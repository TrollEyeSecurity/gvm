#!/usr/bin/env bash

echo "Starting PostgreSQL..."
/usr/bin/pg_ctlcluster --skip-systemctl-redirect 12 main start