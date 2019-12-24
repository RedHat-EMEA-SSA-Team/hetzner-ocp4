#!/usr/bin/env bash
# set -x
set -e
TEMP_DIR=$(mktemp -d)

echo '
export HETZNER_HOSTNAME="{{ hetzner_hostname }}"
export HETZNER_IP="{{ hetzner_ip }}"
' >> $TEMP_DIR/env.j2

export ANSIBLE_LOCALHOST_WARNING=false
export ANSIBLE_REMOTE_TMP=/tmp

ansible localhost -e @cluster.yml -m template -a "src=$TEMP_DIR/env.j2 dest=cluster.env"

rm -rf $TEMP_DIR