## template: jinja
#!/bin/bash

set -o verbose
set -o errexit
set -o pipefail

export ETCD_INDEX="${etcd_index}"
export NAMESPACE="${namespace}"
export DOMAIN_NAME="${domain_name}"
export MEMBER_NAME="${member_name}"
export MEMBER_DOMAIN_NAME="${member_domain_name}"

# Set this only after setting the defaults
set -o nounset

## Install etcd
ETCD_VERSION="v3.4.14"
ETCD_ARCHIVE="etcd-$ETCD_VERSION-linux-amd64.tar.gz"
DOWNLOAD_URL="https://storage.googleapis.com/etcd"

function wait_for_file()
{
    local RETRIES=60
    local ATTEMPT=0
    local SLEEP=6

    until [ $ATTEMPT -eq $RETRIES ]; do
      if [ ! -f "$1" ]; then
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

# Adding user etcd
useradd etcd -m -d /var/lib/etcd -s /bin/false

chown etcd /usr/local/bin/etcdctl
chown etcd /usr/local/bin/etcd

sudo chmod +x /usr/local/bin/etcd
sudo chmod +x /usr/local/bin/etcdctl

rm -vf /tmp/$ETCD_ARCHIVE

# Configure etcd
sudo mkdir -p /etc/etcd
sudo cat > /etc/etcd/etcd.conf <<EOF
ETCD_NAME=$MEMBER_NAME
ETCD_LISTEN_PEER_URLS="https://0.0.0.0:2380"
ETCD_LISTEN_CLIENT_URLS="https://0.0.0.0:2379"
ETCD_INITIAL_CLUSTER_TOKEN="$NAMESPACE-etcd-cluster"
ETCD_INITIAL_ADVERTISE_PEER_URLS="https://$MEMBER_DOMAIN_NAME:2380"
ETCD_ADVERTISE_CLIENT_URLS="https://$MEMBER_DOMAIN_NAME:2379"
ETCD_TRUSTED_CA_FILE="/etc/etcd/tls/ca.pem"
ETCD_CERT_FILE="/etc/etcd/tls/tls.pem"
ETCD_KEY_FILE="/etc/etcd/tls/tls.key"
ETCD_PEER_TRUSTED_CA_FILE="/etc/etcd/tls/ca.pem"
ETCD_PEER_KEY_FILE="/etc/etcd/tls/tls.key"
ETCD_PEER_CERT_FILE="/etc/etcd/tls/tls.pem"
ETCD_DATA_DIR="/var/lib/etcd"
EOF

sudo cat >  /lib/systemd/system/etcd.service <<EOF
[Unit]
Description=etcd key-value store
Documentation=https://github.com/etcd-io/etcd
User=etcd
Group=etcd
After=network.target

[Service]
Type=notify
EnvironmentFile=/etc/etcd/etcd.conf
ExecStart=/usr/local/bin/etcd --discovery-srv $DOMAIN_NAME --initial-cluster-state new
Restart=always
RestartSec=10s
LimitNOFILE=40000

[Install]
WantedBy=multi-user.target
EOF

for F in tls.pem tls.key ca.pem; do
  wait_for_file /etc/etcd/tls/$F
done
chown -R etcd /etc/etcd

sudo systemctl daemon-reload
sudo systemctl start etcd