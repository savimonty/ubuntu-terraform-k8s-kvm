#!/usr/bin/env bash

set -e

IPWithMask=$(sudo virsh net-dhcp-leases default | grep control-plane | awk -F' ' '{print $5}')
arrIN=(${IPWithMask//\// })
CONTROL_PLANE_IP_ONLY="${arrIN[0]}"

JOIN_COMMAND="$(ssh -i ./ssh_keys/id_ed25519 ubuntu@${CONTROL_PLANE_IP_ONLY} 'sudo kubeadm token create --print-join-command')"
echo "JOIN_COMMAND: ${JOIN_COMMAND}"

WORKER_IPsWithMask=( $(sudo virsh net-dhcp-leases default | grep worker-node | awk -F' ' '{print $5}') )
for WORKER in "${WORKER_IPsWithMask[@]}"
do
  WORKER_IP=(${WORKER//\// })
  echo "Joining ${WORKER_IP} into the cluster ... "
  set -x
    ssh -i ./ssh_keys/id_ed25519 ubuntu@${WORKER_IP} "sudo ${JOIN_COMMAND}"
  set +x
done
