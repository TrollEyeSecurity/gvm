#!/usr/bin/env bash

echo "Starting Open Scanner Protocol daemon for OpenVAS..."
if [[ -f /var/run/ospd/ospd-openvas.pid ]]; then
  sudo rm /var/run/ospd/ospd-openvas.pid
fi

if [[ -S /run/ospd/ospd-openvas.sock ]]; then
  sudo rm /run/ospd/ospd-openvas.sock
fi

sudo -u gvm /usr/local/bin/ospd-openvas --log-file /var/log/gvm/ospd-scanner.log --unix-socket /run/ospd/ospd-openvas.sock --pid-file /var/run/ospd/ospd-openvas.pid --log-file /var/log/gvm/ospd-scanner.log --lock-file-dir /var/run/gvm/ --log-level INFO

while  [[ ! -S /run/ospd/ospd-openvas.sock ]]; do
	sleep 1
done

sudo chmod 666 /run/ospd/ospd-openvas.sock