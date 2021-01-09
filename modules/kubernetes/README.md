# Terraform Kubernetes

This module deploys a [Kubernetes](https://kubernetes.io/) cluster on AWS using [Kubeadm](https://kubernetes.io/docs/reference/setup-tools/kubeadm/)

![Kubernetes architecture](_docs/architecture.png)

## Requirements

* A DNS zone. The [kops documentation](https://github.com/kubernetes/kops/blob/master/docs/getting_started/aws.md#configure-dns) describes in details the way to do so.

## How to use the modules

This repository contains a _**bastion**_ and a _**kubernetes**_ [module](https://github.com/Smana/terraform-kubernetes/tree/main/modules).

```console
$ terraform init
$ terraform apply
```

When you apply this configuration you'll get a local **kubeconfig** in the root terraform directory.

```console
$ export KUBECONFIG=$(terraform output -json | jq -r '.kubeconfig.value')
```

From now on you can use the newly created Kubernetes cluster from your local machine (`kubectl`, `helm`)

```console
$ kubectl get nodes
NAME                                       STATUS     ROLES                  AGE     VERSION
ip-10-0-1-129.eu-west-3.compute.internal   NotReady   control-plane,master   2m31s   v1.20.1
ip-10-0-2-55.eu-west-3.compute.internal    NotReady   <none>                 58s     v1.20.1
```

## Post-apply actions

### CNI Plugin

* The cluster has been provision without `kube-proxy` that means that it is meant to be used with **Cilium**.
* I tried to use the Helm provider but I'm not sure this is actually useful as I want to use a GitOps tool for apps deployment. Currently, I decided to run the Helm command using the CLI for the CNI plugin.
* **Warning** about the pod CIDR, it must be different from the subnets you use within your VPC

Here is an example of a Helm command that installs Cilium with kube-proxy replacement.

```console
$ helm upgrade --install cilium cilium/cilium --version 1.9.1 --namespace kube-system \
--set kubeProxyReplacement='strict' \
--set k8sServiceHost=$(terraform output -json | jq -r '.api_dns.value'),k8sServicePort='6443' \
--set ipam.operator.clusterPoolIPv4PodCIDR="172.16.0.0/12"
```


### Additional control-planes for high availablity

**Note:** We use here a [stacked etcd topology](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/ha-topology/#stacked-etcd-topology). That means that the minimum of control plane instances for HA is 3.

```console
$ BASTION=$(terraform output -json | jq -r '.bastion_host.value')
$
```

## License

This code is released under the Apache 2.0 License. Please see [LICENSE](https://github.com/Smana/terraform-kubernetes/tree/main/LICENSE) for more details.
