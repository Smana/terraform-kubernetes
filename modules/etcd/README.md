# Terraform etcd module

Based on the following official doc:
[Etcd DNS discovery](https://etcd.io/docs/v2/clustering/#dns-discovery)
[Guide for AWS](https://etcd.io/docs/v3.4.0/platforms/aws/)
[Hardware recommendations](https://etcd.io/docs/v3.4.0/op-guide/hardware/)

After applying you can SSH to one of the node and run this command to check the etcd cluster status:

```console
ETCDCTL_API=3 etcdctl -w table --endpoints https://$(hostname -i|awk '{print $1}'):2379 --cacert /etc/etcd/tls/ca.pem --cert  /etc/etcd/tls/tls.pem --key  /etc/etcd/tls/tls.key member list
```