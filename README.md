# Install pre-reqs on Host
```
$ sudo apt-get install -y mkisofs xsltproc
```

# Create an SSH Keypair to access cluster nodes
```
$ mkdir ssh_keys
$ ssh-keygen -t ed25519 -f ./ssh_keys/id_ed25519
$ chmod 0400 ./ssh_keys/*
```

# Install KVM on Ubuntu
https://computingforgeeks.com/install-kvm-hypervisor-on-ubuntu-linux/

# Install Virt Manager on VM Host to view KVM Nodes
```
$ sudo apt install -y virt-manager
```

# Setup KVM and KVM bridge network
https://askubuntu.com/questions/1412503/setting-up-a-bridge-for-host-and-vm

# QEMU config change on Host to avoid AppArmor or SELinux issues
Double check that `security_driver = "none"` is uncommented in `/etc/libvirt/qemu.conf` and issue `sudo systemctl restart libvirtd` to restart the daemon.

Reference: https://github.com/dmacvicar/terraform-provider-libvirt/issues/546#issuecomment-612983090


# Reference: Terraform, KVM, Kubernetes Setup 
https://sysadminsignal.com/2023/06/22/a-pre-provisioned-kubernetes-cluster-solution-using-terraform-and-kvm


# Reference: Create virsh storage pool named default
Reference: https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/virtualization_administration_guide/sect-virtualization-storage_pools-creating-local_directories-virsh

```
$ sudo virsh pool-define-as default dir - - - - "/virsh-default-storage-pool"
Pool default defined

$ virsh pool-list --all
 Name   State   Autostart
---------------------------

$ sudo virsh pool-build default
Pool default built

$ sudo virsh pool-start default
Pool default started

$ sudo virsh pool-autostart default
Pool default marked as autostarted

$ sudo virsh pool-info default
Name:           default
UUID:           88ada7c2-86ec-47a0-8ea0-a69d601de36d
State:          running
Persistent:     yes
Autostart:      yes
Capacity:       622.59 GiB
Allocation:     113.77 GiB
Available:      508.82 GiB
```

# Run the Terraform script
```
$ terraform init
$ sudo terraform plan
$ sudo terraform apply -auto-approve
```

This should set up a 3 node cluster if KVM has been setup correctly.
Modify the `main.tf` file to your heart's content to play around with the declarative aspects.

`sudo` should not be needed after some tinkering with KVM/libvirt config and `usermod`.

# Post Terraform - Add Worker Nodes
After the terraform scripts are completed, the nodes are now ready and their NAT interfaces' IP addresses should be printed as outputs.

Another way to get the IP Addresses of the cluster:
```
$ sudo virsh net-dhcp-leases default
 ...
 ...
 2024-04-29 01:46:06   52:54:00:1e:22:be   ipv4       192.168.122.142/24   worker-node-02
 2024-04-29 01:46:06   52:54:00:22:8f:a3   ipv4       192.168.122.125/24   worker-node-01
 2024-04-29 01:46:01   52:54:00:ae:c3:83   ipv4       192.168.122.141/24   control-plane-01
 ...
 ... 
```
... including some other columns that I deleted to keep it neat here.

What's left? You need only to 'join' the worker nodes to the cluster and extract the control plane's kubeconfig file if you need to monitor it on the host or via Lens or another tool.

SSH into the control plane with the SSH Keypair created initially. Then run:
```
$ sudo kubeadm token create --print-join-command
kubeadm join <CONTROL_PLANE_IP>:6443 --token <TOKEN> --discovery-token-ca-cert-hash sha256:<TOKEN_HASH> 
```
This will print the command needed to get workers to join the cluster.

Now, SSH into each worker node and run this kubeadmin join command. You may need to use `sudo`.

On the control plane node observe the workers joining by issuing:
```
watch n -1 kubectl get nodes
Every 1.0s: kubectl get nodes                                                                        control-plane-01: Mon Apr 29 07:58:47 2024

NAME               STATUS   ROLES           AGE     VERSION
control-plane-01   Ready    control-plane   11m     v1.28.1
worker-node-01     Ready    <none>          2m50s   v1.28.1
worker-node-02     Ready    <none>          2m5s    v1.28.1

```

# Post Terraform - Extract the control plane node's kubeconfig
The command below copies the kube config from the control plane onto the current `pwd` and displays it in vscode if it exists and also as std output.
```
./config_host_kubeconfig.sh
config                                                                                                                        100% 5651     7.4MB/s   00:00    
NAME               STATUS   ROLES           AGE     VERSION
control-plane-01   Ready    control-plane   11m     v1.28.1
worker-node-01     Ready    <none>          3m8s    v1.28.1
worker-node-02     Ready    <none>          2m23s   v1.28.1

Control Plane Kube Config is at:
/home/savimonty/Projects/mine/terraform-k8s-kvm/k8s-builder/control_plane_kubeconfig

Command to set kubeconfig to control plane:
export KUBECONFIG="/home/savimonty/Projects/mine/terraform-k8s-kvm/k8s-builder/control_plane_kubeconfig" && kubectl get nodes


Displaying Control Pane's Kube Config in VSCode in case you need it for Lens
```


# Some caveats:
If you run ctrl-c during apply .. 
`Undefine` some pending domains that may remain after `$ terraform destroy`
```
$ sudo virsh list --all
$ sudo virsh undefine <domain_name>
```

# Terraform needs sudo