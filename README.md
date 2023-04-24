
==========================================
Project_Name:	My-Project-14538
Project_ID: 	my-project-14538-384315
Principal:	naveenvk88@gmail.com
==========================================

Part A - terraform repository structure
Repo Name : 01-Terraform Structure

Structure Description: multiple companies (company_a and company_b) that can have multiple environments (staging and production) and can have environments in multiple cloud providers (some in gcp, some in aw).

Structure:

![image](https://user-images.githubusercontent.com/33716521/233611011-a095a55d-f748-4d8c-ae2f-213f61065ab1.png)

 
==========================================
Part B - terraform coding
Repo Name: 02-Terraform-code
Summary:
1.	Create EKS cluster named “naveen-k8s-cluster-dev”.
2.	Created namespaces: “services” and “monitoring”
3.	deployed vanilla nginx web server to “services” namespace
4.	deploy prometheus and grafana to monitoring namespace
5.	exposed nginx and grafana to the internet

Generating kubeconfig .
![image](https://user-images.githubusercontent.com/33716521/233610747-80d6b81c-70f1-4283-8878-f6307277d69d.png)

Created namespaces: “services” and “monitoring”
![image](https://user-images.githubusercontent.com/33716521/233610721-688eedaa-b2b7-48d5-a549-d593f115f139.png)
 
deployed vanilla nginx web server to “services” namespace.
deploy prometheus and grafana to monitoring namespace

![image](https://user-images.githubusercontent.com/33716521/233610652-e70aba21-9c44-466f-b4da-d962a2a208ff.png)
