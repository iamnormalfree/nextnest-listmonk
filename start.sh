#!/bin/sh
set -e

echo "=== Listmonk Startup Script ==="
echo "Environment check:"
echo "PORT: ${PORT:-9000}"
echo "DATABASE_URL: ${DATABASE_URL:-(not set)}"
echo "All LISTMONK env vars:"
env | grep LISTMONK || echo "No LISTMONK vars found"

# Wait for database if needed
if [ -n "$DATABASE_URL" ]; then
    echo "Waiting for database connection..."
    sleep 15
fi

echo "Step 1: Installing database schema..."
./listmonk --install --idempotent --yes --config "" || {
    echo "Database install failed, but continuing..."
}

echo "Step 2: Upgrading database..."
./listmonk --upgrade --yes --config "" || {
    echo "Database upgrade failed, but continuing..."
}

echo "Step 3: Starting Listmonk server..."
echo "Listening on 0.0.0.0:${PORT:-9000}"

# Start in background and check if it's responding
./listmonk --config "" &
LISTMONK_PID=$!

# Wait a bit and check if the process is still running
sleep 10
if kill -0 $LISTMONK_PID 2>/dev/null; then
    echo "Listmonk started successfully (PID: $LISTMONK_PID)"
    # Check if port is listening
    netstat -ln | grep ":${PORT:-9000}" || echo "Warning: Port ${PORT:-9000} not found in netstat"
    wait $LISTMONK_PID
else
    echo "Listmonk process died"
    exit 1
fi