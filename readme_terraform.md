# Multi-Cluster Setup with AWS EC2 Using Terraform

## Overview
This Terraform project allows you to create a Kubernetes-like multi-cluster setup on AWS EC2 instances. You can easily specify the number of control plane and worker nodes, which makes it easy to set up and manage multiple clusters by adjusting the number of instances.

## Prerequisites
- Two or more servers running Ubuntu 22.04.
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
   git clone https://github.com/yourusername/multi-cluster-setup
   cd multi-cluster-setup
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

## Install Kubernetes on Ubuntu 22.04
To install Kubernetes on Ubuntu 22.04, follow these steps on each node:

### Set Up Docker
Kubernetes requires a CRI-compliant container engine runtime such as Docker, containerd, or CRI-O. This guide shows you how to deploy Kubernetes using Docker.

1. **Update the package list**:
   ```sh
   sudo apt update
   ```

2. **Install Docker**:
   ```sh
   sudo apt install docker.io -y
   ```

3. **Set Docker to launch on boot**:
   ```sh
   sudo systemctl enable docker
   ```

4. **Verify Docker is running**:
   ```sh
   sudo systemctl status docker
   ```

5. **Start Docker if not running**:
   ```sh
   sudo systemctl start docker
   ```

### Install Kubernetes Tools
Setting up Kubernetes involves adding the Kubernetes repository to the APT sources list and installing the relevant tools.

1. **Add Kubernetes Signing Key**:
   ```sh
   curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
   ```

2. **Add Kubernetes Repository**:
   ```sh
   echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
   ```

3. **Update Packages**:
   ```sh
   sudo apt update
   ```

4. **Install Kubernetes Tools**:
   ```sh
   sudo apt install kubeadm kubelet kubectl
   sudo apt-mark hold kubeadm kubelet kubectl
   ```

5. **Verify Installation**:
   ```sh
   kubeadm version
   ```

### Deploy Kubernetes Cluster
1. **Disable Swap**:
   ```sh
   sudo swapoff -a
   sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
   ```

2. **Load Required Containerd Modules**:
   ```sh
   echo -e "overlay\nbr_netfilter" | sudo tee /etc/modules-load.d/containerd.conf
   sudo modprobe overlay
   sudo modprobe br_netfilter
   ```

3. **Configure Kubernetes Networking**:
   ```sh
   echo -e "net.bridge.bridge-nf-call-ip6tables = 1\nnet.bridge.bridge-nf-call-iptables = 1\nnet.ipv4.ip_forward = 1" | sudo tee /etc/sysctl.d/kubernetes.conf
   sudo sysctl --system
   ```

4. **Assign Unique Hostname**:
   ```sh
   sudo hostnamectl set-hostname master-node  # For master node
   sudo hostnamectl set-hostname worker01  # For worker node(s)
   ```

5. **Initialize Kubernetes on Master Node**:
   ```sh
   sudo kubeadm init --control-plane-endpoint=master-node --upload-certs
   mkdir -p $HOME/.kube
   sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
   sudo chown $(id -u):$(id -g) $HOME/.kube/config
   ```

6. **Deploy Pod Network**:
   ```sh
   kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
   kubectl taint nodes --all node-role.kubernetes.io/control-plane-
   ```

7. **Join Worker Nodes to Cluster**:
   Use the join command provided after initializing the master node to add worker nodes.

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
