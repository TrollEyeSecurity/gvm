#!/usr/bin/env bash
set -Eeuo pipefail

USERNAME=${USERNAME:-admin}
PASSWORD=${PASSWORD:-admin}

/etc/init.d/ssh start

./start_redis.sh

./start_postgres.sh

if [[ -f /var/run/ospd.pid ]]; then
  rm /var/run/ospd.pid
fi

if [[ -S /tmp/ospd.sock ]]; then
  rm /tmp/ospd.sock
fi

if [[ ! -d /var/run/ospd ]]; then
  mkdir /var/run/ospd
fi

./start_ospd-openvas.sh

echo "Starting Greenbone Vulnerability Manager..."
su -c "gvmd --unix-socket=/tmp/gvmd.sock --osp-vt-update=/tmp/ospd.sock" gvm

while  [[ ! -S /tmp/gvmd.sock ]]; do
	sleep 1
done

chmod 666 /tmp/gvmd.sock

until su -c "gvmd --get-users" gvm; do
	sleep 1
done

if [[ ! -f "/data/created_gvm_user" ]]; then
	echo "Creating Greenbone Vulnerability Manager admin user"
	su -c "gvmd --create-user=${USERNAME} --password=${PASSWORD}" gvm
	admin_user_uuid=$(su -c "gvmd --get-users --verbose| cut -d\" \" -f 2" gvm)
	su -c "gvmd --modify-setting 78eceaec-3385-11ea-b237-28d24461215b --value ${admin_user_uuid}" gvm

	touch /data/created_gvm_user
fi

tail -F /usr/local/var/log/gvm/*