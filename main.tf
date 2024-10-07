# Terraform block
terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

# AWS Provider configuration
provider "aws" {
  region = "us-east-1"  # North Virginia
}

# Generate an SSH Key Pair
resource "tls_private_key" "terraform_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save the Private Key Locally
resource "local_file" "private_key" {
  content  = tls_private_key.terraform_key.private_key_pem
  filename = "${path.module}/t2_medium.pem"

  # Ensure the private key file is secure and not tracked in version control.
  lifecycle {
    ignore_changes = [content]
  }
}

# Register the Public Key with AWS
resource "aws_key_pair" "terraform_key" {
  key_name   = "t2.medium"
  public_key = tls_private_key.terraform_key.public_key_openssh

  tags = {
    Name = "t2.medium-key"
  }
}

# Create a VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "terraform-vpc"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "terraform-igw"
  }
}

# Create a Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "terraform-public-subnet"
  }
}

# Create a Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "terraform-public-route-table"
  }
}

# Associate Route Table with Subnet
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Create a Security Group to Allow SSH
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow inbound SSH traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # For enhanced security, restrict to your IP
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh_sg"
  }
}

# Create a Security Group for HTTP Access
resource "aws_security_group" "allow_http" {
  name        = "allow_http"
  description = "Allow inbound HTTP traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_http_sg"
  }
}

# Launch the Control Plane EC2 Instance with t2.medium
resource "aws_instance" "control_plane" {
  ami                         = "ami-0583d8c7a9c35822c"  # Replace with your preferred AMI
  instance_type               = "t2.medium"
  subnet_id                   = aws_subnet.public.id
  key_name                    = aws_key_pair.terraform_key.key_name
  vpc_security_group_ids      = [
    aws_security_group.allow_ssh.id,
    aws_security_group.allow_http.id
  ]
  associate_public_ip_address = true

  depends_on = [
    aws_security_group.allow_ssh,
    aws_security_group.allow_http
  ]

  tags = {
    Name = "control-plane"
  }
}

# Launch the Worker Node 1 EC2 Instance with t2.medium
resource "aws_instance" "worker_node1" {
  ami                         = "ami-0583d8c7a9c35822c"  # Replace with your preferred AMI
  instance_type               = "t2.medium"
  subnet_id                   = aws_subnet.public.id
  key_name                    = aws_key_pair.terraform_key.key_name
  vpc_security_group_ids      = [
    aws_security_group.allow_ssh.id,
    aws_security_group.allow_http.id
  ]
  associate_public_ip_address = true

  depends_on = [
    aws_security_group.allow_ssh,
    aws_security_group.allow_http
  ]

  tags = {
    Name = "worker-node1"
  }
}

# Output the Public IPs of the Instances
output "control_plane_public_ip" {
  description = "Public IP of the control-plane instance"
  value       = aws_instance.control_plane.public_ip
}

output "worker_node1_public_ip" {
  description = "Public IP of the worker-node1 instance"
  value       = aws_instance.worker_node1.public_ip
}
