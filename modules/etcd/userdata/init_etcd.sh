## template: jinja
#!/bin/bash

set -o verbose
set -o errexit
set -o pipefail

export ETCD_INDEX="${etcd_index}"

# Set this only after setting the defaults
set -o nounset

## Install etcd
ETCD_VERSION="v3.4.14"
ETCD_ARCHIVE="etcd-$ETCD_VERSION-linux-amd64.tar.gz"
DOWNLOAD_URL="https://storage.googleapis.com/etcd"

wget -qO /tmp/$ETCD_ARCHIVE $DOWNLOAD_URL/$ETCD_VERSION/$ETCD_ARCHIVE

sudo tar xzvf /tmp/$ETCD_ARCHIVE --strip-components=1  -C /usr/local/bin

sudo chmod +x /usr/local/bin/etcd
sudo chmod +x /usr/local/bin/etcdctl

rm -vf /tmp/$ETCD_ARCHIVE

## Install cfssl
CFSSL_VERSION="1.5.0"
for BIN in cfssl cfssljson; do
  sudo wget -qO /usr/local/bin/$BIN https://github.com/cloudflare/cfssl/releases/download/v"$CFSSL_VERSION"/"$BIN"_"$CFSSL_VERSION"_linux_amd64
  chmod +x /usr/local/bin/$BIN
done