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

---

# Kubernetes Installation Guide on Ubuntu 22.04

## Introduction

Kubernetes is an open-source platform designed to orchestrate containerized applications across a cluster of machines, automating deployment, scaling, and management of applications. This guide will walk you through the process of installing Kubernetes on Ubuntu 22.04 using five simple steps.

## Prerequisites

- **Two or more servers** running Ubuntu 22.04.
- **Command-line access** to each server.
- A **user account with sudo privileges** on each system.

### AWS EC2 Setup
If you are using AWS EC2 instances, configure a security group that allows inbound connections on the following ports:
- **SSH (Port 22)**: For remote access.
- **Kubernetes Control Plane (Port 6443)**: Allows communication between nodes.
- **NodePort Services (30000–32767)**: Required for exposing services running on Kubernetes.

## Step 1: Set Up Docker

Kubernetes requires a container runtime like Docker, containerd, or CRI-O. We will use Docker in this setup.

### Install Docker on Each Node

1. **Update the package list**:
   ```bash
   sudo apt update
   ```
   - **Purpose**: Ensures that you get the latest versions of packages and their dependencies.

2. **Install Docker**:
   ```bash
   sudo apt install docker.io -y
   ```
   - **Purpose**: Installs Docker, a platform for developing, shipping, and running applications in containers.
   - **Explanation**: The `-y` flag automatically answers "yes" to prompts during the installation.

3. **Enable Docker to start on boot**:
   ```bash
   sudo systemctl enable docker
   ```
   - **Purpose**: Ensures Docker starts automatically when the server reboots.

4. **Verify Docker is running**:
   ```bash
   sudo systemctl status docker
   ```
   - **Purpose**: Checks if Docker is active and running on your system.

5. **Start Docker if it is not running**:
   ```bash
   sudo systemctl start docker
   ```
   - **Purpose**: Starts the Docker service if it is not already active.

6. **Configure Docker Daemon**:
   Open the Docker daemon configuration file:
   ```bash
   sudo vi /etc/docker/daemon.json
   ```
   - **Append the following configuration block**:
     ```json
     {
       "exec-opts": ["native.cgroupdriver=systemd"],
       "log-driver": "json-file",
       "log-opts": {
         "max-size": "100m"
       },
       "storage-driver": "overlay2"
     }
     ```
   - **Purpose**: Configures Docker to use the `systemd` cgroup driver for better compatibility with Kubernetes, sets the log driver and options for log management, and specifies `overlay2` as the storage driver for optimal performance.

