#!/bin/bash
set -e

# This script ensures the database schema exists regardless of initialization state
# It runs as part of the FreeRADIUS container startup

echo "================================================"
echo "Checking Database Schema..."
echo "================================================"

# Wait for PostgreSQL to be ready
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

# Check if tables exist
TABLE_COUNT=$(PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -tAc "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public' AND table_name IN ('radcheck', 'radreply', 'radgroupcheck', 'radgroupreply', 'radusergroup', 'radacct', 'radpostauth', 'nas');" 2>/dev/null || echo "0")

if [ "$TABLE_COUNT" -lt "8" ]; then
    echo "Database tables missing or incomplete. Initializing..."
    
    # Run schema
    if [ -f /app/sql/schema.sql ]; then
        echo "Creating database schema..."
        PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f /app/sql/schema.sql
        echo "Schema created successfully!"
    fi
    
    # Run seed data
    if [ -f /app/sql/seed.sql ]; then
        echo "Seeding database..."
        PGPASSWORD="$DB_PASSWORD" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f /app/sql/seed.sql
        echo "Seed data inserted successfully!"
    fi
    
    echo "Database initialization complete!"
else
    echo "Database schema already exists (found $TABLE_COUNT tables). Skipping initialization."
fi

echo "================================================"
