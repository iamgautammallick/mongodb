#!/bin/bash

# Input parameters: Master node, Worker nodes, and Kubernetes version
master_node=$1
version=$2
worker_nodes=("${@:3}")

# Function to install Kubernetes components
install_kubernetes() {
  # Update and install Docker
  sudo apt update
  sudo apt install docker.io -y
  sudo systemctl enable docker
  sudo systemctl start docker

  # Install Kubernetes packages for the specified version
  curl -fsSL https://pkgs.k8s.io/core:/stable:/v$version/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
  echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v$version/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

  sudo apt update
  sudo apt install -y kubeadm=$version-00 kubelet=$version-00 kubectl=$version-00
  sudo apt-mark hold kubeadm kubelet kubectl
}

# Function to disable swap and configure sysctl parameters
configure_system() {
  sudo swapoff -a
  sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

  # Load kernel modules
  echo overlay >> /etc/modules-load.d/containerd.conf
  echo br_netfilter >> /etc/modules-load.d/containerd.conf
  sudo modprobe overlay
  sudo modprobe br_netfilter

  # Set sysctl parameters
  cat <<EOF | sudo tee /etc/sysctl.d/kubernetes.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
  sudo sysctl --system
}

# Function to configure Docker
configure_docker() {
  cat <<EOF | sudo tee /etc/docker/daemon.json
{
   "exec-opts": ["native.cgroupdriver=systemd"],
   "log-driver": "json-file",
   "log-opts": {
     "max-size": "100m"
   },
   "storage-driver": "overlay2"
}
EOF
  sudo systemctl daemon-reload
  sudo systemctl restart docker
}

# Function to initialize the control plane
initialize_control_plane() {
  sudo kubeadm init --control-plane-endpoint="$master_node" --upload-certs --kubernetes-version "v$version"
  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

  # Apply network plugin
  kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

  # Allow scheduling on the control plane node
  kubectl taint nodes --all node-role.kubernetes.io/control-plane-
}

# Function to upgrade Kubernetes version
upgrade_kubernetes() {
  echo "Upgrading Kubernetes to version $version..."
  sudo apt-mark unhold kubeadm kubelet kubectl
  sudo apt install -y kubeadm=$version-00 kubelet=$version-00 kubectl=$version-00
  sudo kubeadm upgrade apply "v$version" -y
  sudo systemctl daemon-reload
  sudo systemctl restart kubelet
  sudo apt-mark hold kubeadm kubelet kubectl

  # Uncordon nodes
  for worker_node in "${worker_nodes[@]}"; do
    kubectl uncordon $worker_node
  done
}

# Function to rollback Kubernetes version
rollback_kubernetes() {
  echo "Rolling back Kubernetes to version $version..."
  sudo apt-mark unhold kubeadm kubelet kubectl
  sudo apt install -y kubeadm=$version-00 kubelet=$version-00 kubectl=$version-00
  sudo kubeadm upgrade apply "v$version" -y
  sudo systemctl daemon-reload
  sudo systemctl restart kubelet
  sudo apt-mark hold kubeadm kubelet kubectl
}

# Prompt user for action: install, upgrade, or rollback
echo "Choose action: install, upgrade, rollback"
read action

case $action in
  install)
    install_kubernetes
    configure_system
    configure_docker
    if [[ "$HOSTNAME" == "$master_node" ]]; then
      initialize_control_plane
    else
      echo "Please copy the join command from the master node and run it here to join this worker to the cluster."
    fi
    ;;
  upgrade)
    upgrade_kubernetes
    ;;
  rollback)
    rollback_kubernetes
    ;;
  *)
    echo "Invalid action. Please choose 'install', 'upgrade', or 'rollback'."
    exit 1
    ;;
esac
