#!/usr/bin/env bash
export USERNAME=${USERNAME:-admin}
export PASSWORD=${PASSWORD:-admin}

ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N '' && ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key -N '' && ssh-keygen -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -N '' && ssh-keygen -t ed25519 -f  /etc/ssh/ssh_host_ed25519_key -N ''

/usr/sbin/sshd -D &

./start_redis.sh

./start_postgres.sh

./start_ospd-openvas.sh

echo "Starting Greenbone Vulnerability Manager..."
su -c "gvmd --unix-socket=/tmp/gvmd.sock --osp-vt-update=/run/ospd/ospd.sock" gvm

while  [[ ! -S /tmp/gvmd.sock ]]; do
	sleep 1
done

chmod 666 /tmp/gvmd.sock

until su -c "gvmd --get-users" gvm; do
	sleep 1
done

echo "Creating Greenbone Vulnerability Manager admin user"
su -c "gvmd --create-user=${USERNAME} --password=${PASSWORD}" gvm
admin_user_uuid=$(su -c "gvmd --get-users --verbose| cut -d\" \" -f 2" gvm)
su -c "gvmd --modify-setting 78eceaec-3385-11ea-b237-28d24461215b --value ${admin_user_uuid}" gvm

tail -F /var/log/gvm/*