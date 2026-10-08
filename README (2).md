# Nginx Reverse Proxy + SSL Configuration — Muslim Corner

Configured Nginx as a reverse proxy with SSL/TLS for a real Next.js production application (Muslim Corner — muslimcorner.org), running it locally to practice and verify a full production-style deployment setup end to end.

## What This Demonstrates

- Setting up Nginx as a web server and reverse proxy
- Generating and configuring self-signed SSL/TLS certificates
- Enforcing HTTPS via HTTP → HTTPS redirection
- Serving a real Next.js application through Nginx rather than a toy example
- Debugging real deployment issues: permission errors, stale package state, network connectivity, and misconfigured upstreams

## Setup Overview

Muslim Corner (a live Next.js content site normally hosted on Vercel) was built locally and run with `npm start` on port 3000. Nginx was configured separately to sit in front of it, handling SSL termination and reverse-proxying all traffic to the app.

```
Browser (https://localhost)
        │
        ▼
   Nginx (port 443, SSL)
        │  proxy_pass
        ▼
Next.js app (port 3000)
```

## Nginx Configuration

**HTTPS + reverse proxy:**
```nginx
server {
    listen 443 ssl;
    server_name localhost;
    ssl_certificate /etc/nginx/ssl/self.cert;
    ssl_certificate_key /etc/nginx/ssl/self.key;

    location / {
        proxy_pass http://localhost:3000;
    }
}
```

**Forcing HTTPS (HTTP → HTTPS redirect):**
```nginx
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;
    return 301 https://$host$request_uri;
}
```

## Certificate Generation

```bash
sudo mkdir -p /etc/nginx/ssl
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/nginx/ssl/self.key \
  -out /etc/nginx/ssl/self.cert
```

Self-signed certificates were used here since this was a local practice deployment. In a real production deployment, this step would be replaced with Certbot / Let's Encrypt to obtain a certificate trusted by browsers by default, with automatic renewal.

## Verification

```bash
sudo nginx -t                    # validate config before reloading
sudo systemctl reload nginx
curl -k https://localhost        # returns the app's HTML
curl -I http://localhost         # returns 301 → https://localhost/
```

## Issues Debugged Along the Way

- **`403 Forbidden` despite correct file permissions**: the target file itself was world-readable, but a parent directory in the path had restrictive permissions (`750`), blocking Nginx's `www-data` user from traversing into it. Fixed by granting execute/traverse permission on the parent directory, not just the file.
- **`dpkg was interrupted`**: caused by an earlier malformed `apt` command; resolved with `sudo dpkg --configure -a` before retrying the install.
- **WSL network failure (`NO-CARRIER`)**: the network adapter dropped inside the VM, blocking all connectivity, including DNS resolution. Diagnosed via `ip addr show`, resolved with a full VM restart.
- **`502 Bad Gateway`**: occurred whenever the upstream Next.js process wasn't actually running — a reminder that Nginx reverse-proxies to a live process, not a static target; the app has to be kept running independently of Nginx.
- **Config syntax typo (`ssl_certificficate`)**: caught by `nginx -t` before reload, which is why validating config before every reload is standard practice rather than optional.

## Key Takeaway

Nginx configuration itself is a small part of the work — most of the real learning came from diagnosing why a correctly-written config still didn't serve traffic (permissions, process state, network layer), which mirrors the kind of troubleshooting expected in an actual DevOps/deployment role.
