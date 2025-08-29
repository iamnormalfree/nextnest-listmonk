#!/bin/sh
set -x  # Enable debug mode to see all commands

echo "=== Listmonk Startup Script ==="
echo "Current working directory: $(pwd)"
echo "Listmonk binary exists: $(ls -la ./listmonk 2>/dev/null || echo 'NOT FOUND')"
echo "Environment check:"
echo "PORT: ${PORT:-9000}"
echo "DATABASE_URL: ${DATABASE_URL:-(not set)}"
echo "All LISTMONK env vars:"
env | grep LISTMONK | head -20 || echo "No LISTMONK vars found"

# Test if we can run listmonk at all
echo "Testing listmonk binary..."
./listmonk --help | head -5 || {
    echo "ERROR: Cannot execute listmonk binary"
    exit 1
}

# Wait for database if needed
if [ -n "$DATABASE_URL" ]; then
    echo "Waiting for database connection..."
    sleep 20
fi

echo "Step 1: Installing database schema..."
./listmonk --install --idempotent --yes --config "" 2>&1 || {
    echo "Database install failed, continuing anyway..."
}

echo "Step 2: Upgrading database..."
./listmonk --upgrade --yes --config "" 2>&1 || {
    echo "Database upgrade failed, continuing anyway..."
}

echo "Step 3: Starting Listmonk server..."
echo "Will bind to: 0.0.0.0:${PORT:-9000}"

# Start listmonk in foreground with full output
exec ./listmonk --config ""