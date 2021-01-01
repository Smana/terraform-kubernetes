## template: jinja
#!/bin/bash

set -o verbose
set -o errexit
set -o pipefail

export KUBEADM_TOKEN=${kubeadm_token}
export CONTROL_PLANE_DNS_NAME=${control_plane_dns_name}
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

# Start services
systemctl enable containerd kubelet
systemctl start containerd kubelet

# --------------------------------
# kubeadm
# --------------------------------

# kubedm configuration
cat > /home/ubuntu/kubeadm.yaml <<EOF
---
apiVersion: kubeadm.k8s.io/v1beta2
kind: JoinConfiguration
discovery:
  bootstrapToken:
    apiServerEndpoint: $CONTROL_PLANE_DNS_NAME:6443
    token: $KUBEADM_TOKEN
    unsafeSkipCAVerification: true
  timeout: 5m0s
  tlsBootstrapToken: $KUBEADM_TOKEN
nodeRegistration:
  kubeletExtraArgs:
    cloud-provider: {{ v1.cloud_name }}
    read-only-port: "10255"
    cgroup-driver: systemd
  name: {{ ds.meta_data.hostname }}
---
EOF

kubeadm reset --force
kubeadm join --config /tmp/kubeadm.yaml
