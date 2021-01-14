#!/usr/bin/env bash

echo "Starting PostgreSQL..."
su - postgres -c "pg_ctl -D /var/lib/pgsql/data -l logfile start"