#!/usr/bin/env bash

echo "Starting Open Scanner Protocol daemon for OpenVAS..."
if [[ -f /var/run/ospd/ospd-openvas.pid ]]; then
  rm /var/run/ospd/ospd-openvas.pid
fi

if [[ -S /run/ospd/ospd.sock ]]; then
  rm /run/ospd/ospd.sock
fi

su - gvm -c "export PYTHONPATH=/opt/atomicorp/lib/python3.6/site-packages; /opt/atomicorp/bin/ospd-openvas --log-file /var/log/gvm/ospd-scanner.log --unix-socket /run/ospd/ospd.sock --pid-file /var/run/ospd/ospd-openvas.pid --log-file /var/log/gvm/ospd-scanner.log --lock-file-dir /var/run/gvm/ --log-level INFO"

while  [[ ! -S /run/ospd/ospd.sock ]]; do
	sleep 1
done

chmod 666 /run/ospd/ospd.sock