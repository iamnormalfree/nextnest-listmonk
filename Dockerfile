FROM listmonk/listmonk:latest

# Expose port
EXPOSE $PORT

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:$PORT/api/health || exit 1

# Start command - Listmonk will use environment variables
CMD ["./listmonk"]