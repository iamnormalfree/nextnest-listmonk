FROM listmonk/listmonk:latest

# Copy custom config
COPY config.toml /listmonk/config.toml

# Expose port
EXPOSE $PORT

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:$PORT/api/health || exit 1

# Start command
CMD ["./listmonk", "--config=config.toml"]