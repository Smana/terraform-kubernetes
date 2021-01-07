## template: jinja
#!/bin/bash

set -o verbose
set -o errexit
set -o pipefail

export REGION=${region}
export SUBNETS="${subnets}"
export CLUSTER_NAME=${cluster_name}
export API_CNAME_DNS="${api_cname_dns}"
export API_ELB_DNS="${api_elb_dns}"
export CONTROL_PLANE_INDEX="${control_plane_index}"
export KUBEADM_TOKEN=${kubeadm_token}
export KUBERNETES_VERSION="1.20.1"

# Set this only after setting the defaults
set -o nounset

# --------------------------------
# containerd
# --------------------------------
cat > /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

# Setup required sysctl params, these persist across reboots.
cat > /etc/sysctl.d/99-kubernetes-cri.conf <<EOF
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sysctl --system

# Containerd configuration
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml

# Restart containerd
systemctl restart containerd
systemctl enable containerd

# --------------------------------
# kubeadm
# --------------------------------

# kubedm configuration
cat > /home/ubuntu/kubeadm.yaml <<EOF
---
apiVersion: kubeadm.k8s.io/v1beta2
kind: InitConfiguration
localAPIEndpoint:
 advertiseAddress: {{ ds.meta_data.local_ipv4 }}
 bindPort: 6443
bootstrapTokens:
- groups:
  - system:bootstrappers:kubeadm:default-node-token
  token: $KUBEADM_TOKEN
  ttl: 0s
  usages:
  - signing
  - authentication
nodeRegistration:
  kubeletExtraArgs:
    cloud-provider: {{ v1.cloud_name }}
    read-only-port: "10255"
    cgroup-driver: systemd
  name: {{ ds.meta_data.hostname }}
  taints:
  - effect: NoSchedule
    key: node-role.kubernetes.io/master
---
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
controlPlaneEndpoint: '$API_ELB_DNS:6443'
apiServer:
  certSANs:
  - $API_CNAME_DNS
  - $API_ELB_DNS
  - {{ ds.meta_data.local_ipv4}}
  - {{ ds.meta_data.hostname }}
  extraArgs:
    cloud-provider: aws
  timeoutForControlPlane: 5m0s
certificatesDir: /etc/kubernetes/pki
clusterName: kubernetes
controllerManager:
  extraArgs:
    cloud-provider: {{ v1.cloud_name }}
dns:
  type: CoreDNS
etcd:
  local:
    dataDir: /var/lib/etcd
imageRepository: k8s.gcr.io
kubernetesVersion: v$KUBERNETES_VERSION
networking:
  dnsDomain: cluster.local
---
EOF


if [ $CONTROL_PLANE_INDEX -eq 0 ]; then
  kubeadm reset --force
  kubeadm init --skip-phases=addon/kube-proxy --config /home/ubuntu/kubeadm.yaml

  cp /etc/kubernetes/admin.conf /home/ubuntu && chown ubuntu /home/ubuntu/admin.conf
  kubectl --kubeconfig /home/ubuntu/admin.conf config set-cluster kubernetes --server https://$API_CNAME_DNS:6443
else
  echo "ha control plane"
fi

# Start services
systemctl enable containerd kubelet
systemctl start containerd kubelet
