#!/usr/bin/env bash

go_home(){
  cd "$HOME" || exit
}

export INSTALL_PREFIX=/usr/local
export SOURCE_DIR=$HOME/source
export BUILD_DIR=$HOME/build
export INSTALL_DIR=$HOME/install
export GVM_VERSION=20.8.2
export GVMD_VERSION=$GVM_VERSION
export OPENVAS_SMB_VERSION=21.4.0
export GVM_LIBS_VERSION=$GVM_VERSION
export OPENVAS_SCANNER_VERSION=$GVM_VERSION
export OSPD_VERSION=20.8.3
export OSPD_OPENVAS_VERSION=$GVM_VERSION

go_home

# create the source, build, and install directories
mkdir -p "$SOURCE_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$INSTALL_DIR"

# Installing Common Build Dependencies
sudo apt install -y --no-install-recommends --assume-yes \
  bison \
  build-essential \
  cmake \
  curl \
  dpkg \
  fakeroot \
  gcc-mingw-w64 \
  gnupg \
  gnutls-bin \
  gpgsm \
  heimdal-dev \
  libgcrypt20-dev \
  libglib2.0-dev \
  libgnutls28-dev \
  libgpgme-dev \
  libhiredis-dev \
  libical-dev \
  libksba-dev \
  libldap2-dev \
  libnet1-dev \
  libpcap-dev \
  libpopt-dev \
  libpq-dev \
  libradcli-dev \
  libsnmp-dev \
  libssh-gcrypt-dev \
  libunistring-dev \
  libxml2-dev \
  nmap \
  nsis \
  openssh-client \
  perl-base \
  pkg-config \
  postgresql \
  postgresql-server-dev-11 \
  python-impacket \
  python3 \
  python3-cffi \
  python3-defusedxml \
  python3-lxml \
  python3-packaging \
  python3-paramiko \
  python3-pip \
  python3-psutil \
  python3-redis \
  python3-setuptools \
  python3-wrapt \
  redis-server \
  rpm \
  rsync \
  smbclient \
  snmp \
  socat \
  sshpass \
  openssh-server \
  texlive-fonts-recommended \
  texlive-latex-extra \
  uuid-dev \
  wget \
  xml-twig-tools \
  xmlstarlet \
  xsltproc \
  zip

# gvm-libs
curl -L https://github.com/greenbone/gvm-libs/archive/refs/tags/v$GVM_LIBS_VERSION.tar.gz -o "$SOURCE_DIR"/gvm-libs-$GVM_LIBS_VERSION.tar.gz
tar -C "$SOURCE_DIR" -xvzf "$SOURCE_DIR"/gvm-libs-$GVM_LIBS_VERSION.tar.gz
mkdir -p "$BUILD_DIR"/gvm-libs && cd "$BUILD_DIR"/gvm-libs || exit
cmake "$SOURCE_DIR"/gvm-libs-$GVM_LIBS_VERSION \
  -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX \
  -DCMAKE_BUILD_TYPE=Release \
  -DSYSCONFDIR=/etc \
  -DLOCALSTATEDIR=/var \
  -DGVM_PID_DIR=/run/gvm
