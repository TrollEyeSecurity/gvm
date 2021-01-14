#!/usr/bin/env bash
export NON_INT=1
dnf install 'dnf-command(config-manager)' epel-release wget -y && dnf config-manager --set-enabled powertools && wget -q -O - https://updates.atomicorp.com/installers/atomic | sh && dnf update -y && \
 { cat <<EOF
gvm
openssh-server.x86_64
EOF
} | xargs dnf install -y
