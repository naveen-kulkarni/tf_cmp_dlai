
variable "project_id" {
  default     = "my-project-14538-384315"
  description = "The project ID to host the cluster in"
}
variable "gcp_auth_file" {
  description = "The name for the GKE cluster"
  default     = "my-project-14538-384315-32db0c5b35a6.json"
}
variable "bucket_name" {
  description = "The bucket name"
  default     = "naveen-s3"
}

variable "cluster_name" {
  description = "The name for the GKE cluster"
  default     = "naveen-k8s-cluster"
}
variable "env_name" {
  description = "The environment for the GKE cluster"
  default     = "dev"
}
variable "region" {
  description = "The region to host the cluster in"
  default     = "asia-south1"
}
variable "network" {
  description = "The VPC network created to host the cluster in"
  default     = "gke-network"
}
variable "subnetwork" {
  description = "The subnetwork created to host the cluster in"
  default     = "gke-subnet"
}
variable "ip_range_pods_name" {
  description = "The secondary ip range to use for pods"
  default     = "ip-range-pods"
}
variable "ip_range_services_name" {
  description = "The secondary ip range to use for services"
  default     = "ip-range-services"
}
