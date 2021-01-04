# Terraform Kubernetes module

This module deploys a [Kubernetes](https://kubernetes.io/) cluster on AWS using [Kubeadm](https://kubernetes.io/docs/reference/setup-tools/kubeadm/)

![Kubernetes architecture](https://github.com/Smana/terraform-kubernetes/blob/master/_docs/architecture.png?raw=true)

## How to use this Module

This repo has the following folder structure:

* [modules](https://github.com/Smana/terraform-kubernetes/tree/main/modules): This folder contains a 'bastion' and a 'kubernetes' module.
* [examples](https://github.com/Smana/terraform-kubernetes/tree/main/examples): TODO
* [todo test](): Automated tests for the modules and examples.
* [root folder](): The root folder is *an example* ...


## Todo
* export the kubeconfig to be used with Helm
* install Cilium
* kubeadm control-plane high-availability
* Tests
* Examples
* Documentation: Provision the DNS zone, modules descriptions
## License