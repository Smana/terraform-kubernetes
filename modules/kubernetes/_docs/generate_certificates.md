# Generate Kubeadm certs

In order to have the same certificates accross all the control-plane nodes, we'll create self-signed certificates using [cfssl](https://cfssl.org/)

For more info please have a look to the [Kubeadm documentation](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-certs/)

In the root path of this repository create a directory **pki** and generate a configuration for the root Certificate Autority.

```console
$ mkdir pki && cd pki

$ cfssl print-defaults config > ca-config.json
```

The file should contains this

```json
{
    "signing": {
        "default": {
            "expiry": "168h"
        },
        "profiles": {
            "kubernetes": {
                "expiry": "8760h",
                "usages": [
                    "signing",
                    "key encipherment",
                    "server auth"
                    "client auth"
                ]
            }
        }
    }
}
```

Create the CSR that contains the CA parameters

```console
$ cfssl print-defaults csr > ca-csr.json
```

```json
{
    "CN": "Kubernetes",
    "key": {
        "algo": "ecdsa",
        "size": 256
    },
    "names": [
        {
            "C": "FR",
            "ST": "France",
            "L": "Paris",
            "O": "CNCFParis"
        }
    ]
}

```

Run the certificate creation command

```console
$ cfssl gencert -initca ca-csr.json | cfssljson -bare ca
2021/01/08 20:47:32 [INFO] generating a new CA key and certificate from CSR
2021/01/08 20:47:32 [INFO] generate received request
2021/01/08 20:47:32 [INFO] received CSR
2021/01/08 20:47:32 [INFO] generating key: ecdsa-256
2021/01/08 20:47:32 [INFO] encoded CSR
2021/01/08 20:47:32 [INFO] signed certificate with serial number 649883787961335885955252016630161879600821806710
```

Finally we want to keep only 2 files in the pki directory

```console
$ rm -fv *.{json,csr}
removed 'ca-config.json'
removed 'ca-csr.json'
removed 'ca.csr'

$ mv -v ca.pem ca.crt
renamed 'ca.pem' -> 'ca.crt'

$ mv -v ca-key.pem ca.key
renamed 'ca-key.pem' -> 'ca.key'

$ ls
ca.crt  ca.key
```
