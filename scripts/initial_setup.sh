#!/usr/bin/env bash

if  [[ ! -d /data ]]; then
	echo "Creating Data folder..."
        mkdir /data
fi
if  [[ ! -d /data/database ]]; then
	echo "Creating Database folder..."
	mv /var/lib/postgresql/12/main /data/database
	ln -s /data/database /var/lib/postgresql/12/main
	chown postgres:postgres -R /var/lib/postgresql/12/main
	chown postgres:postgres -R /data/database
fi
if [[ -d /var/lib/postgresql/12/main ]]; then
	echo "Fixing Database folder..."
	rm -rf /var/lib/postgresql/12/main
	ln -s /data/database /var/lib/postgresql/12/main
	chown postgres:postgres -R /var/lib/postgresql/12/main
	chown postgres:postgres -R /data/database
fi

./start_redis.sh

./start_postgres.sh

if [[ ! -f "/firstrun" ]]; then
	echo "Running first start configuration..."
	echo "Creating Openvas NVT sync user..."
	useradd --home-dir /usr/local/share/openvas openvas-sync
	mkdir /usr/local/var/lib/gvm/cert-data
	mkdir /home/openvas_user
	chown openvas-sync:openvas-sync -R /usr/local/share/openvas
	chown openvas-sync:openvas-sync -R /usr/local/var/lib/openvas
	echo "Creating Greenbone Vulnerability system user..."
	useradd --home-dir /usr/local/share/gvm gvm
	useradd --home-dir /home/openvas_user openvas_user
	usermod -a -G openvas_user gvm
	chown gvm:gvm -R /usr/local/share/gvm
	chown gvm:gvm -R /usr/local/var/lib/gvm
	chown gvm:gvm -R /usr/local/var/log/gvm
	chmod 770 -R /usr/local/var/lib/gvm
	chown gvm:gvm -R /usr/local/var/run
	chmod g+w /usr/local/var/run
	chown openvas-sync:openvas-sync /usr/local/var/lib/gvm/cert-data
	chown openvas_user:openvas_user -R /home/openvas_user
	adduser openvas-sync gvm
	adduser gvm openvas-sync
	useradd --home-dir /usr/local/share/gvm openvas
	echo "openvas_user:openvas_user" | chpasswd
	touch /firstrun
fi
if [[ ! -f "/data/firstrun" ]]; then
	echo "Creating Greenbone Vulnerability Manager database"
	su -c "createuser -DRS gvm" postgres
	su -c "createdb -O gvm gvmd" postgres
	su -c "psql --dbname=gvmd --command='create role dba with superuser noinherit;'" postgres
	su -c "psql --dbname=gvmd --command='grant dba to gvm;'" postgres
	su -c "psql --dbname=gvmd --command='create extension \"uuid-ossp\";'" postgres
	su -c "psql --dbname=gvmd --command='create extension \"pgcrypto\";'" postgres
	touch /data/firstrun
fi
if  [[ ! -d /data/gvmd ]]; then
	echo "Creating gvmd folder..."
	mkdir /data/gvmd
	chown gvm:gvm -R /data/gvmd
	rm -rf /usr/local/var/lib/gvm/gvmd
	ln -s /data/gvmd /usr/local/var/lib/gvm/gvmd
fi

echo -e "\nUpdating NVTs..."
echo "#################################################################"
su -c "/usr/local/bin/greenbone-nvt-sync" openvas-sync
sleep 5

echo -e "\nUpdating GVMD Data..."
echo "#################################################################"
su -c "/usr/local/sbin/greenbone-feed-sync --type GVMD_DATA" openvas-sync
sleep 5

echo -e "\nUpdating SCAP data..."
echo "#################################################################"
su -c "/usr/local/sbin/greenbone-feed-sync --type SCAP" openvas-sync
sleep 5

echo -e "\nUpdating CERT data..."
echo "#################################################################"
su -c "/usr/local/sbin/greenbone-feed-sync --type CERT" openvas-sync
sleep 5

# todo: test and add Vulners
# echo -e "\nAdding Vulners..."
# echo "#################################################################"
# for file in vulners/*.zip;
# do
#    :
#    unzip ${file} -d /usr/local/var/lib/openvas/plugins/private/
# done

if [[ ! -d /var/run/ospd ]]; then
  mkdir /var/run/ospd
fi

./start_ospd-openvas.sh

echo -e "\nMigrate the database..."
echo "#################################################################"
su -c "gvmd --osp-vt-update=/tmp/ospd.sock --migrate" gvm
sleep 5

echo -e "\nRebuilding SCAP for gvmd..."
echo "#################################################################"
su -c "gvmd --osp-vt-update=/tmp/ospd.sock --rebuild-scap=ovaldefs" gvm
sleep 5

echo -e "\nRebuilding database for gvmd..."
echo "#################################################################"
su -c "gvmd --osp-vt-update=/tmp/ospd.sock --rebuild" gvm