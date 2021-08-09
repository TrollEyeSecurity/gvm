#!/usr/bin/env bash

if [[ ! -d "/run/redis" ]]; then
	sudo mkdir /run/redis
fi

if  [[ -S /run/redis/redis.sock ]]; then
  sudo rm /run/redis/redis.sock
fi
sudo redis-server --unixsocket /run/redis/redis.sock --unixsocketperm 770 --timeout 0 --databases 128 --maxclients 512 --daemonize yes --port 6379 --bind 127.0.0.1 --logfile /var/log/gvm/redis-server.log

echo "Wait for redis socket to be created..."
while  [[ ! -S /run/redis/redis.sock ]]; do
  sleep 1
done

sudo chown redis:redis /run/redis/redis.sock

echo "Testing redis status..."
X="$(sudo redis-cli -s /run/redis/redis.sock ping)"
while  [[ "${X}" != "PONG" ]]; do
  echo "Redis is not yet ready..."
  sleep 1
  X="$(sudo redis-cli -s /run/redis/redis.sock ping)"
done
echo "Redis is ready."