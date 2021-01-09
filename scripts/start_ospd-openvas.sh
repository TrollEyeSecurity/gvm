#!/usr/bin/env bash

echo "Starting Open Scanner Protocol daemon for OpenVAS..."
ospd-openvas --log-file /usr/local/var/log/gvm/ospd-openvas.log --unix-socket /tmp/ospd.sock --log-level INFO

while  [[ ! -S /tmp/ospd.sock ]]; do
	sleep 1
done

chmod 666 /tmp/ospd.sock