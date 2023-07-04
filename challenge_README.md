Cloud Engineer Technical Challenge - 2021
=========================================

The XXXXX Technical Challenge is a self-paced interview challenge focused on AWS infrastructure and DevOps principles including:
* Source Control
* Infrastructure as Code
* CI/CD


# Requirements

The Cloud Engineer Technical challenge is expected to take between 1.5-6 hours, depending on level of experience, with most people expected to take 2-4 hours.

The goal is to test your ability to complete a relatively simple set of tasks using technologies or tools that you would be using on a regular basis in the Cloud Engineer role at XXXXX. Specifics for the challenge are below, and you have the full power of the internet at your disposal - there aren't any intended tricks. If you have any questions please email your contact as soon as possible.

At a minimum the following items should be completed:
- Infrastructure is deployable
- Application is running and reachable via load balancer
- Documentation on how to deploy/update everything

**Last, be prepared to speak to the pieces of the completed challenge. The final interview is a combination of XXXXX following your documentation to run the project and your explanation of the solution provided**

## Source Control
Your contact should have gotten your GitHub username and given you access to the new-tech-challenge repository, the application repository, and an empty repository for you to push your terraform.

Pleae make sure you have access to the following repositories:
- XXXXX (this repository)
- XXXXX (application to be deployed)
- XXXXX (for your terraform/pipeline)

## AWS Infrastructure - Infrastructure as Code
Please use Terraform to deploy the infrastructure in the architecture document. Make sure that Terraform is checked in to your GitHub repository before your challenge window closes.

**The challenge is designed to use AWS free tier services ONLY and the architecture diagram found at the end of this document reflects that. Please work accordingly**

Noted key elements of the infrastructure:
- VPC
- Subnet
- load balancer
- ec2 instances
- database

Your final Terraform should be able to run in a green or completely empty AWS account.

## Application -  Deployment/Testing
The application is a simple python [flask](https://flask.palletsprojects.com/) app running on port 8080 that has several routes. Documentation for the app is found in its repository.

- The app can be deployed to windows or to linux, whatever you set up in your Terraform
- The application should be load balanced across two availability zones
- All routes documented in the application repository should be available
- The load balancer should serve the app over standard HTTP on port 80

## CI/CD

Please set up a CI/CD pipeline that can be used to deploy the infrastructure or the application, your choice.
Please use a common toolset such as GitHub actions, GitLab CI, Jenkins, TravisCI, CircleCI, AWS CodePipeline or similar. Make sure to document how to set up the pipeline.

- The pipeline should be checked in to your repository
- Should be well documented

# Optional
- The application should start when the instances start
- Pre-build AMIs with the application already loaded
- Use AutoScaling Groups to help with application deployment
- Create pipelines for both infrastructure and application deployment
- Containerize the application for use on ECS

# Documentation

Documentation for infrastructure:
![architecture diagram](./images/arch_diagram.png)
