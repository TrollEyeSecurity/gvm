#!/usr/bin/env bash
export USERNAME=${USERNAME:-admin}
export PASSWORD=${PASSWORD:-admin}

page_separator="#################################################################"

function setup_postgres(){
    if [[ ! -f /var/lib/postgresql/13/main/initdb_postgresql.log ]]; then
        sudo chown postgres:postgres -R /var/lib/postgresql/13/main
        sudo -u postgres /usr/lib/postgresql/13/bin/initdb -D /var/lib/postgresql/13/main/data --no-locale -E UTF8
        /start_postgres.sh
	    sudo -u postgres createuser -DRS gvm
	    sudo -u postgres createdb -O gvm gvmd
	    sudo -u postgres psql gvmd -q --command='create role dba with superuser noinherit;'
	    sudo -u postgres psql gvmd -q --command='grant dba to gvm;'
	    sudo -u postgres psql gvmd -q --command='create extension "uuid-ossp";'
	    sudo -u postgres psql gvmd -q --command='create extension "pgcrypto";'
    fi
}

function do_nvt_sync() {
  COMMAND=$1
  DOWNLOAD_SUCCESS=0
  RETRIES=0
  while [[ ${DOWNLOAD_SUCCESS} -lt 1 ]]; do
		if [[ ${RETRIES} -gt 10 ]]; then
			echo "Download not successful: too many failed attempts"
			echo "rerun  $COMMAND manually"
			return 1
		fi
		sudo -u gvm "${COMMAND}"
		if [[ $? -ne 0 ]]; then
		  echo "Retrying in 30 seconds, attempt # ${RETRIES}..."
			sleep 30
			RETRIES=$(( $RETRIES + 1 ))
		else
		  DOWNLOAD_SUCCESS=1
		fi
	done
}

function do_feed_sync() {
	COMMAND=$1
	TYPE_FLAG=$2
	TYPE=$3
	DOWNLOAD_SUCCESS=0
	RETRIES=0
	while [[ ${DOWNLOAD_SUCCESS} -lt 1 ]]; do
		if [[ ${RETRIES} -gt 10 ]]; then
			echo "Download not successful: too many failed attempts"
			echo "rerun  $COMMAND manually"
			return 1
		fi
		sudo -u gvm "${COMMAND}" "${TYPE_FLAG}" "${TYPE}"
		if [[ $? -ne 0 ]]; then
		  echo "Retrying in 30 seconds, attempt # ${RETRIES}..."
			sleep 30
			RETRIES=$(( $RETRIES + 1 ))
		else
		  DOWNLOAD_SUCCESS=1
		fi
	done
}

# adjust user for gvm-cli
echo "gvm_user:gvm_user" | sudo chpasswd
sudo usermod -aG gvm gvm_user

# create dir
sudo mkdir /var/run/ospd/
sudo mkdir /var/run/gsad/
sudo touch /run/gvmd/gvmd.pid

# Adjusting directory permissions
sudo chown -R gvm:gvm /var/lib/gvm
sudo chown -R gvm:gvm /var/lib/openvas
sudo chown -R gvm:gvm /var/log/gvm
sudo chown -R gvm:gvm /run/gvmd
sudo chown -R gvm:gvm /run/gvm
sudo chown -R gvm:gvm /run/gsad
sudo chown -R gvm:gvm /run/ospd/

sudo chmod -R g+srw /var/lib/gvm
sudo chmod -R g+srw /var/lib/openvas
sudo chmod -R g+srw /var/log/gvm

# Adjusting gvmd permissions
sudo chown gvm:gvm /usr/local/sbin/gvmd
sudo chmod 6750 /usr/local/sbin/gvmd

# Adjusting feed sync script permissions
sudo chown gvm:gvm /usr/local/bin/greenbone-nvt-sync
sudo chmod 740 /usr/local/sbin/greenbone-feed-sync
sudo chown gvm:gvm /usr/local/sbin/greenbone-*-sync
sudo chmod 740 /usr/local/sbin/greenbone-*-sync

# Set up postgres
setup_postgres

# Add gvm user to redis socket
if ! groups gvm |grep -q redis ; then
	sudo usermod -aG redis gvm
fi

#Set sysctl
if ! grep -q "net.core.somaxconn=1024" /etc/sysctl.conf; then
	sudo bash -c 'echo "net.core.somaxconn=1024"  >> /etc/sysctl.conf'
fi
if ! grep -q "vm.overcommit_memory=1" /etc/sysctl.conf; then
	sudo bash -c 'echo "vm.overcommit_memory=1" >> /etc/sysctl.conf'
fi

sudo -u gvm gvmd --create-user="${USERNAME}" --password="${PASSWORD}"
sudo -u gvm gvmd --modify-setting 78eceaec-3385-11ea-b237-28d24461215b --value "$(sudo gvmd --get-users --verbose | grep admin | awk '{print $2}')"

# Download updates
echo "Update NVT, CERT, and SCAP data"
echo "Please note this step could take some time."
echo $page_separator

echo -e "\nUpdating NVTs...."
echo $page_separator
do_nvt_sync greenbone-nvt-sync || { echo -e "\nUpdating NVTs failed" ; exit 1; }
sleep 5

echo "Updating SCAP data..."
echo $page_separator
do_feed_sync greenbone-feed-sync --type SCAP || { echo -e "\nUpdating SCAP data failed" ; exit 1; }
sleep 5

echo "Updating CERT data..."
echo $page_separator
do_feed_sync greenbone-feed-sync --type CERT || { echo -e "\nUpdating CERT data failed" ; exit 1; }
sleep 5

echo "Updating GVMd data..."
echo $page_separator
do_feed_sync greenbone-feed-sync --type GVMD_DATA || { echo -e "\nUpdating GVMD_DATA data failed" ; exit 1; }

# Handle certs
echo -e "\nUpdating OpenVAS Manager certificates: "
sudo -u gvm /usr/local/bin/gvm-manage-certs -V >/dev/null 2>&1
# shellcheck disable=SC2181
if [[ $? -ne 0 ]]; then
sudo -u gvm /usr/local/bin/gvm-manage-certs -a >/dev/null 2>&1
	echo "Complete"
else
	echo "Already Exists"
fi

# Start redis and ospd
/start_redis.sh
/start_ospd-openvas.sh

# Update VT Info and then rebuild SCAP and DB
echo -e "\nRemoving feed-update.lock..."
echo $page_separator

while [[ -f /var/run/gvm/feed-update.lock ]]
do
    sudo rm -rf /var/run/gvm/feed-update.lock
    sleep 2
done

echo -e "\nUpdating VT info for openvas..."
echo $page_separator
sudo -u gvm openvas --update-vt-info

echo -e "\nRebuilding SCAP for gvmd..."
echo $page_separator
sudo -u gvm gvmd --rebuild-scap=ovaldefs

echo -e "\nRebuilding database for gvmd..."
echo $page_separator
sudo -u gvm gvmd --rebuild

echo "Cleaning up..."
echo $page_separator
sudo -u postgres /usr/lib/postgresql/13/bin/pg_ctl -D /var/lib/postgresql/13/main/data -l logfile stop
sudo rm -rf /run/nologin
# sudo rm -rm /var/log/gvm/*