#!/usr/bin/env bash
export USERNAME=${USERNAME:-admin}
export PASSWORD=${PASSWORD:-admin}

# Setup and start ssh
sudo /etc/init.d/ssh start

# Start Redis, PostgreSQL, and OSPd
/start_redis.sh
/start_postgres.sh
/start_ospd-openvas.sh

sleep 2
# Start the core GVM processes (NO UI - GSA)
echo "Starting Greenbone Vulnerability Manager..."
sudo -u gvm gvmd --osp-vt-update=/run/ospd/ospd-openvas.sock --listen-group=gvm

while  [[ ! -S /run/gvmd/gvmd.sock ]]; do
	sleep 1
done

# make sure gmv-cli can access the gvmd.sock
sudo chmod 770 /run/gvmd/gvmd.sock

# Add GVM admin user
until sudo -u gvm gvmd --get-users; do
	sleep 1
done
echo "Creating Greenbone Vulnerability Manager admin user"
sudo -u gvm gvmd --user="${USERNAME}" --new-password="${PASSWORD}"
admin_user_uuid=$(sudo -u gvm gvmd --get-users --verbose | cut -d" " -f 2)
sudo -u gvm gvmd --modify-setting 78eceaec-3385-11ea-b237-28d24461215b --value "${admin_user_uuid}"

## Spew all the logs
sudo tail -F /var/log/gvm/*