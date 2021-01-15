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

function wait_for_file()
{
    local RETRIES=12
    local ATTEMPT=0
    local SLEEP=2

    until [ $ATTEMPT -eq $RETRIES ]; do
      if [ ! -f $1 ]; then
        echo "warning: file $1 not present, waiting ..."
        sleep $SLEEP
        ((ATTEMPT=ATTEMPT+1))
      else
        return 0
      fi
    done
    echo "error: the file $1 not found !"
    exit 1
}

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

wait_for_file /etc/etcd/etcd.conf
wait_for_file /etc/etcd/tls/tls.pem

sudo systemctl start etcd