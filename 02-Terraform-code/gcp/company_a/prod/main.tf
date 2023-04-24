module "gke_auth" {
  source = "terraform-google-modules/kubernetes-engine/google//modules/auth"
  version = "24.1.0"
  depends_on   = [module.gke]
  project_id   = var.project_id
  location     = module.gke.location
  cluster_name = module.gke.name
}

resource "local_file" "kubeconfig" {
  content  = module.gke_auth.kubeconfig_raw
  filename = "kubeconfig-${var.env_name}"
}

module "gcp-network" {
  source       = "terraform-google-modules/network/google"
  version      = "6.0.0"
  project_id   = var.project_id
  network_name = "${var.network}-${var.env_name}"

  subnets = [
    {
      subnet_name   = "${var.subnetwork}-${var.env_name}"
      subnet_ip     = "10.10.0.0/16"
      subnet_region = var.region
    },
  ]

  secondary_ranges = {
    "${var.subnetwork}-${var.env_name}" = [
      {
        range_name    = var.ip_range_pods_name
        ip_cidr_range = "10.20.0.0/16"
      },
      {
        range_name    = var.ip_range_services_name
        ip_cidr_range = "10.30.0.0/16"
      },
    ]
  }
}

data "google_client_config" "default" {}

module "gke" {
  source                 = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  version                = "24.1.0"
  project_id             = var.project_id
  name                   = "${var.cluster_name}-${var.env_name}"
  regional               = true
  region                 = var.region
  network                = module.gcp-network.network_name
  subnetwork             = module.gcp-network.subnets_names[0]
  ip_range_pods          = var.ip_range_pods_name
  ip_range_services      = var.ip_range_services_name
  
  node_pools = [
    {
      name                      = "node-pool"
      machine_type              = "e2-medium"
      node_locations            = "asia-south1-a"
      min_count                 = 1
      max_count                 = 2
      disk_size_gb              = 30
    },
  ]
}

# Kubernetes Namespace Configuration
resource "kubernetes_namespace" "services" {
  metadata {
    name = "services"
  }
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

# Vanilla Nginx Deployment Configuration
resource "kubernetes_deployment" "nginx" {
  metadata {
    name = "nginx"
    namespace = kubernetes_namespace.services.metadata[0].name
      labels = {
        app = "nginx"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "nginx"
      }
    }

    template {
      metadata {
        labels = {
          app = "nginx"
        }
      }

      spec {
        container {
          image = "nginx:latest"
          name  = "nginx"
	  port {
            container_port = 80
          }
        }
      }
    }
  }
}


resource "kubernetes_deployment" "prometheus" {
  metadata {
    name      = "prometheus"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels = {
      app = "prometheus"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "prometheus"
      }
    }

    template {
      metadata {
        labels = {
          app = "prometheus"
        }
      }

      spec {
        container {
          image = "prom/prometheus"
          name  = "prometheus"
          port {
            container_port = 9090
          }
          args = [
            "--config.file=/etc/prometheus/prometheus.yml",
            "--storage.tsdb.path=/data",
            "--web.console.libraries=/usr/share/prometheus/console_libraries",
            "--web.console.templates=/usr/share/prometheus/consoles"
          ]
          volume_mount {
            name       = "prometheus-config"
            mount_path = "/etc/prometheus"
          }
          volume_mount {
            name       = "prometheus-storage"
            mount_path = "/data"
          }
        }

        volume {
          name = "prometheus-config"
          config_map {
            name = "prometheus-config"
          }
        }

        volume {
          name = "prometheus-storage"
          empty_dir {}
        }
      }
    }
  }
}

resource "kubernetes_config_map" "prometheus_config" {
  metadata {
    name      = "prometheus-config"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  data = {
    "prometheus.yml" = <<-EOT
    global:
      scrape_interval: 15s
      evaluation_interval: 15s
    scrape_configs:
      - job_name: 'prometheus'
        static_configs:
          - targets: ['localhost:9090']
      - job_name: 'kube-apiserver'
        kubernetes_sd_configs:
          - role: endpoints
        scheme: https
        tls_config:
          ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
        relabel_configs:
          - source_labels: [__meta_kubernetes_namespace, __meta_kubernetes_service_name, __meta_kubernetes_endpoint_port_name]
            separator: ;
            regex: default;kubernetes;https
            replacement: $1
            target_label: __address__
          - source_labels: [__meta_kubernetes_namespace, __meta_kubernetes_service_name, __meta_kubernetes_endpoint_port_name]
            separator: ;
            regex: default;kubernetes;https
            replacement: /api/v1/namespaces/$1/services/${2}:${3}/proxy
            target_label: __metrics_path__
    EOT
  }
}



# Grafana Deployment Configuration
resource "kubernetes_deployment" "grafana" {
  metadata {
    name = "grafana"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels ={
        app = "grafana"
      }
    }
    template {
      metadata {
        labels = {
          app = "grafana"
        }
      }
      spec {
        container {
          name  = "grafana"
          image = "grafana/grafana:latest"
          port {
            container_port = 3000
          }
          volume_mount {
            name       = "grafana-storage"
            mount_path = "/var/lib/grafana"
          }
        }
        volume {
          name = "grafana-storage"
          empty_dir {}
        }
      }
    }
  }
}

# Expose the Grafana service to the internet
resource "kubernetes_service" "grafana" {
  metadata {
    name = "grafana"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  spec {
    selector = {
      app = kubernetes_deployment.grafana.spec[0].template[0].metadata[0].labels.app
    }

    port {
      name       = "http"
      port       = 80
      target_port = 3000
    }

    type = "LoadBalancer"
  }
}

# Expose the Nginx service to the internet
resource "kubernetes_service" "nginx" {
  metadata {
    name = "nginx"
    namespace = kubernetes_namespace.services.metadata[0].name
    annotations = {
      "cloud.google.com/load-balancer-type" = "External"
    }
   }
  spec {
    selector = {
      app = "nginx"
    }

    port {
      name       = "http"
      port       = 80
      target_port = 80
    }

    type = "LoadBalancer"
  }
}
