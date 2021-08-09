#!/usr/bin/env bash

echo "Starting PostgreSQL..."
sudo -u postgres /usr/lib/postgresql/11/bin/pg_ctl -D /var/lib/postgresql/11/main/data -l /var/lib/postgresql/11/main/data/logfile start