# IT610 Final Project: Hardened Jellyfin Container with Reverse Proxy

A **security-hardened** Jellyfin Docker container with **Nginx reverse proxy** for SSL termination, demonstrating multi-container orchestration and defense-in-depth security practices.

## Project Evolution

- **Midterm**: Security-hardened Jellyfin container (non-root execution, read-only mounts)
- **Final**: Added Nginx reverse proxy for SSL/TLS, security headers, and network isolation

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Docker Host                                   │
│                                                                      │
│    Internet/Browser                                                  │
│          │                                                           │
│          ▼                                                           │
│    ┌─────────────────────────────────────────┐                      │
│    │  Ports 80/443 (exposed to host)         │                      │
│    └─────────────────────────────────────────┘                      │
│          │                                                           │
│          ▼                                                           │
│    ┌─────────────────────────────────────────┐                      │
│    │         Nginx Reverse Proxy             │                      │
│    │  • SSL/TLS termination (HTTPS)          │                      │
│    │  • Security headers injection           │                      │
│    │  • HTTP → HTTPS redirect                │                      │
│    │  • Hides backend server identity        │                      │
│    └─────────────────┬───────────────────────┘                      │
│                      │                                               │
│              ┌───────▼────────┐                                      │
│              │ jellyfin-net   │  (Internal Docker Network)           │
│              │ (isolated)     │                                      │
│              └───────┬────────┘                                      │
│                      │                                               │
│    ┌─────────────────▼───────────────────────┐                      │
│    │        Jellyfin (hardened)              │                      │
│    │  • Runs as non-root user                │                      │
│    │  • Read-only media mount                │                      │
│    │  • NOT exposed to host network          │                      │
│    │  • Only accessible through Nginx        │                      │
│    └─────────────────────────────────────────┘                      │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

**Key security improvement**: Jellyfin is no longer directly accessible from outside Docker. All traffic must pass through the Nginx reverse proxy first.

## Security Features

### Container Hardening (Midterm)
1. **Non-root user execution** - Container runs as unprivileged `jellyfin` user (UID/GID 1000)
2. **Read-only media mount** - Media library cannot be modified from within container
3. **Separated volumes** - Config, cache, transcode, and metadata isolated
4. **Minimal packages** - Only essential packages installed

### Network Security (Final)
5. **SSL/TLS encryption** - All traffic encrypted via HTTPS (TLS 1.2/1.3 only)
6. **Network isolation** - Jellyfin only accessible on internal Docker network
7. **Security headers** - X-Frame-Options, X-Content-Type-Options, XSS protection
8. **Server identity hidden** - Nginx version and Jellyfin identity not exposed
9. **HTTP redirect** - All HTTP traffic automatically redirected to HTTPS

## Prerequisites

### Required
- Docker Desktop with Docker Compose (v2.0+)
- OpenSSL (for generating SSL certificates)

### Optional (GPU acceleration)
- NVIDIA GPU + drivers + Container Toolkit

## Quick Start

### 1. Generate SSL Certificates

Self-signed certificates for local development:

```bash
cd nginx/ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout key.pem -out cert.pem -config openssl.cnf
```

### 2. Configure Media Path

Create a `.env` file in the project root:

```bash
echo "MEDIA_PATH=/path/to/your/media" > .env
```

### 3. Build and Run

```bash
# Build the hardened Jellyfin image
docker compose build

# Start all services (CPU profile)
docker compose --profile cpu up -d

# Or with GPU acceleration
docker compose --profile gpu up -d
```

### 4. Access Jellyfin

- **HTTPS**: https://localhost (recommended)
- **HTTP**: http://localhost (auto-redirects to HTTPS)

Your browser will warn about the self-signed certificate - this is expected. Click through the warning to proceed.

## Commands Reference

