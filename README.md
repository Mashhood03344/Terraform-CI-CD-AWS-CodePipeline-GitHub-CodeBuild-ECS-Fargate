# Terraform Infrastructure for ECS Deployment with CI/CD Pipeline

## Overview
This project sets up a complete infrastructure on AWS for deploying a simple HTML application using ECS Fargate. It includes the creation of a VPC, ECS cluster, task definition, security groups, and a CI/CD pipeline with AWS CodePipeline and CodeBuild.

## Table of Contents
- [Architecture Overview](#architecture-overview)
- [Prerequisites](#prerequisites)
- [Terraform Resources](#terraform-resources)
- [How to Deploy](#how-to-deploy)
- [Configuration](#configuration)
- [Cleanup](#cleanup)

## Architecture Overview

The infrastructure consists of the following components:

1. **VPC and Networking**: A VPC with a public subnet, internet gateway, and route table is created to host the ECS cluster.
2. **Security Groups**: A security group is configured to allow HTTP traffic on port 80.
3. **ECS Cluster**: An ECS cluster is created along with a Fargate task definition for the HTML application.
4. **IAM Roles**: IAM roles and policies are defined for ECS task execution, CodeBuild, and CodePipeline.
5. **CI/CD Pipeline**: A CI/CD pipeline is set up using AWS CodePipeline and CodeBuild to automate the deployment of the HTML application.

## Prerequisites

Before you begin, ensure you have the following:

- Terraform installed on your machine.
- AWS CLI configured with appropriate credentials.
- A GitHub repository containing the HTML application.
- A CodeConnection to your GitHub Repository 
	- Goto Developer Tools in the AWS Console 
	- Click to settings
	- Click on Connections
	- Create a connection to your GitHub Repository 
- An S3 bucket for storing CodePipeline artifacts.

## Terraform Resources

### VPC and Networking

- `aws_vpc` - Creates a VPC for the application.
- `aws_internet_gateway` - Attaches an Internet Gateway to the VPC.
- `aws_subnet` - Creates a public subnet within the VPC.
- `aws_route_table` - Creates a route table with routes to the internet.
- `aws_security_group` - Configures security group for HTTP access.

### ECS and IAM

- `aws_ecs_cluster` - Creates an ECS cluster.
- `aws_ecs_task_definition` - Defines a Fargate task for the HTML application.
- `aws_iam_role` and `aws_iam_role_policy_attachment` - Defines IAM roles and attaches necessary policies for ECS, CodeBuild, and CodePipeline.

### CI/CD Pipeline

- `aws_codepipeline` - Sets up a pipeline for automated deployment.
- `aws_codebuild_project` - Configures a build project for the HTML application.

## How to Deploy

 **Clone the Repository**:

	```bash
	git clone <repository-url>
	cd <repository-directory>
	```
  
  Initialize Terraform:

	```bash
	terraform init
	```

  Review and Apply the Terraform Plan:

	```bash
	terraform plan
	terraform apply
	```

  Type yes when prompted to apply the changes.

## Configuration

**Variables**

Update the following variables in your terraform.tfvars file:

 - aws_region: The AWS region where the resources will be deployed.
 - github_repository: The GitHub repository containing the HTML application.
 - github_repository_owner: The owner of the GitHub repository.
 - github_oauth_token: GitHub OAuth token for accessing the repository.


## Output

After deployment, Terraform will output the following:

 - ECS Cluster ID
 - ECS Service Name
 - ECR Repository URL

## Cleanup

To remove the infrastructure created by Terraform:

	terraform destroy
	
	
Type yes when prompted to destroy the resources.
