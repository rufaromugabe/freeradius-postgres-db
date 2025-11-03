# FreeRADIUS with PostgreSQL Docker Setup

Complete production-ready FreeRADIUS server with PostgreSQL backend, built with custom Dockerfile and entrypoint scripts.

## Features

- ✅ **Custom Docker Build**: FreeRADIUS with PostgreSQL support
- ✅ **Automated Setup**: Entrypoint script handles initialization
- ✅ **Database Backend**: PostgreSQL for users, clients, and accounting
- ✅ **Health Checks**: Automatic health monitoring
- ✅ **Debug Mode**: Easy debug mode via environment variable
- ✅ **Makefile**: Convenient management commands
- ✅ **Sample Data**: Pre-configured test users and groups

## Quick Start

### Prerequisites

- Docker and Docker Compose
- `radtest` utility (optional, for testing):

  ```bash
  # Ubuntu/Debian
  sudo apt-get install freeradius-utils

  # macOS
  brew install freeradius-server
  ```

### 1. Directory Structure

Create the following structure:

```
.
├── docker-compose.yml
├── Dockerfile
├── .env
├── Makefile
├── scripts/
│   └── docker-entrypoint.sh
├── sql/
│   ├── schema.sql
│   └── seed.sql
└── raddb/
    ├── clients.conf
    ├── mods-available/
    │   └── sql
    ├── mods-enabled/
    │   └── sql (copy of mods-available/sql)
    └── sites-available/
        └── default
```

### 2. Setup

```bash
# Create directories
mkdir -p scripts sql raddb/mods-available raddb/mods-enabled raddb/sites-available

# Copy configuration files to their locations
# (Place all the provided files in the correct directories)

# Copy the SQL config to both locations
cp raddb/mods-available/sql raddb/mods-enabled/sql

# Create .env file from example
cp .env.example .env

# Edit .env and change passwords (important for production!)
nano .env
```

### 3. Build and Start

```bash
# Build the image
make build

# Start all services
make up

# View logs
make logs
```

### 4. Test Authentication

```bash
# Test with sample users
make test          # Tests user 'bob'
make test-all      # Tests all sample users

# Or manually:
radtest bob test 127.0.0.1 0 testing123
radtest alice password123 127.0.0.1 0 testing123
```

## Using the Makefile

The Makefile provides convenient commands for managing the system:

```bash
# Service Management
make build          # Build FreeRADIUS Docker image
make up             # Start all services
make down           # Stop all services
make restart        # Restart all services
make status         # Show container status

# Debugging and Logs
make logs           # View all logs
make logs-radius    # View FreeRADIUS logs only
make logs-db        # View PostgreSQL logs only
make debug          # Start FreeRADIUS in debug mode (-X)

# Shell Access
make shell          # Open bash shell in FreeRADIUS container
make shell-db       # Open PostgreSQL shell

# Testing
make test           # Test authentication with bob user
make test-all       # Test all sample users

# Database Management
make users          # List all users
make sessions       # Show active sessions
make auth-log       # Show authentication log
make add-user USER=testuser PASS=testpass
make remove-user USER=testuser

# Backup and Restore
make backup         # Backup database
make restore FILE=backups/radius_backup_20241103_120000.sql

# Cleanup
make clean          # Stop and remove all containers and volumes
```

## Sample Users

The setup includes these pre-configured users:

| Username    | Password    | Group     | VLAN | Notes                       |
| ----------- | ----------- | --------- | ---- | --------------------------- |
| bob         | test        | employees | -    | Basic user                  |
| alice       | password123 | vip       | 100  | Has VLAN assignment         |
| guest1      | guestpass   | guest     | -    | Time-limited session        |
| admin       | admin123    | -         | 200  | Admin with VLAN 200         |
| healthcheck | healthcheck | -         | -    | For container health checks |

## Database Management

Add PostgreSQL server:

- Host: `postgres`
- Port: `5432`
- Database: `radius`
- Username: `radius`
- Password: `radiuspassword` (or your custom password from .env)

### Using psql Command Line

```bash
# Open PostgreSQL shell
make shell-db

# Or manually
docker exec -it freeradius-postgres psql -U radius -d radius

# Useful queries
SELECT * FROM radcheck;                    # List all users
SELECT * FROM user_sessions;               # Active sessions
SELECT * FROM auth_log;                    # Recent auth attempts
SELECT * FROM nas;                         # List NAS devices
```