make -j "$(nproc)"
make DESTDIR="$INSTALL_DIR" install
sudo cp -rv "$INSTALL_DIR"/* /
rm -rf "${INSTALL_DIR:?}"/*
go_home

# gvmd
curl -L https://github.com/greenbone/gvmd/archive/refs/tags/v$GVMD_VERSION.tar.gz -o "$SOURCE_DIR"/gvmd-$GVMD_VERSION.tar.gz
tar -C "$SOURCE_DIR" -xvzf "$SOURCE_DIR"/gvmd-$GVMD_VERSION.tar.gz
mkdir -p "$BUILD_DIR"/gvmd && cd "$BUILD_DIR"/gvmd || exit
cmake "$SOURCE_DIR"/gvmd-$GVMD_VERSION \
  -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX \
  -DCMAKE_BUILD_TYPE=Release \
  -DLOCALSTATEDIR=/var \
  -DSYSCONFDIR=/etc \
  -DGVM_DATA_DIR=/var \
  -DGVM_RUN_DIR=/run/gvm \
  -DOPENVAS_DEFAULT_SOCKET=/run/ospd/ospd-openvas.sock \
  -DSYSTEMD_SERVICE_DIR=/lib/systemd/system \
  -DDEFAULT_CONFIG_DIR=/etc/default \
  -DLOGROTATE_DIR=/etc/logrotate.d
make -j "$(nproc)"
make DESTDIR="$INSTALL_DIR" install
sudo cp -rv "$INSTALL_DIR"/* /
rm -rf "${INSTALL_DIR:?}"/*
go_home

# openvas-smb
curl -L https://github.com/greenbone/openvas-smb/archive/refs/tags/v$OPENVAS_SMB_VERSION.tar.gz -o "$SOURCE_DIR"/openvas-smb-$OPENVAS_SMB_VERSION.tar.gz
tar -C "$SOURCE_DIR" -xvzf "$SOURCE_DIR"/openvas-smb-$OPENVAS_SMB_VERSION.tar.gz
mkdir -p "$BUILD_DIR"/openvas-smb && cd "$BUILD_DIR"/openvas-smb || exit
cmake "$SOURCE_DIR"/openvas-smb-$OPENVAS_SMB_VERSION \
  -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX \
  -DCMAKE_BUILD_TYPE=Release
make -j "$(nproc)"
make DESTDIR="$INSTALL_DIR" install
sudo cp -rv "$INSTALL_DIR"/* /
rm -rf "${INSTALL_DIR:?}"/*
go_home

# openvas-scanner
curl -L https://github.com/greenbone/openvas-scanner/archive/refs/tags/v$OPENVAS_SCANNER_VERSION.tar.gz -o "$SOURCE_DIR"/openvas-scanner-$OPENVAS_SCANNER_VERSION.tar.gz
tar -C "$SOURCE_DIR" -xvzf "$SOURCE_DIR"/openvas-scanner-$OPENVAS_SCANNER_VERSION.tar.gz
mkdir -p "$BUILD_DIR"/openvas-scanner && cd "$BUILD_DIR"/openvas-scanner || exit
cmake "$SOURCE_DIR"/openvas-scanner-$OPENVAS_SCANNER_VERSION \
  -DCMAKE_INSTALL_PREFIX=$INSTALL_PREFIX \
  -DCMAKE_BUILD_TYPE=Release \
  -DSYSCONFDIR=/etc \
  -DLOCALSTATEDIR=/var \
  -DOPENVAS_FEED_LOCK_PATH=/var/lib/openvas/feed-update.lock \
  -DOPENVAS_RUN_DIR=/run/ospd
make -j "$(nproc)"
make DESTDIR="$INSTALL_DIR" install
sudo cp -rv "$INSTALL_DIR"/* /
rm -rf "${INSTALL_DIR:?}"/*
go_home

# ospd-openvas
curl -L https://github.com/greenbone/ospd/archive/refs/tags/v$OSPD_VERSION.tar.gz -o "$SOURCE_DIR"/ospd-$OSPD_VERSION.tar.gz
curl -L https://github.com/greenbone/ospd-openvas/archive/refs/tags/v$OSPD_OPENVAS_VERSION.tar.gz -o "$SOURCE_DIR"/ospd-openvas-$OSPD_OPENVAS_VERSION.tar.gz
tar -C "$SOURCE_DIR" -xvzf "$SOURCE_DIR"/ospd-$OSPD_VERSION.tar.gz
tar -C "$SOURCE_DIR" -xvzf "$SOURCE_DIR"/ospd-openvas-$OSPD_OPENVAS_VERSION.tar.gz
cd "$SOURCE_DIR"/ospd-$OSPD_VERSION || exit
python3 -m pip install . --prefix=$INSTALL_PREFIX --root="$INSTALL_DIR"
cd "$SOURCE_DIR"/ospd-openvas-$OSPD_OPENVAS_VERSION || exit
python3 -m pip install . --prefix=$INSTALL_PREFIX --root="$INSTALL_DIR" --no-warn-script-location
sudo cp -rv "$INSTALL_DIR"/* /
rm -rf "${INSTALL_DIR:?}"/*
go_home

# gvm-tools
python3 -m pip install --prefix=$INSTALL_PREFIX --root="$INSTALL_DIR" --no-warn-script-location gvm-tools
sudo cp -rv "$INSTALL_DIR"/* /
rm -rf "${INSTALL_DIR:?}"/*
go_home

# create the necessary links and cache to the most recent shared libraries
sudo ldconfig
