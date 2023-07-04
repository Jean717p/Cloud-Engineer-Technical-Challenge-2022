variable "tags" {
    type = map(string)
    description = "Map of tags assigned to project resources"
    default = {
        "project" = "project_name"
        "env" = "mock"
    }
}

variable "ec2_key_pair_name" {
    type = string
    description = "EC2 Key pair name"
}

variable "ecs_cluster_name" {
    type = string
    description = "ECS Cluster Name"
    default = "cluster"
}

variable "region" {
  type = string
  description = "AWS_REGION"
  default = "us-east-2"
}

variable "app_port" {
  type = number
  description = "application port"
  default = 8000
}

variable "instance_type" {
    type = string
    description = "EC2 host instance type"
    default = "t3.micro"
}

variable "desired_tasks" {
    type = number
    description = "number of desired ecs tasks"
    default = 2
}

variable "desired_instance_capacity" {
    type = number
    description = "number of desired EC2 host instances"
    default = 2
}

variable "artifact_store" {
    type = string
    description = "bucket for pipeline artifact store"
}

variable "codebuild_image" {
    type = string
    description = "codebuild base image version"
    default = "aws/codebuild/standard:5.0"
}

variable "healthcheck_path" {
    type = string
    description = "Target group healthcheck path"
    default = "/gtg"
}
