variable "aws_region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "github_repository_owner" {
  description = "GitHub repository owner (username)"
  type = string
  default = "your-github-repository-owner"
}

variable "github_repository" {
  description = "GitHub repository name (username/repo)"
  type        = string
  default     = "your-github-repository"
}

variable "github_oauth_token" {
  description = "GitHub OAuth token for accessing the repository"
  type        = string
  sensitive   = true
  default = "your-personal-access-token"
}

variable "ecr_repo_name" {
  description = "ECR repository name"
  type        = string
  default     = "simple-html-app"
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  default     = "simple-html-cluster"
}

variable "ecs_service_name" {
  description = "Name of the ECS service"
  type        = string
  default     = "simple-html-service"
}

variable "ecs_task_definition_name" {
  description = "Name of the ECS task definition"
  type        = string
  default     = "simple-html-task"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for the subnet"
  type        = string
  default     = "10.0.1.0/24"
}

