#!/usr/bin/env bash
export USERNAME=${USERNAME:-admin}
export PASSWORD=${PASSWORD:-admin}

# Setup and start ssh
ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N '' && ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key -N '' && ssh-keygen -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -N '' && ssh-keygen -t ed25519 -f  /etc/ssh/ssh_host_ed25519_key -N ''
/usr/sbin/sshd -D &

#Set sysctl
sysctl -w net.core.somaxconn=1024
sysctl vm.overcommit_memory=1

# Start Redis, PostgreSQL, and OSPd
./start_redis.sh
./start_postgres.sh
./start_ospd-openvas.sh

# Start the core GVM processes (NO UI - GSA)
echo "Starting Greenbone Vulnerability Manager..."
su -c "gvmd" gvm

while  [[ ! -S /var/run/gvm/gvmd.sock ]]; do
	sleep 1
done

# make sure gmv-cli can access the gvmd.sock
chmod 770 /var/run/gvm/gvmd.sock

# Make sure root is not greedy
chown gvm:gvm -R /var/run/ospd/
chown gvm:gvm -R /var/run/gvm/

# Add GVM admin user
until su -c "gvmd --get-users" gvm; do
	sleep 1
done
echo "Creating Greenbone Vulnerability Manager admin user"
su -c "gvmd --create-user=${USERNAME} --password=${PASSWORD}" gvm
admin_user_uuid=$(su -c "gvmd --get-users --verbose| cut -d\" \" -f 2" gvm)
su -c "gvmd --modify-setting 78eceaec-3385-11ea-b237-28d24461215b --value ${admin_user_uuid}" gvm

# Start GSAD
echo "Starting GSAD..."
/usr/sbin/gsad --munix-socket=/var/run/gvm/gvmd.sock

## Spew all the logs
tail -F /var/log/gvm/*