## Configuration

### Environment Variables (.env)

```bash
# Database
POSTGRES_PASSWORD=your_secure_password
DB_PASSWORD=your_secure_password

# Debug mode
RADIUS_DEBUG=no  # Set to 'yes' for debug mode

# Ports
RADIUS_AUTH_PORT=1812
RADIUS_ACCT_PORT=1813
```

### Adding RADIUS Clients (NAS)

**Option 1: Database (Recommended)**

```sql
INSERT INTO nas (nasname, shortname, type, secret, description) VALUES
('192.168.1.10', 'wifi-ap-01', 'cisco', 'your_secret', 'WiFi Access Point');
```

**Option 2: Configuration File**

Edit `raddb/clients.conf`:

```conf
client wifi_ap {
    ipaddr = 192.168.1.10
    secret = your_secret
    require_message_authenticator = yes
    nas_type = cisco
}
```

### Adding Users

**Via Makefile:**

```bash
make add-user USER=newuser PASS=newpass
```

**Via SQL:**

```sql
-- Simple user
INSERT INTO radcheck (username, attribute, op, value)
VALUES ('newuser', 'Cleartext-Password', ':=', 'password');

-- User with VLAN assignment
INSERT INTO radcheck (username, attribute, op, value)
VALUES ('vlanuser', 'Cleartext-Password', ':=', 'password');

INSERT INTO radreply (username, attribute, op, value) VALUES
('vlanuser', 'Tunnel-Type', ':=', 'VLAN'),
('vlanuser', 'Tunnel-Medium-Type', ':=', 'IEEE-802'),
('vlanuser', 'Tunnel-Private-Group-Id', ':=', '100');
```

### Creating User Groups

```sql
-- Create group
INSERT INTO radgroupcheck (groupname, attribute, op, value)
VALUES ('contractors', 'Auth-Type', ':=', 'Accept');

-- Add group attributes
INSERT INTO radgroupreply (groupname, attribute, op, value) VALUES
('contractors', 'Session-Timeout', ':=', '14400'),
('contractors', 'Idle-Timeout', ':=', '900');

-- Assign user to group
INSERT INTO radcheck (username, attribute, op, value)
VALUES ('contractor1', 'Cleartext-Password', ':=', 'pass123');

INSERT INTO radusergroup (username, groupname, priority)
VALUES ('contractor1', 'contractors', 1);
```

## Debug Mode

### Via Environment Variable

```bash
# Set in .env
RADIUS_DEBUG=yes

# Restart
make restart
make logs-radius
```

### Via Makefile

```bash
# This stops the current container and starts in debug mode
make debug
```

### Manual Debug

```bash
docker-compose exec freeradius radiusd -X
```

## Monitoring and Accounting

### View Active Sessions

```bash
make sessions

# Or via SQL
SELECT
    username,
    nasipaddress,
    acctstarttime,
    acctinputoctets,
    acctoutputoctets
FROM radacct
WHERE acctstoptime IS NULL;
```

### View Authentication Log

```bash
make auth-log

# Or via SQL
SELECT
    username,
    reply,
    authdate,
    callingstationid
FROM radpostauth
ORDER BY authdate DESC
LIMIT 50;
```

### Session History for User

```sql
SELECT
    acctstarttime,
    acctstoptime,
    acctsessiontime,
    acctinputoctets + acctoutputoctets as total_bytes,
    nasipaddress
FROM radacct
WHERE username = 'bob'
ORDER BY acctstarttime DESC;
```

## Backup and Restore

### Automated Backups

```bash
# Create backup (saves to backups/ directory)
make backup

# Restore from backup
make restore FILE=backups/radius_backup_20241103_120000.sql
```

### Manual Backups

```bash
# Backup
docker exec freeradius-postgres pg_dump -U radius radius > backup.sql

# Restore
cat backup.sql | docker exec -i freeradius-postgres psql -U radius radius
```

### Scheduled Backups (Cron)

```bash
# Add to crontab
0 2 * * * cd /path/to/freeradius && make backup
```

## Security Considerations

### Critical for Production

1. **Change All Default Passwords**

   - PostgreSQL password in `.env`
   - RADIUS client secrets in `clients.conf` and `nas` table
   - User passwords

2. **Use Strong Secrets**

   ```bash
   # Generate random secret
   openssl rand -base64 32
   ```

