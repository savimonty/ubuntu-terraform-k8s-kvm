#!/usr/bin/env bash

sudo kubeadm config images pull --kubernetes-version 1.28.1

# Deploy a cluster
sudo kubeadm init --kubernetes-version 1.28.1

# Configure kubectl
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Verify
kubectl get nodes
#o/p# NAME               STATUS     ROLES           AGE    VERSION
#o/p# control-plane-01   NotReady   control-plane   2m2s   v1.28.1


# Now install a networking provider to get things working. Deploy Calico Networking CNI:
# Perform the following steps on the Control Plane node. Download the Calico CNI manifest:
curl https://raw.githubusercontent.com/projectcalico/calico/v3.27.1/manifests/calico.yaml -O
kubectl apply -f calico.yaml

# Verify. Control Plane. Should be ready.
kubectl get nodes

echo "Run 'sudo kubeadm token create --print-join-command' to get workers to join this cluster"

echo "Done"
