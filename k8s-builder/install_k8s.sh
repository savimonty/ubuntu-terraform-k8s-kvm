#!/usr/bin/env bash

set -e

sudo apt update
sudo apt remove docker docker.io containerd runc

sudo apt update
sudo apt install -y ca-certificates curl gnupg

# Add the Docker repository GPG keys
sudo install -m 0755 -d /etc/apt/keyrings
sudo sh -c 'curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --yes --dearmor -o /etc/apt/keyrings/docker.gpg'
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add Docker repository
echo "deb [arch="$(dpkg --print-architecture)" \
signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu \
"$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" \
| sudo tee /etc/apt/sources.list.d/docker.list \
> /dev/null

# Install containerd
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add the ubuntu user to the docker group, and then enable the Docker daemon:
sudo usermod -aG docker ubuntu
sudo systemctl enable --now docker
# sudo systemctl status docker


# There’s an issue with the stock /etc/containerd/config.toml file and Kubernetes 1.26 and above.
# Set the configuration file aside, and restart the containerd service.

sudo mv /etc/containerd/config.toml /etc/containerd/config.toml.bak
sudo systemctl restart containerd

# There’s an issue with the stock /etc/containerd/config.toml file and Kubernetes 1.26 and above.
# Set the configuration file aside, and restart the containerd service.
sudo sh -c 'containerd config default > /etc/containerd/config.toml'
sudo sed -i '/SystemdCgroup/s/false/true/' /etc/containerd/config.toml
sudo sed -i '/sandbox_image/s/registry.k8s.io\/pause:3.6/registry.k8s.io\/pause:3.2/' /etc/containerd/config.toml
sudo systemctl restart containerd


sudo touch /etc/docker/daemon.json
cat <<EOF | sudo tee /etc/docker/daemon.json
{"exec-opts": ["native.cgroupdriver=systemd"]}
EOF

sudo systemctl restart docker

sudo sh -c 'docker info | grep Cgroup'
#o/p#  Cgroup Driver: systemd
#o/p#  Cgroup Version: 2

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter
sudo sh -c 'lsmod | grep -E "overlay|br_netfilter"'
#o/p# overlay
#o/p# br_netfilter
#o/p# br_netfilter           32768  0
#o/p# bridge                307200  1 br_netfilter
#o/p# overlay               151552  0


cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF


sudo sysctl --system
#o/p# 
#o/p# * Applying /etc/sysctl.d/k8s.conf ...
#o/p# net.bridge.bridge-nf-call-iptables = 1
#o/p# net.bridge.bridge-nf-call-ip6tables = 1
#o/p# net.ipv4.ip_forward = 1
#o/p#

#### NODE CONFIG COMPLETE 

# Install K8s: 1.28
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --yes --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list
sudo apt update
sudo apt install -y --allow-change-held-packages kubeadm kubelet kubectl
sudo apt-mark hold kubelet kubeadm kubectl
