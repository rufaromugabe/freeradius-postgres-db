# REST API Integration

FreeRADIUS includes the `rlm_rest` module that enables integration with external REST APIs for authentication, authorization, and accounting.

## Configuration

The REST module is available at `raddb/mods-available/rest`. To enable it:

```bash
# Create symbolic link to enable the module
docker-compose exec freeradius ln -sf /etc/freeradius/3.0/mods-available/rest /etc/freeradius/3.0/mods-enabled/rest

# Restart FreeRADIUS
docker-compose restart freeradius
```

## Use Cases

### 1. External Authentication API

Authenticate users against your custom API:

**API Endpoint**: `POST /api/radius/authorize`

**Request**:

```json
{
  "username": "user@example.com",
  "password": "secret123"
}
```

**Response** (200 OK = Accept, 403 = Reject):

```json
{
  "result": "accept",
  "reply": {
    "Session-Timeout": 3600,
    "Reply-Message": "Welcome!"
  }
}
```

### 2. Accounting Integration

Send accounting data to your API:

**API Endpoint**: `POST /api/radius/accounting`

**Request**:

```json
{
  "username": "user@example.com",
  "session_id": "abc123",
  "status_type": "Start",
  "nas_ip": "192.168.1.1",
  "input_octets": "0",
  "output_octets": "0",
  "session_time": "0"
}
```

### 3. Post-Authentication Logging

Log authentication attempts:

**API Endpoint**: `POST /api/radius/post-auth`

**Request**:

```json
{
  "username": "user@example.com",
  "reply": "Access-Accept",
  "nas_ip": "192.168.1.1"
}
```

## Example REST API Server

Here's a simple Node.js/Express example:

```javascript
const express = require("express");
const app = express();

app.use(express.json());

// Authorization endpoint
app.post("/api/radius/authorize", (req, res) => {
  const { username, password } = req.body;

  // Your authentication logic here
  if (username === "testuser" && password === "testpass") {
    res.status(200).json({
      result: "accept",
      reply: {
        "Session-Timeout": 3600,
        "Reply-Message": "Welcome!",
      },
    });
  } else {
    res.status(403).json({
      result: "reject",
      reply: {
        "Reply-Message": "Invalid credentials",
      },
    });
  }
});

// Accounting endpoint
app.post("/api/radius/accounting", (req, res) => {
  console.log("Accounting data:", req.body);
  res.status(200).json({ result: "ok" });
});

// Post-auth endpoint
app.post("/api/radius/post-auth", (req, res) => {
  console.log("Auth attempt:", req.body);
  res.status(200).json({ result: "ok" });
});

app.listen(8080, () => {
  console.log("RADIUS REST API listening on port 8080");
});
```

## Configuration in FreeRADIUS

1. **Update `.env` file**:

```bash
REST_API_URL=http://your-api-server:8080/api/radius
```

2. **Enable REST module**:

```bash
# Copy to mods-enabled
cp raddb/mods-available/rest raddb/mods-enabled/rest

# Or create symlink
ln -s ../mods-available/rest raddb/mods-enabled/rest
```

3. **Update `sites-available/default`** to use REST:

Add to the `authorize` section:

```
authorize {
    # ... existing modules ...

    # Try REST API first
    rest {
        ok = return
        fail = 1
        notfound = 1
    }

    # Fall back to SQL if REST fails
    sql

    # ... other modules ...
}
```

4. **Restart FreeRADIUS**:

```bash
docker-compose restart freeradius
```

## Testing

```bash
# Test authentication (will call your REST API)
radtest testuser testpass localhost 0 testing123
```

## Security Considerations

### HTTPS/TLS

For production, always use HTTPS:

```
rest {
    connect_uri = "https://api.example.com/radius"

    tls {
        ca_file = "${certdir}/ca.pem"
        certificate_file = "${certdir}/client.pem"
        private_key_file = "${certdir}/client.key"
        check_cert = yes
        check_cert_cn = yes
    }
}
```

### Authentication

Add API authentication:

**Bearer Token**:

```
rest {
    authorize {
        uri = "${..connect_uri}/authorize"
        header = "Authorization: Bearer ${env:API_TOKEN}"
    }
}
```

**Basic Auth**:

```
rest {
    authorize {
        uri = "${..connect_uri}/authorize"
        auth = 'basic'
        username = "${env:API_USER}"
        password = "${env:API_PASSWORD}"
    }
}
```

### Rate Limiting

Implement rate limiting in your API to prevent abuse.

### IP Whitelisting

Restrict API access to known FreeRADIUS server IPs.

## Advanced Features

### Custom Headers

```
rest {
    authorize {
        header = "X-API-Key: your-api-key"
        header = "X-Request-ID: %{Acct-Session-Id}"
    }
}
```

### Response Mapping

Map API response fields to RADIUS attributes:

```json
{
  "username": "user@example.com",
  "vlan": "100",
  "session_timeout": 3600
}
```

Configure FreeRADIUS to map these to RADIUS attributes.

### Error Handling

Handle API failures gracefully:

```
rest {
    authorize {
        # If API fails, fall back to SQL
        fail = 1
        invalid = 1
        notfound = 1
    }
}
```

## Monitoring

Monitor REST API calls in FreeRADIUS logs:

```bash
docker-compose logs -f freeradius | grep rest
```

## Example: OAuth2/JWT Integration

For OAuth2/JWT tokens:

```
rest {
    authorize {
        uri = "${..connect_uri}/validate"
        method = 'post'
        body = 'json'
        data = '{
            "token": "%{User-Password}",
            "username": "%{User-Name}"
        }'
    }
}
```

## Troubleshooting

**Connection refused**:

- Check if API server is accessible from FreeRADIUS container
- Verify network connectivity: `docker-compose exec freeradius curl http://your-api`

**SSL certificate errors**:

- Add CA certificate to FreeRADIUS
- Or disable cert verification (not recommended for production)

**Module not found**:

- Check if `freeradius-rest` package is installed
- Install if needed: `apt-get install freeradius-rest`

## Resources

- [FreeRADIUS REST Module Documentation](https://networkradius.com/doc/current/raddb/mods-available/rest.html)
- [REST API Integration Guide](https://wiki.freeradius.org/modules/Rlm_rest)