```bash
# Build
docker compose build

# Start (choose one)
docker compose --profile cpu up -d    # Without GPU
docker compose --profile gpu up -d    # With NVIDIA GPU

# Stop
docker compose --profile cpu down
docker compose --profile gpu down

# View logs
docker compose logs -f                # All services
docker compose logs -f nginx          # Nginx only
docker compose logs -f jellyfin       # Jellyfin only

# Restart Nginx (after config changes)
docker compose restart nginx
```

## Security Validation

### Verify Container Security

```bash
# Jellyfin running as non-root user
docker exec jellyfin-hardened whoami
# Expected: jellyfin

# Media is read-only
docker exec jellyfin-hardened touch /media/test.txt
# Expected: "Read-only file system" error

# Verify file ownership
docker exec jellyfin-hardened ls -la /config
# Expected: owned by jellyfin:jellyfin
```

### Verify Network Isolation

```bash
# Jellyfin should NOT be accessible on port 8096 from host
curl http://localhost:8096
# Expected: Connection refused

# Jellyfin IS accessible through Nginx
curl -k https://localhost
# Expected: Jellyfin response (HTML)
```

### Verify SSL/TLS

```bash
# Check SSL certificate
openssl s_client -connect localhost:443 -servername localhost </dev/null 2>/dev/null | openssl x509 -noout -subject -dates

# Check TLS version (should be 1.2 or 1.3)
curl -kv https://localhost 2>&1 | grep "SSL connection"
```

### Verify Security Headers

```bash
curl -kI https://localhost 2>/dev/null | grep -E "^(X-Frame|X-Content|X-XSS|Referrer)"
# Expected:
# X-Frame-Options: SAMEORIGIN
# X-Content-Type-Options: nosniff
# X-XSS-Protection: 1; mode=block
# Referrer-Policy: strict-origin-when-cross-origin
```

## File Structure

```
it610-midterm/
├── Dockerfile              # Hardened Jellyfin image
├── docker-compose.yml      # Multi-container orchestration
├── nginx/
│   ├── nginx.conf          # Reverse proxy configuration
│   └── ssl/
│       ├── openssl.cnf     # Certificate generation config
│       ├── cert.pem        # SSL certificate (generated, gitignored)
│       └── key.pem         # Private key (generated, gitignored)
├── .env                    # Local config (gitignored)
├── .gitignore
└── README.md
```

## Volume Structure

| Volume | Container Path | Purpose |
|--------|----------------|---------|
| jellyfin-config | /config | Jellyfin database and settings |
| jellyfin-cache | /cache | General cache |
| jellyfin-transcode | /transcode | Transcoding temp files |
| jellyfin-metadata | /metadata | Media metadata |
| (bind mount) | /media | Media library (read-only) |

## Port Mapping

| Host Port | Service | Purpose |
|-----------|---------|---------|
| 443 | Nginx | HTTPS (encrypted traffic) |
| 80 | Nginx | HTTP (redirects to HTTPS) |
| - | Jellyfin | Not exposed (internal only) |

## Optional: GPU Acceleration

```bash
# Start with GPU profile
docker compose --profile gpu up -d

# Verify GPU access
docker exec jellyfin-hardened nvidia-smi
```

Configure in Jellyfin: Dashboard → Playback → Transcoding → Set to "NVIDIA NVENC"

---

## Appendix: Nginx Security Headers Explained

| Header | Purpose |
|--------|---------|
| `X-Frame-Options: SAMEORIGIN` | Prevents clickjacking - blocks other sites from embedding Jellyfin in an iframe |
| `X-Content-Type-Options: nosniff` | Prevents MIME-type sniffing attacks |
| `X-XSS-Protection: 1; mode=block` | Enables browser's XSS filter |
| `Referrer-Policy` | Controls what URL info is sent to external sites |
| `server_tokens off` | Hides Nginx version from headers and error pages |

## Appendix: Supported Codecs

### Video
- H.264/AVC, H.265/HEVC, AV1, VP9, Theora

### Audio
- AAC, MP3, Opus, Vorbis

### HDR
- HDR10/HDR10+, Dolby Vision passthrough, tone mapping

### Subtitles
- ASS/SSA, SRT, VTT with burn-in support
