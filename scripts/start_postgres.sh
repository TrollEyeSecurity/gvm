#!/usr/bin/env bash

echo "Starting PostgreSQL..."
sudo -u postgres /usr/lib/postgresql/13/bin/pg_ctl -D /var/lib/postgresql/13/main/data -l /var/lib/postgresql/13/main/data/logfile start
sleep 10