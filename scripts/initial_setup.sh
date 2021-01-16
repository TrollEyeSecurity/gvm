#!/usr/bin/env bash

function setup_postgres(){
    if [[ ! -f /var/lib/pgsql/initdb_postgresql.log ]]; then
        chown postgres:postgres -R /var/lib/pgsql/
        su - postgres -c "initdb -D /var/lib/pgsql/data --no-locale -E UTF8"
        ./start_postgres.sh
	    su - postgres -c "createuser -DRS gvm"
	    su - postgres -c "createdb -O gvm gvmd"
	    su - postgres -c "psql gvmd -q --command='create role dba with superuser noinherit;'"
	    su - postgres -c "psql gvmd -q --command='grant dba to gvm;'"
	    su - postgres -c "psql gvmd -q --command='create extension \"uuid-ossp\";'"
	    su - postgres -c "psql gvmd -q --command='create extension \"pgcrypto\";'"
    fi
}

function download_update() {
	RETRIES=0
	DOWNLOAD_SUCCESS=0
	COMMAND=$1
	TEST=$2
	MSG=$3

	echo "$COMMAND"

	while [[ ${DOWNLOAD_SUCCESS} -lt 1 ]]; do
		if [[ ${RETRIES} -gt 50 ]]; then
			echo "Download not successful: too many failed attempts"
			echo "  rerun  $COMMAND manually"
			return
		fi

		su - gvm -c "$COMMAND"

		if [[ -f ${TEST} ]] ; then
			echo "$COMMAND success"
			DOWNLOAD_SUCCESS=1
		else
			echo "Retrying in 60 seconds..."
			sleep 60
			RETRIES=$(( $RETRIES + 1 ))
		fi
	done

}

# Add user for gvm-cli
useradd --home-dir /home/gvm_user gvm_user
usermod -aG gvm gvm_user
chown gvm_user:gvm_user -R /home/gvm_user
echo "gvm_user:gvm_user" | chpasswd

#Python
alternatives --set python /usr/bin/python3
echo -e "\nInstalling GVM tools..."
pip3 install gvm-tools=="20.10.1"

# Set up postgres
setup_postgres

# Add gvm user to redis socket
if ! groups gvm |grep -q redis ; then
	usermod -aG redis gvm
fi

# Make sure root is not greedy
chown gvm:gvm -R /var/run/ospd/
chown gvm:gvm -R /var/run/gvm/

#Set sysctl
if ! grep -q "net.core.somaxconn=1024" /etc/sysctl.conf; then
	echo "net.core.somaxconn=1024"  >> /etc/sysctl.conf
fi
if ! grep -q "vm.overcommit_memory=1" /etc/sysctl.conf; then
	echo "vm.overcommit_memory=1" >> /etc/sysctl.conf
fi

#Disable transparent hugepages
if ! $(grub2-editenv - list | grep -q transparent_hugepage=never) ; then
	grub2-editenv - set "$(grub2-editenv - list | grep kernelopts) transparent_hugepage=never"
fi

# Download updates
echo "Update NVT, CERT, and SCAP data"
echo "Please note this step could take some time."

echo -e "\nUpdating NVTs...."
echo "#################################################################"
download_update /usr/bin/greenbone-nvt-sync /var/lib/gvm/plugins/plugin_feed_info.inc

echo -e "\nUpdating GVMD_DATA..."
echo "#################################################################"
download_update  "/usr/sbin/greenbone-feed-sync --type GVMD_DATA" /var/lib/gvm/data-objects/gvmd/timestamp

echo -e "\nUpdating SCAP data..."
echo "#################################################################"
download_update "/usr/sbin/greenbone-feed-sync --type SCAP" /var/lib/gvm/scap-data/official-cpe-dictionary_v2.2.xml

echo -e "\nUpdating CERT data..."
echo "#################################################################"
download_update "/usr/sbin/greenbone-feed-sync --type CERT"  /var/lib/gvm/cert-data/timestamp

# Handle certs
echo -n "\nUpdating OpenVAS Manager certificates: "
su - gvm -c "/usr/bin/gvm-manage-certs -V >/dev/null 2>&1"
if [[ $? -ne 0 ]]; then
	su - gvm -c "/usr/bin/gvm-manage-certs -a  >/dev/null 2>&1"
	echo "Complete"
else
	echo "Already Exists"
fi

# Start redis and ospd
./start_redis.sh
./start_ospd-openvas.sh

# Update VT Info and then rebuild SCAP and DB
echo -e "\nRemoving /var/run/gvm/feed-update.lock..."
echo "#################################################################"
while [[ -f /var/run/gvm/feed-update.lock ]]
do
    rm -rf /var/run/gvm/feed-update.lock
    sleep 2
done

echo -e "\nUpdating VT info for openvas..."
echo "#################################################################"
su - gvm -c "openvas --update-vt-info"

echo -e "\nRebuilding SCAP for gvmd..."
echo "#################################################################"
su -c "gvmd --rebuild-scap=ovaldefs" gvm

echo -e "\nRebuilding database for gvmd..."
echo "#################################################################"
su -c "gvmd --rebuild" gvm

echo "Cleaning up..."
su - postgres -c "pg_ctl -D /var/lib/pgsql/data -l logfile stop"
rm -rf /run/nologin
