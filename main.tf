provider "aws" {
    region = "us-east-1"
  }
  
  resource "tls_private_key" "generated_key" {
    algorithm = "RSA"
    rsa_bits  = 2048
  }
  
  resource "local_file" "private_key" {
    content  = tls_private_key.generated_key.private_key_pem
    filename = "./ec2-key.pem"
  }
  
  variable "control_plane_count" {
    description = "Number of control plane instances to create"
    type        = number
    default     = 1
  }
  
  variable "worker_node_count" {
    description = "Number of worker node instances to create"
    type        = number
    default     = 1
  }
  
  resource "aws_key_pair" "generated_key" {
    key_name   = "ec2-key"
    public_key = tls_private_key.generated_key.public_key_openssh
  }
  
  resource "aws_instance" "control_plane" {
    count         = var.control_plane_count
    ami           = "ami-005fc0f236362e99f"  # Using the Ubuntu 22.04 specified AMI
    instance_type = "t2.medium"
    key_name      = aws_key_pair.generated_key.key_name
  
    tags = {
      Name = "control-plane-${count.index + 1}"
    }
  
    subnet_id = aws_subnet.public_subnet.id
    vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  }
  
  resource "aws_instance" "worker_node" {
    count         = var.worker_node_count
    ami           = "ami-005fc0f236362e99f"  # Using the Ubuntu 22.04 specified AMI
    instance_type = "t2.medium"
    key_name      = aws_key_pair.generated_key.key_name
  
    tags = {
      Name = "worker-node-${count.index + 1}"
    }
  
    subnet_id = aws_subnet.public_subnet.id
    vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  }
  
  # Output the Public IPs of the Control Plane Instances
  output "control_plane_public_ips" {
    description = "Public IPs of the control plane instances"
    value       = aws_instance.control_plane[*].public_ip
  }
  
  # Output the Public IPs of the Worker Node Instances
  output "worker_node_public_ips" {
    description = "Public IPs of the worker node instances"
    value       = aws_instance.worker_node[*].public_ip
  }
  
  resource "aws_vpc" "main" {
    cidr_block           = "10.0.0.0/16"
    enable_dns_support   = true
    enable_dns_hostnames = true
  }
  
  resource "aws_subnet" "public_subnet" {
    vpc_id                  = aws_vpc.main.id
    cidr_block              = "10.0.1.0/24"
    availability_zone       = "us-east-1a"  # Update as needed
    map_public_ip_on_launch = true
  }
  
  resource "aws_internet_gateway" "gw" {
    vpc_id = aws_vpc.main.id
  }
  
  resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.id
  
    route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.gw.id
    }
  }
  
  resource "aws_route_table_association" "public_assoc" {
    subnet_id      = aws_subnet.public_subnet.id
    route_table_id = aws_route_table.public.id
  }
  
  resource "aws_security_group" "allow_ssh" {
    name_prefix = "allow_ssh"
    vpc_id      = aws_vpc.main.id
  
    ingress {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  
    ingress {
      from_port   = 6443
      to_port     = 6443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  
    ingress {
      from_port   = 30000
      to_port     = 32767
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  
    egress {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
