# IT610 Midterm Project: Hardened Jellyfin Container

A **security-hardened** Jellyfin Docker container that addresses security weaknesses in the official Jellyfin Docker image, with optional NVIDIA GPU acceleration.

## Project Rationale

The official Jellyfin Docker container runs as root by default and lacks proper security isolation. This project implements Systems Administration security best practices while maintaining full Jellyfin functionality.

## Security Hardening Features

1. **Non-root user execution** - Container runs as unprivileged `jellyfin` user (UID/GID 1000) instead of root
2. **Read-only media mount** - Media library mounted read-only to prevent modification or tampering
3. **Separated cache volumes** - Config, cache, transcode, and metadata isolated for security and performance
4. **Minimal attack surface** - Only essential packages installed beyond base image
5. **Proper file permissions** - All directories have appropriate ownership and permissions set at build time
6. **Configurable UID/GID** - User namespace mapping configurable to match host user permissions

## Additional Features

- **Comprehensive codec support** - H.264, HEVC/H.265, AV1, VP9, HDR10+, Dolby Vision, and subtitle rendering
- **Optional NVIDIA GPU acceleration** - Hardware transcoding for systems with NVIDIA GPUs (not required)
- **Cross-platform compatibility** - Runs on Linux, macOS, and Windows

## Prerequisites

### Required
- Docker Desktop with Docker Compose (v2.0 or newer)

### Optional (for GPU acceleration only)
- NVIDIA GPU (Maxwell architecture or newer)
- NVIDIA drivers (v522.25 or newer)
- NVIDIA Container Toolkit

**Note**: GPU support is completely optional. The container runs perfectly fine with CPU-only transcoding.

## Quick Start

```bash
# Build the hardened image
docker compose build

# Start container (works on all systems)
docker compose --profile cpu up -d

# Access Jellyfin
open http://localhost:8920
```

### Configuration

1. **Set your media path** (choose one):
   - Create `.env` file: `MEDIA_PATH=/path/to/your/media`
   - Set environment variable: `export MEDIA_PATH=/path/to/your/media`
   - Or use the default `./media` directory

2. **Adjust user permissions** (optional):
   - Edit `JELLYFIN_UID` and `JELLYFIN_GID` in `docker-compose.yml` to match your host UID/GID
   - Default: 1000:1000

3. **Access web interface** at `http://localhost:8920` and complete setup wizard

## Security Validation

Verify the security hardening is working:

```bash
# Verify container is NOT running as root
docker exec jellyfin-hardened whoami
# Expected: jellyfin

# Verify media is read-only
docker exec jellyfin-hardened touch /media/test.txt
# Expected: "Read-only file system" error

# Check file ownership
docker exec jellyfin-hardened ls -la /config /cache /transcode
# All should be owned by jellyfin:jellyfin (1000:1000)
```

## Volume Structure

| Volume | Purpose |
|--------|---------|
| `/config` | Jellyfin configuration and database |
| `/cache` | General cache data |
| `/transcode` | Transcoding temporary files |
| `/metadata` | Media metadata cache |
| `/media` | Media library (read-only) |

## Optional: GPU Acceleration

If you have an NVIDIA GPU and want hardware-accelerated transcoding:

```bash
# Start with GPU support (requires NVIDIA Container Toolkit)
docker compose --profile gpu up -d

# Verify GPU access
docker exec jellyfin-hardened nvidia-smi
```

**Jellyfin GPU setup**:
1. Dashboard > Playback > Transcoding
2. Set Hardware Acceleration to "NVIDIA NVENC"
3. Enable desired codecs

---

## Appendix: Supported Codecs

### Video
- H.264/AVC, H.265/HEVC, AV1, VP9, Theora

### Audio
- AAC, MP3, Opus, Vorbis

### HDR & Advanced
- HDR10/HDR10+, Dolby Vision passthrough, tone mapping

### Subtitles
- ASS/SSA, SRT, VTT with burn-in support (libass, FreeType)
- CJK font support (Noto CJK)

### Container Formats
- MKV, MP4, WebM, AVI, and standard media containers
