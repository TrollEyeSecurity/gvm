#!/usr/bin/env bash

apt-get update

{ cat <<EOF
bison
build-essential
ca-certificates
cmake
curl
doxygen
git
gcc
gcc-mingw-w64
geoip-database
gnutls-bin
graphviz
heimdal-dev
ike-scan
libgcrypt20-dev
libglib2.0-dev
libgnutls28-dev
libgpgme11-dev
libgpgme-dev
libhiredis-dev
libical-dev
libksba-dev
libldap2-dev
libmicrohttpd-dev
libnet-snmp-perl
libpcap-dev
libpopt-dev
libsnmp-dev
libssh-gcrypt-dev
libxml2-dev
net-tools
nmap
nsis
openssh-client
openssh-server
perl-base
pkg-config
postgresql
postgresql-contrib
postgresql-server-dev-all
python3-defusedxml
python3-dialog
python3-lxml
python3-paramiko
python3-pip
python3-polib
python3-psutil
python3-setuptools
python3-dev
redis-server
redis-tools
rsync
sendmail
smbclient
texlive-fonts-recommended
texlive-latex-extra
uuid-dev
unzip
wapiti
wget
whiptail
xml-twig-tools
xmltoman
xsltproc
EOF
} | xargs apt-get install -yq --no-install-recommends

rm -rf /var/lib/apt/lists/*