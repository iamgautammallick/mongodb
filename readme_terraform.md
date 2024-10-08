# Multi-Cluster Setup with AWS EC2 Using Terraform

## Overview
This Terraform project allows you to create a Kubernetes-like multi-cluster setup on AWS EC2 instances. You can easily specify the number of control plane and worker nodes, which makes it easy to set up and manage multiple clusters by adjusting the number of instances.

## Prerequisites
- Terraform installed on your local machine.
- AWS credentials configured with sufficient permissions to create VPC, Subnet, EC2 instances, Security Groups, etc.
- SSH key-pair for accessing the EC2 instances.

## Features
- Automated generation of a key pair for secure SSH access to EC2 instances.
- Configurable number of control plane and worker node instances.
- Custom VPC, Subnet, and Security Group setup to manage the network infrastructure.
- Outputs public IPs of the control plane and worker nodes for easy access.

## Setup
1. **Clone the Repository**
   ```sh
   https://github.com/iamgautammallick/mongodb.git
   cd mongodb
   ```

2. **Edit Variables (Optional)**
   You can update the default variables to configure the number of control plane and worker node instances.
   ```hcl
   variable "control_plane_count" {
     description = "Number of control plane instances to create"
     type        = number
     default     = 1  # Update as needed
   }

   variable "worker_node_count" {
     description = "Number of worker node instances to create"
     type        = number
     default     = 1  # Update as needed
   }
   ```

3. **Initialize Terraform**
   Run the following command to initialize Terraform and download the necessary providers.
   ```sh
   terraform init
   ```

4. **Apply Configuration**
   Run the command below to create the infrastructure. You will be prompted to confirm before Terraform makes any changes.
   ```sh
   terraform apply
   ```
   Note: You can use the `-var` flag to override default values:
   ```sh
   terraform apply -var="control_plane_count=3" -var="worker_node_count=5"
   ```

5. **Access the Instances**
   After the infrastructure is created, Terraform will output the public IP addresses of the control plane and worker nodes.
   ```
   control_plane_public_ips = ["<control-plane-ip>", ...]
   worker_node_public_ips = ["<worker-node-ip>", ...]
   ```
   Use these IPs to SSH into the instances. For example:
   ```sh
   ssh -i ./ec2-key.pem ec2-user@<control-plane-ip>
   ```

## Network Configuration
The setup includes a VPC, public subnet, internet gateway, and security groups:
- **VPC**: Custom VPC for network isolation.
- **Subnet**: A public subnet with IPs assigned on instance launch.
- **Security Groups**: Allows SSH (port 22) and Kubernetes-related ports (6443 for API server, 30000-32767 for NodePort services).

## Multi-Cluster Setup
You can set up multiple clusters by adjusting the number of control plane and worker node instances using the `control_plane_count` and `worker_node_count` variables. Each instance can act as an independent node in a Kubernetes cluster. For example, by setting `control_plane_count` to `3` and `worker_node_count` to `5`, you can create a setup suitable for managing a highly available multi-cluster environment.

## Clean Up
To destroy all resources created by this project and avoid incurring charges:
```sh
terraform destroy
```

## Notes
- The AMI used (`ami-005fc0f236362e99f`) is for `us-east-1`. You may need to update the AMI ID if deploying in a different region.
- The generated key (`ec2-key.pem`) is stored locally for accessing the instances.

## Contributing
Feel free to open an issue or submit a pull request if you have suggestions or improvements.

## License
This project is licensed under the MIT License.

