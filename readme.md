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
   git clone https://github.com/yourusername/mongodb
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

# Installing Kubernetes on Ubuntu 22.04

This guide provides instructions for setting up Kubernetes on Ubuntu 22.04 using Docker as the container engine. Follow these steps on each node (both master and worker nodes).

### Step 1: Set Up Docker
Kubernetes requires a Container Runtime Interface (CRI)-compliant container runtime, such as Docker, containerd, or CRI-O. Here, we use Docker.

#### Update the Package List
```sh
sudo apt update
```
This command updates the package list to ensure the latest versions of packages are available.

#### Install Docker
```sh
sudo apt install docker.io -y
```
Docker is installed to serve as the container runtime for Kubernetes. The `-y` flag automatically confirms the installation.

#### Set Docker to Launch on Boot
```sh
sudo systemctl enable docker
```
This command enables Docker to start automatically when the system boots, ensuring the Kubernetes cluster can always use Docker.

#### Verify Docker is Running
```sh
sudo systemctl status docker
```
This command verifies that Docker is running correctly.

#### Start Docker (if not already running)
```sh
sudo systemctl start docker
```
This command starts the Docker service if it's not running.

### Step 2: Install Kubernetes Tools
The installation of Kubernetes involves adding the Kubernetes repository to your APT sources and installing the necessary tools.

#### Add Kubernetes Signing Key
```sh
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
```
This command adds the Kubernetes signing key to your system, which helps verify the authenticity of the Kubernetes packages being installed.

#### Add Kubernetes Repository
```sh
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
```
This command adds the Kubernetes package repository to your APT sources, allowing you to install Kubernetes components.

#### Update Packages
```sh
sudo apt update
```
Updates the package list to recognize the newly added Kubernetes repository.

#### Install Kubernetes Tools
```sh
sudo apt install kubeadm kubelet kubectl
sudo apt-mark hold kubeadm kubelet kubectl
```
Installs Kubernetes tools:
- **kubeadm**: Helps initialize and configure the Kubernetes cluster.
- **kubelet**: Manages the Kubernetes nodes.
- **kubectl**: The command-line tool for managing Kubernetes.

The `apt-mark hold` command ensures that the installed versions are not automatically updated, maintaining cluster compatibility.

#### Verify Installation
```sh
kubeadm version
```
This command checks that kubeadm is correctly installed.

### Step 3: Deploy Kubernetes Cluster

#### Disable Swap
```sh
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
```
Kubernetes requires swap to be disabled to ensure the predictability of memory allocation for workloads. The first command disables swap temporarily, and the second command comments out the swap entry in `/etc/fstab` to ensure it remains disabled after reboot.

#### Load Required Containerd Modules
```sh
echo -e "overlay\nbr_netfilter" | sudo tee /etc/modules-load.d/containerd.conf
sudo modprobe overlay
sudo modprobe br_netfilter
```
These commands load kernel modules required for container networking:
- **overlay**: Enables overlay networks for containers.
- **br_netfilter**: Allows bridge network traffic to be processed by iptables.

#### Configure Kubernetes Networking
```sh
echo -e "net.bridge.bridge-nf-call-ip6tables = 1\nnet.bridge.bridge-nf-call-iptables = 1\nnet.ipv4.ip_forward = 1" | sudo tee /etc/sysctl.d/kubernetes.conf
sudo sysctl --system
```
These commands configure networking settings necessary for Kubernetes to handle network traffic effectively. The `sysctl` command reloads the configuration to apply changes.

#### Assign Unique Hostname
```sh
sudo hostnamectl set-hostname master-node  # For master node
sudo hostnamectl set-hostname worker01  # For worker nodes
```
Assigns a unique hostname to each node. This helps Kubernetes distinguish between different nodes in the cluster.

#### Initialize Kubernetes on Master Node
```sh
sudo kubeadm init --control-plane-endpoint=master-node --upload-certs
```
This command initializes the Kubernetes control plane on the master node. The `--control-plane-endpoint` specifies the hostname for the control plane.

#### Set Up kubeconfig for kubectl
```sh
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```
These commands configure the kubeconfig file, allowing the `kubectl` command to manage the cluster.

#### Deploy Pod Network
```sh
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
```
This command deploys the Flannel pod network. Flannel is used as a network overlay to enable communication between pods running on different nodes.

#### Remove Control-Plane Taint
```sh
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
```
This command allows scheduling pods on the master node by removing the control-plane taint, which otherwise prevents normal pods from running on the master.

### Step 4: Join Worker Nodes to Cluster
Use the join command provided after initializing the master node to add worker nodes to the cluster. This command should be run on each worker node to connect them to the master and form a full Kubernetes cluster.

---
These steps should be performed on each node to successfully set up a Kubernetes cluster. Ensure that each step is followed carefully, as misconfigurations can lead to issues in the cluster.

Author: Gautam Mallick
