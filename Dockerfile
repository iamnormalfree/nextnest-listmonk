FROM listmonk/listmonk:latest

# Install curl for health checks
USER root
RUN apk add --no-cache curl
USER listmonk

# Expose port
EXPOSE $PORT

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:$PORT/api/health || exit 1

# Start command with install flag for first run
CMD ["./listmonk", "--install"]