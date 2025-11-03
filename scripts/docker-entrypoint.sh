#!/bin/bash
#
# FreeRADIUS Docker Entrypoint Script
# 
# This script:
# - Waits for PostgreSQL to be ready
# - Copies configuration files with proper permissions
# - Tests FreeRADIUS configuration
# - Starts FreeRADIUS in normal or debug mode
#
set -e

echo "================================================"
echo "FreeRADIUS Docker Container Starting..."
echo "================================================"

# Function to wait for PostgreSQL
wait_for_postgres() {
    echo "Waiting for PostgreSQL at ${DB_HOST}:${DB_PORT}..."
    
    max_attempts=30
    attempt=0
    
    until pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" > /dev/null 2>&1; do
        attempt=$((attempt + 1))
        if [ $attempt -ge $max_attempts ]; then
            echo "ERROR: PostgreSQL is not available after ${max_attempts} attempts"
            exit 1
        fi
        echo "Waiting for PostgreSQL... (attempt $attempt/$max_attempts)"
        sleep 2
    done
    
    echo "PostgreSQL is ready!"
}

# Function to test database connection
test_db_connection() {
    echo "Testing database connection..."
    
    if PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1;" > /dev/null 2>&1; then
        echo "Database connection successful!"
        return 0
    else
        echo "ERROR: Cannot connect to database"
        return 1
    fi
}

# Function to enable SQL module and fix permissions
enable_sql_module() {
    echo "Enabling SQL module..."
    
    # Copy mounted config files to temporary location with correct permissions
    # This works around Docker Desktop on Windows permission issues
    echo "Copying configuration files with correct permissions..."
    
    if [ -f /mnt/clients.conf ]; then
        cp /mnt/clients.conf /etc/freeradius/3.0/clients.conf
        chmod 640 /etc/freeradius/3.0/clients.conf
        chown freerad:freerad /etc/freeradius/3.0/clients.conf
    fi
    
    if [ -f /mnt/users ]; then
        cp /mnt/users /etc/freeradius/3.0/users
        chmod 640 /etc/freeradius/3.0/users
        chown freerad:freerad /etc/freeradius/3.0/users
    fi
    
    if [ -f /mnt/mods-available-sql ]; then
        cp /mnt/mods-available-sql /etc/freeradius/3.0/mods-available/sql
        chmod 640 /etc/freeradius/3.0/mods-available/sql
        chown freerad:freerad /etc/freeradius/3.0/mods-available/sql
    fi
    
    if [ -f /mnt/mods-enabled-sql ]; then
        cp /mnt/mods-enabled-sql /etc/freeradius/3.0/mods-enabled/sql
        chmod 640 /etc/freeradius/3.0/mods-enabled/sql
        chown freerad:freerad /etc/freeradius/3.0/mods-enabled/sql
    fi
    
    if [ -f /mnt/sites-available-default ]; then
        cp /mnt/sites-available-default /etc/freeradius/3.0/sites-available/default
        chmod 640 /etc/freeradius/3.0/sites-available/default
        chown freerad:freerad /etc/freeradius/3.0/sites-available/default
    fi
    
    if [ -f /mnt/sites-enabled-default ]; then
        cp /mnt/sites-enabled-default /etc/freeradius/3.0/sites-enabled/default
        chmod 640 /etc/freeradius/3.0/sites-enabled/default
        chown freerad:freerad /etc/freeradius/3.0/sites-enabled/default
    fi
    
    echo "Configuration files copied with correct permissions"
}

# Function to test FreeRADIUS configuration
test_config() {
    echo "Testing FreeRADIUS configuration..."
    
    if freeradius -XC > /tmp/radiusd-config-test.log 2>&1; then
        echo "Configuration test passed!"
        return 0
    else
        echo "ERROR: Configuration test failed!"
        echo "Last 50 lines of configuration test output:"
        tail -n 50 /tmp/radiusd-config-test.log
        return 1
    fi
}

# Function to start in debug mode
start_debug_mode() {
    echo "================================================"
    echo "Starting FreeRADIUS in DEBUG mode..."
    echo "================================================"
    # Run as freerad user
    exec su -s /bin/bash freerad -c "freeradius -X"
}

# Function to start in normal mode
start_normal_mode() {
    echo "================================================"
    echo "Starting FreeRADIUS in normal mode..."
    echo "================================================"
    # Run as freerad user
    exec su -s /bin/bash freerad -c "$*"
}

# Main execution
main() {
    # Check if running as root (we shouldn't be)
    if [ "$(id -u)" = "0" ]; then
        echo "WARNING: Running as root. This is not recommended."
    fi
    
    # Wait for PostgreSQL if DB_HOST is set
    if [ -n "$DB_HOST" ]; then
        wait_for_postgres
        test_db_connection || exit 1
        
        # Initialize database schema if needed
        if [ -f /init-database.sh ]; then
            echo "Running database initialization check..."
            /init-database.sh
        fi
        
        enable_sql_module
    fi
    
    # Test configuration
    test_config || exit 1
    
    # Check if debug mode is requested
    if [ "$RADIUS_DEBUG" = "yes" ] || [ "$RADIUS_DEBUG" = "true" ] || [ "$RADIUS_DEBUG" = "1" ]; then
        start_debug_mode
    else
        start_normal_mode "$@"
    fi
}

# Execute main function
main "$@"