3. **Replace Self-Signed Certificates**

   - Default certs are in `/etc/raddb/certs/`
   - Replace with proper certificates for production

4. **Network Security**

   - Restrict access to RADIUS ports (1812/1813)
   - Use firewall rules
   - Consider VPN or private networks

5. **Database Security**

   - Don't expose PostgreSQL port externally
   - Use strong passwords
   - Enable SSL/TLS for production
   - Regular backups

6. **File Permissions**

   ```bash
   chmod 600 .env
   chmod 600 raddb/clients.conf
   ```

7. **Regular Updates**
   ```bash
   docker-compose pull
   make build
   ```

## Troubleshooting

### Container Won't Start

```bash
# Check logs
make logs

# Test configuration
docker-compose exec freeradius radiusd -XC

# Check database connectivity
docker exec freeradius-postgres pg_isready -U radius
```

### Authentication Fails

1. **Enable debug mode:**

   ```bash
   make debug
   ```

2. **Check user exists:**

   ```bash
   make shell-db
   SELECT * FROM radcheck WHERE username='bob';
   ```

3. **Verify client secret:**

   - Check `clients.conf` or `nas` table
   - Must match the secret used in `radtest`

4. **Check authentication log:**
   ```bash
   make auth-log
   ```

### SQL Module Not Loading

```bash
# Check if SQL module is enabled
docker exec freeradius-server ls -la /etc/raddb/mods-enabled/sql

# Verify SQL configuration
docker exec freeradius-server cat /etc/raddb/mods-available/sql

# Test configuration
docker exec freeradius-server radiusd -XC
```

### Database Connection Issues

```bash
# Test from FreeRADIUS container
docker exec freeradius-server pg_isready -h postgres -p 5432 -U radius

# Check environment variables
docker exec freeradius-server env | grep DB_
```

### Performance Issues

- Increase PostgreSQL connection pool in SQL module
- Add database indexes
- Monitor database performance with PostgreSQL tools
- Check container resources: `docker stats`

## Common Use Cases

### WiFi Authentication (WPA2-Enterprise)

1. Add WiFi AP to database:

   ```sql
   INSERT INTO nas (nasname, shortname, type, secret, description)
   VALUES ('192.168.1.10', 'wifi-ap', 'cisco', 'secret123', 'Main WiFi AP');
   ```

2. Configure AP:

   - RADIUS Server: Docker host IP
   - Port: 1812
   - Secret: match the database

3. Users authenticate with credentials from `radcheck` table

### VPN Authentication

1. Add VPN server to NAS table
2. Configure VPN to use RADIUS
3. Users can authenticate with database credentials

### 802.1X Network Access Control

1. Add network switches to NAS table
2. Configure VLAN assignments in `radreply`
3. Enable dynamic VLAN assignment on switches

### Guest Portal with Time Limits

Users in the `guest` group automatically get:

- 1 hour session timeout
- 10 minute idle timeout

## Maintenance

### Cleanup Old Records

```sql
-- Delete accounting older than 90 days
DELETE FROM radacct
WHERE acctstoptime < NOW() - INTERVAL '90 days';

-- Delete old auth logs
DELETE FROM radpostauth
WHERE authdate < NOW() - INTERVAL '90 days';

-- Vacuum database
VACUUM ANALYZE;
```

### Monitor Database Size

```bash
docker exec freeradius-postgres psql -U radius -d radius -c \
  "SELECT pg_size_pretty(pg_database_size('radius'));"
```

### Update Images

```bash
# Pull latest images
docker-compose pull

# Rebuild custom image
make build

# Restart
make restart
```

## Docker Entrypoint Features

The custom entrypoint script (`docker-entrypoint.sh`) provides:

- ✅ PostgreSQL connection waiting with retry logic
- ✅ Database connection testing
- ✅ Automatic SQL module enablement
- ✅ Configuration validation before startup
- ✅ Debug mode support via environment variable
- ✅ Detailed startup logging
- ✅ Proper error handling

## Additional Resources

- [FreeRADIUS Documentation](https://freeradius.org/documentation/)
- [FreeRADIUS Wiki](https://wiki.freeradius.org/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

## Support

For issues and questions:

- Check the logs: `make logs`
- Run in debug mode: `make debug`
- Review FreeRADIUS wiki for common issues
- Check Docker and PostgreSQL logs

## License

This setup uses FreeRADIUS (GPL v2) and PostgreSQL (PostgreSQL License).# freeradius-postgres-db
