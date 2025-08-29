#!/bin/sh
set -e

echo "=== Listmonk Startup Script ==="
echo "Environment check:"
echo "PORT: ${PORT:-9000}"
echo "DATABASE_URL: ${DATABASE_URL:-(not set)}"

# Wait for database if needed
if [ -n "$DATABASE_URL" ]; then
    echo "Waiting for database connection..."
    sleep 10
fi

echo "Step 1: Installing database schema..."
./listmonk --install --idempotent --yes --config ""

echo "Step 2: Upgrading database..."
./listmonk --upgrade --yes --config ""

echo "Step 3: Starting Listmonk server..."
echo "Listening on 0.0.0.0:${PORT:-9000}"
exec ./listmonk --config ""