#!/bin/bash
set -e

echo "Checking if database tables exist..."

# Check if radcheck table exists
TABLE_EXISTS=$(psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tAc "SELECT COUNT(*) FROM information_schema.tables WHERE table_name='radcheck';")

if [ "$TABLE_EXISTS" -eq "0" ]; then
    echo "Tables don't exist. Running schema initialization..."
    psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f /docker-entrypoint-initdb.d/schema.sql
    
    echo "Running seed data..."
    psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f /docker-entrypoint-initdb.d/seed.sql
    
    echo "Database initialized successfully!"
else
    echo "Database tables already exist. Skipping initialization."
fi
