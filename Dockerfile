FROM ubuntu:22.04

LABEL maintainer="FreeRADIUS Admin"
LABEL description="FreeRADIUS with PostgreSQL support"

# Prevent interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    freeradius \
    freeradius-postgresql \
    freeradius-utils \
    postgresql-client \
    curl \
    vim \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create necessary directories
RUN mkdir -p /var/log/radius /app/sql \
    && chown -R freerad:freerad /var/log/radius \
    && chown -R freerad:freerad /etc/freeradius/3.0

# Copy SQL files for database initialization
COPY --chmod=644 sql/schema.sql sql/seed.sql /app/sql/

# Copy scripts
COPY --chmod=755 scripts/docker-entrypoint.sh /docker-entrypoint.sh
COPY --chmod=755 scripts/init-database.sh /init-database.sh

# Expose RADIUS ports
EXPOSE 1812/udp 1813/udp

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD radtest healthcheck healthcheck localhost 0 testing123 || exit 1

# Note: entrypoint will handle permissions and then run freeradius as freerad user
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["freeradius", "-f"]