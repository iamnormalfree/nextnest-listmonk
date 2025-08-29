FROM listmonk/listmonk:latest

# Install curl and setup startup script as root
USER root
RUN apk add --no-cache curl
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Disable Docker healthcheck - let Railway handle it
# HEALTHCHECK NONE

# Use the startup script
CMD ["/start.sh"]