# Security Checklist

Before deploying to production, ensure you've completed these security tasks:

## Authentication & Secrets

- [ ] **Change all default passwords** in `.env`:
  - `POSTGRES_PASSWORD`
  - `DB_PASSWORD`
- [ ] **Update RADIUS shared secrets** in `raddb/clients.conf`

  - Change `secret = testing123` to strong, unique secrets
  - Use different secrets for each NAS client

- [ ] **Review user passwords** in database (`radcheck` table)
  - Remove or change test users (bob, alice, guest1)
  - Use strong password policies

## Network Security

- [ ] **Restrict Docker network access**

  - Update `clients.conf` to only allow specific NAS IP addresses
  - Remove overly broad network ranges (e.g., 172.28.0.0/16)

- [ ] **Enable message authenticator** for production clients

  - Set `require_message_authenticator = yes` in `clients.conf`

- [ ] **Firewall configuration**
  - Only expose RADIUS ports (1812, 1813) to trusted networks
  - Protect PostgreSQL port (5432) - should not be publicly accessible

## Database Security

- [ ] **Database access controls**

  - Create separate database users with minimum required privileges
  - Review PostgreSQL `pg_hba.conf` if customizing

- [ ] **Enable SSL/TLS** for database connections (production)
  - Configure PostgreSQL to require SSL
  - Update FreeRADIUS SQL module to use SSL

## File Permissions

- [ ] **Configuration file permissions**
  - Ensure `.env` is not committed to git (check `.gitignore`)
  - Verify config files are not world-readable in production

## Monitoring & Logging

- [ ] **Enable proper logging**

  - Configure log rotation
  - Set up monitoring for failed authentication attempts
  - Alert on suspicious activity

- [ ] **Health checks**
  - Verify health check endpoints are working
  - Set up external monitoring

## Updates & Maintenance

- [ ] **Keep images updated**

  - Regularly update base images (ubuntu:22.04, postgres:16-alpine)
  - Monitor security advisories for FreeRADIUS

- [ ] **Backup strategy**
  - Set up automated backups of PostgreSQL database
  - Test restore procedures

## Compliance

- [ ] **Review for compliance requirements**
  - GDPR, HIPAA, or other regulations
  - Log retention policies
  - Data encryption requirements

## Testing

- [ ] **Security testing**
  - Test with production-like configuration
  - Verify authentication works as expected
  - Test failure scenarios

---

## Quick Security Improvements

```bash
# Generate strong passwords
openssl rand -base64 32

# Generate strong shared secrets
openssl rand -hex 32

# Check for exposed secrets in git
git log -p | grep -i password
```

## Reporting Security Issues

If you discover a security vulnerability, please email [security@example.com] instead of using the issue tracker.
