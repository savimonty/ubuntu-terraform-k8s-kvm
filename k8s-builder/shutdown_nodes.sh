#!/usr/bin/env bash
nodes=$(kubectl get nodes -o wide | grep 192 | awk -v OFS='\t\t' '{print $6}')

echo "nodes: $nodes"

for node in ${nodes[@]}
    do
        echo "==== Shut down $node ===="
        set -x
            ssh ubuntu@$node sudo shutdown -h 1
        set +x
    done
