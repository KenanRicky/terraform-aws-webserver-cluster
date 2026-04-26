# AWS Web Server Cluster Module

This Terraform module creates a production-ready web server cluster on AWS, including an Auto Scaling Group (ASG) of EC2 instances running a simple HTTP server, fronted by an Application Load Balancer (ALB). The module automatically handles instance health checks, scales instances based on configured min/max sizes, and distributes traffic across healthy instances.

## Features

- Deploys an Auto Scaling Group of EC2 instances with customizable instance types
- Creates an Application Load Balancer to distribute traffic across instances
- Configures security groups for both instances and load balancer
- Supports custom VPC and subnet IDs for network isolation
- Includes health checks to ensure only healthy instances receive traffic
- Automatically registers/deregisters instances with the target group
- Configurable HTTP server port
- Tagging support for resource organization

## Requirements

| Name | Version |
|------|---------|
| Terraform | >= 1.0 |
| AWS Provider | ~> 5.0 |

## Input Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `cluster_name` | The name to use for all cluster resources (VPC, ASG, ALB, etc.) | `string` | n/a | yes |
| `vpc_id` | VPC ID where resources will be created | `string` | n/a | yes |
| `subnet_ids` | List of subnet IDs for the ASG and ALB (must be at least 2 in different AZs) | `list(string)` | n/a | yes |
| `instance_type` | EC2 instance type for the cluster (e.g., t2.micro, t2.medium, t3.small) | `string` | `"t2.micro"` | no |
| `min_size` | Minimum number of EC2 instances in the Auto Scaling Group | `number` | n/a | yes |
| `max_size` | Maximum number of EC2 instances in the Auto Scaling Group | `number` | n/a | yes |
| `server_port` | Port the web server uses for HTTP traffic | `number` | `8080` | no |
| `environment` | Environment name (dev, staging, prod) for resource tagging | `string` | `"development"` | no |

## Outputs

| Name | Description |
|------|-------------|
| `alb_dns_name` | The DNS name of the load balancer (use this to access your web application) |
| `asg_name` | The name of the Auto Scaling Group (useful for debugging and monitoring) |
| `alb_security_group_id` | Security group ID of the load balancer (for additional security rules) |
| `instance_security_group_id` | Security group ID of the instances (for additional security rules) |

## Usage Examples

### Basic Usage (Minimum Required Inputs)

```hcl
module "webserver_cluster" {
  source = "git::https://github.com/KenanRicky/terraform-aws-webserver-cluster.git?ref=v0.0.1"

  cluster_name = "my-app"
  vpc_id       = aws_vpc.main.id
  subnet_ids   = aws_subnet.public[*].id
  min_size     = 2
  max_size     = 4
}


Architecture
text
Internet → ALB (Port 80) → Target Group → Auto Scaling Group → EC2 Instances (Port 8080)
                                    ↓
                              Health Checks (HTTP:8080/)


                              Troubleshooting
Issue: "At least two subnets in two different Availability Zones must be specified"
Solution: Ensure you're providing at least 2 subnet IDs from different AZs.

Issue: Instances show as "unhealthy" in target group
Solution: Check that:

The web server is running on the correct port (server_port)

Security groups allow traffic on that port

The health check path returns HTTP 200

Issue: Cannot access ALB DNS name
Solution: Verify:

Internet Gateway is attached to your VPC

Subnets have map_public_ip_on_launch = true

Route tables have 0.0.0.0/0 pointing to IGW

Development
To modify this module:

Clone the repository

Make changes to the module files (main.tf, variables.tf, outputs.tf)

Test locally using a root module with source = "../../../../modules/services/webserver-cluster"

Run terraform validate and terraform fmt

Create a pull request with your changes

Tag a new version after merging: git tag -a v1.0.0 -m "Description" && git push origin v1.0.0