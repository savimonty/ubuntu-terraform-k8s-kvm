#!/usr/bin/env bash

set -e

IPWithMask=$(sudo virsh net-dhcp-leases default | grep control-plane-01 | awk -F' ' '{print $5}')
arrIN=(${IPWithMask//\// })
CONTROL_PLANE_IP_ONLY="${arrIN[0]}"

scp -i ./ssh_keys/id_ed25519 "ubuntu@${CONTROL_PLANE_IP_ONLY}:~/.kube/config" ./control_plane_kubeconfig

export KUBECONFIG="control_plane_kubeconfig"
kubectl get nodes

KUBECONFIG_PATH="$(pwd)/${KUBECONFIG}"
echo ""
echo -e "Control Plane Kube Config is at:\n${KUBECONFIG_PATH}\n"
echo -e "Command to set kubeconfig to control plane:\nexport KUBECONFIG=\"${KUBECONFIG_PATH}\" && kubectl get nodes"
echo ""

code -v >/dev/null 2>&1
[[ $? -eq 0 ]] && code "${KUBECONFIG_PATH}"

echo ""
echo "Displaying Control Pane's Kube Config in case you need it for Lens"
