# Configure AWS provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Get availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Get latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Get default VPC
data "aws_vpc" "default" {
  default = true
}

# Create subnets (since your default VPC has none)
resource "aws_subnet" "webserver" {
  count = 2
  
  vpc_id            = data.aws_vpc.default.id
  cidr_block        = cidrsubnet(data.aws_vpc.default.cidr_block, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  
  tags = {
    Name = "webserver-subnet-${count.index + 1}"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = data.aws_vpc.default.id
  
  tags = {
    Name = "webserver-igw"
  }
}

# Create route table
resource "aws_route_table" "public" {
  vpc_id = data.aws_vpc.default.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  tags = {
    Name = "webserver-route-table"
  }
}

# Associate subnets with route table
resource "aws_route_table_association" "public" {
  count = 2
  
  subnet_id      = aws_subnet.webserver[count.index].id
  route_table_id = aws_route_table.public.id
}

locals {
  subnet_ids = aws_subnet.webserver[*].id
}

# Module call
module "webserver_cluster" {
  source = "../../../../modules/services/webserver-cluster"

  # Required arguments
  ami_id        = data.aws_ami.amazon_linux_2.id
  subnet_ids    = local.subnet_ids
  vpc_id        = data.aws_vpc.default.id
  max_size      = 3
  cluster_name  = "my-webserver-cluster"
  environment   = "dev"
  
  # Optional arguments
  min_size         = 1
  desired_capacity = 1
  instance_type    = "t2.micro"
}

# Outputs
output "alb_dns_name" {
  value = module.webserver_cluster.alb_dns_name
}

output "asg_name" {
  value = module.webserver_cluster.asg_name
}

output "subnet_ids" {
  value = local.subnet_ids
}