7. **Reload the Docker configuration and restart Docker**:
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl restart docker
   ```
   - **Purpose**: Reloads the system daemon to apply the new Docker configuration and restarts the Docker service for changes to take effect.

## Step 2: Install Kubernetes

To install Kubernetes, add its repository to your APT sources and install the necessary tools on each node.

1. **Add Kubernetes Signing Key**:
   ```bash
   curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
   ```
   - **Purpose**: Downloads and saves the signing key for the Kubernetes repository to verify the authenticity of the packages.

2. **Add Kubernetes Repository**:
   ```bash
   echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
   ```
   - **Purpose**: Adds the Kubernetes repository to the APT sources list, allowing you to install Kubernetes packages.

3. **Update Package List**:
   ```bash
   sudo apt update
   ```

4. **Install Kubernetes Tools**:
   ```bash
   sudo apt install kubeadm kubelet kubectl
   ```
   - **Purpose**: Installs `kubeadm` (for initializing clusters), `kubelet` (runs on each node), and `kubectl` (for cluster management).

5. **Hold the Packages**:
   ```bash
   sudo apt-mark hold kubeadm kubelet kubectl
   ```
   - **Purpose**: Prevents these packages from being automatically updated, ensuring version consistency.

6. **Verify Installation**:
   ```bash
   kubeadm version
   ```
   - **Purpose**: Checks if `kubeadm` is installed correctly and displays the version.

## Step 3: Deploy Kubernetes

### Prepare Nodes for Kubernetes

1. **Disable Swap**:
   ```bash
   sudo swapoff -a
   ```
   - **Purpose**: Disables swap to meet Kubernetes requirements for performance and stability.
   - **Update `fstab` to Disable Swap Permanently**:
     ```bash
     sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
     ```
     - **Purpose**: Prevents swap from reactivating on reboot.

2. **Load Required Modules**:
   Edit the containerd configuration file:
   ```bash
   sudo vi /etc/modules-load.d/containerd.conf
   ```
   - **Add**:
     ```
     overlay
     br_netfilter
     ```
   - **Purpose**: Enables necessary modules for container networking.

3. **Load the Modules**:
   ```bash
   sudo modprobe overlay
   sudo modprobe br_netfilter
   ```

4. **Configure Network Settings**:
   ```bash
   sudo vi /etc/sysctl.d/kubernetes.conf
   ```
   - **Add**:
     ```
     net.bridge.bridge-nf-call-ip6tables = 1
     net.bridge.bridge-nf-call-iptables = 1
     net.ipv4.ip_forward = 1
     ```
   - **Purpose**: Configures system network settings for Kubernetes.

5. **Reload the Configuration**:
   ```bash
   sudo sysctl --system
   ```

### Initialize the Cluster on the Master Node

1. **Set the Control Plane Endpoint**:
   ```bash
   sudo vi /etc/default/kubelet
   ```
   - **Add**:
     ```
     KUBELET_EXTRA_ARGS="--cgroup-driver=cgroupfs"
     ```
   - **Purpose**: Configures `kubelet` to use the `cgroupfs` driver.

2. **Reload and Restart Kubelet**:
   ```bash
   sudo systemctl daemon-reload && sudo systemctl restart kubelet
   ```

3. **Initialize the Cluster**:
   ```bash
   sudo kubeadm init --control-plane-endpoint=master-node --upload-certs
   ```

4. **Set Up `kubectl` Access for the Master Node**:
   ```bash
   mkdir -p $HOME/.kube
   sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
   sudo chown $(id -u):$(id -g) $HOME/.kube/config
   ```

## Step 4: Deploy Pod Network

1. **Install Flannel for Network Management**:
   ```bash
   kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
   ```
   - **Purpose**: Sets up the network between nodes using Flannel.

2. **Remove Taints**:
   ```bash
   kubectl taint nodes --all node-role.kubernetes.io/control-plane-
   ```
   - **Purpose**: Allows workloads to be scheduled on the master node.

## Step 5: Join Worker Nodes to the Cluster

1. **Run the `kubeadm join` Command on Worker Nodes**:
   ```bash
   sudo kubeadm join [master-node-ip]:6443 --token [token] --discovery-token-ca-cert-hash sha256:[hash]
   ```
   - **Purpose**: Connects the worker nodes to the master node.
   - **Replace `[master-node-ip]`, `[token]`, and `[hash]` with the actual values.**

2. **Check Cluster Status**:
   On the master node:
   ```bash
   kubectl get nodes
   ```
   - **Purpose**: Verifies that the worker nodes have successfully joined the cluster.

3. **Copy `kubelet` Config on Worker Nodes**:
   ```bash
   sudo cp /etc/kubernetes/kubelet.conf /root/.kube/config
   ```

## Conclusion

By following these steps, you have successfully installed and configured a Kubernetes cluster on Ubuntu 22.04. This guide covered the setup of Docker as the container runtime, installation of Kubernetes tools, and the deployment of a cluster with a network plugin for communication between nodes.

---

This version includes all the steps, with explanations and proper rephrasing to make it unique and clear. Let me know if you need any more adjustments!

---
These steps should be performed on each node to successfully set up a Kubernetes cluster. Ensure that each step is followed carefully, as misconfigurations can lead to issues in the cluster.

Author: Gautam Mallick
