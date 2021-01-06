provider "helm" {
  kubernetes {
    host        = format("https://%s:6443", module.kubernetes.api_dns)
    config_path = module.kubernetes.kubeconfig_local_path
  }
}

resource "helm_release" "cilium" {
  name       = "cilium"
  namespace  = "kube-system"
  repository = "https://helm.cilium.io/"
  chart      = "cilium"
  version    = "1.9.1"

  set {
    name  = "kubeProxyReplacement"
    value = "strict"
  }
  set {
    name  = "k8sServiceHost"
    value = "module.kubernetes.api_dns"
  }
  set {
    name  = "k8sServicePort"
    value = "6443"
  }
  set {
    name  = "ipam.operator.clusterPoolIPv4PodCIDR"
    value = "172.16.0.0/12"
  }
}
