FROM listmonk/listmonk:latest

# Install curl and setup startup script as root
USER root
RUN apk add --no-cache curl
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Health check with longer timeout for Railway deployment
HEALTHCHECK --interval=60s --timeout=30s --start-period=180s --retries=5 \
  CMD curl -f http://localhost:${PORT:-9000}/api/health || exit 1

# Use the startup script
CMD ["/start.sh"]