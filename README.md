# itsUP Projects

Docker Compose stack definitions for itsUP infrastructure.

## Structure

**Infrastructure Config:**
- `traefik.yml` - Infrastructure-wide configuration (domain, plugins, middleware)

**Projects:**
Each project is a directory containing:
- `docker-compose.yml` - Standard Docker Compose (copy-paste from anywhere!)
- `traefik.yml` - Minimal routing configuration

## Adding a New Project

```bash
# 1. Create directory
mkdir my-app

# 2. Add standard docker-compose.yml
# (copy from Docker Hub, your existing setup, etc.)

# 3. Create traefik.yml for routing
cat > my-app/traefik.yml <<YAML
enabled: true
ingress:
  - service: web
    domain: my-app.example.com
    port: 3000
YAML

# 4. Reference secrets from secrets/ submodule
# In docker-compose.yml, use ${SECRET_VAR} syntax
```

## traefik.yml Schema

**Infrastructure (projects/traefik.yml):**
```yaml
domain_suffix: example.com

letsencrypt:
  email: ${LETSENCRYPT_EMAIL}      # From secrets
  staging: false

traefik:
  log_level: INFO
  dashboard_enabled: true
  dashboard_auth: ${TRAEFIK_ADMIN}  # From secrets

middleware:
  rate_limit:
    enabled: true
    average: 100
    burst: 50

plugins:
  crowdsec:
    enabled: true
    apikey: ${CROWDSEC_API_KEY}    # From secrets
```

**Project Routing (projects/{name}/traefik.yml):**
```yaml
enabled: true|false

ingress:
  - service: web              # Docker compose service name
    domain: app.example.com   # Domain for routing
    port: 3000                # Container port
    router: http|tcp|udp      # Default: http
    path_prefix: /api         # Optional: path-based routing
    hostport: 8080            # Optional: expose on host
    passthrough: true|false   # Optional: TLS passthrough
    tls_sans:                 # Optional: SAN certificate
      - alt1.example.com
      - alt2.example.com
```

## Examples

See existing projects for real-world examples.
