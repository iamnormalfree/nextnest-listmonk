FROM listmonk/listmonk:latest

# Install curl for health checks
USER root
RUN apk add --no-cache curl
USER listmonk

# Health check with longer timeout for Railway startup
HEALTHCHECK --interval=60s --timeout=30s --start-period=120s --retries=5 \
  CMD curl -f http://localhost:${PORT:-9000}/api/health || exit 1

# Start command that handles both install and run
CMD sh -c "./listmonk --install --yes --idempotent && ./listmonk"