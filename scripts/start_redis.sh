#!/usr/bin/env bash

if [[ ! -d "/run/redis" ]]; then
	mkdir /run/redis
fi
if  [[ -S /run/redis/redis.sock ]]; then
        rm /run/redis/redis.sock
fi
redis-server --unixsocket /run/redis/redis.sock --unixsocketperm 700 --timeout 0 --databases 128 --maxclients 512 --daemonize yes --port 6379 --bind 127.0.0.1

echo "Wait for redis socket to be created..."
while  [[ ! -S /run/redis/redis.sock ]]; do
        sleep 1
done

echo "Testing redis status..."
X="$(redis-cli -s /run/redis/redis.sock ping)"
while  [[ "${X}" != "PONG" ]]; do
        echo "Redis not yet ready..."
        sleep 1
        X="$(redis-cli -s /run/redis/redis.sock ping)"
done
echo "Redis ready."