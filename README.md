
# Automated deployment of MongoDB cluster to AWS using Terraform

An automated setup to deploy a MongoDB Cluster with a Replica Set (1 Primary, n Secondary nodes)

Nowadays, IaC tools allows teams to automatically provision the complex intertwined cloud infrastructure in a deterministic manner. There can be multiple reasons why you would want to invest efforts into writing code for automating the deployment of a database cluster:

-Performance testing your applications' access patterns by pointing them to your database.

-Documenting the custom configurations made while setting up the database.

-Safely and quickly replicating environments for staging, testing, DR, etc.

This project creates in AWS a VPC, Public/Private subnets, a Jumpbox server in the public subnet, and a MongoDB cluster in the private subnets.

All the source code is available at my GitHub repository. The code is structured as different Terraform files such as main.tf, variable.tf , mongodb_userdata.sh, terraform.tfvars, etc. You can visit the repository for installation prerequisites and instructions on how to run the project. Here's a snippet of the main.tf file which utilizes all the Terraform modules.

The MongoDB cluster module takes in a lot of configurable parameters which can be supplied by the terraform.tfvars file.

We're going to deploy MongoDB v6.0 using the Amazon Linux 2 AMI. The official MongoDB documentation delineates steps to follow for installing MongoDB on Amazon Linux AMI. Just browsing through the insane number of steps involved or the confusing order of steps, you can imagine the dividend of scripting the commands rather than scampering through the documentation to figure out what worked the last time. Additionally, since this isn't a single node deployment, we need to deploy a replica set for MongoDB.

The main.tf file for the MongoDB cluster module contains the code for creating the resources like EC2 instances, IAM policies, Security Groups, etc. Using Terraform's file provisioner, certain scripts and files (like the private key file needed to be shared by all the participating nodes) are uploaded to the instances while creating them.

The "count" parameter (passed by the user) controls how many nodes to create. The instance is placed in any of the 3 private subnets in a round-robin manner.

The userdata shell script contains the bulk of the configuration. It scans the AWS environment for the cluster members and configures each instance with the private IPs of other members. This is accomplished by using the EC2 Instance Metadata Service. Also, each instance has a Tag attached to it which helps to identify whether it's a Primary or Secondary node.

Go ahead and deploy the cluster in your AWS environment. Make sure you have a public-private keypair in the ~/.ssh directory. Use ssh-keygen to create the key files. Install Terraform and the AWS CLI. Create ~/.aws/credentials file to store your AWS Secret Key and Access Key locally for Terraform to use. I hope everything works great on the first try.


## Deployment Architecture 


![deployment architecture diagram](https://github.com/TejasMore324/Mongodb-terraform-deployment/assets/172258584/6857f505-43cf-4d1f-a2cc-9ef01c789925)


## Steps to Deploy

1.Clone this repository

2.cd into the repository

3.Edit the variables in the terraform.tfvars file

```bash
vpc_name = "mongo_vpc"
replica_set_name = "mongoRs" 
num_secondary_nodes = 2 
mongo_username = "admin" 
mongo_password = "mongo4pass" 
mongo_database = "admin"
```
4.Set up the AWS CLI on your development machine and configure the ~/.aws/credentials file
```bash
[default] aws_access_key_id = xxxxxxxxxxxxxxxxxx 
aws_secret_access_key = xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```
5.Install Terraform on your development machine

6.Use "terraform init" to initialize the modules

7.Use "terraform plan" to view the resources that would be created

8.Use "terraform apply" to deploy the cluster


