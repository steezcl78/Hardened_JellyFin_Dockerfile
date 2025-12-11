# IT610 Midterm Project: Hardened Jellyfin Container

A security-hardened, performance-optimized Jellyfin Docker container with NVIDIA GPU support.

## Features

1. **Non-root user execution** - Container runs as unprivileged `jellyfin` user (UID/GID 1000)
2. **NVIDIA GPU hardware acceleration** - Configured for NVENC/NVDEC transcoding
3. **Separated cache volumes** - Transcode and metadata caches isolated for performance
4. **Extra codecs** - Comprehensive codec and library support for home media

## Codec & Format Support

### Video Codecs
- **H.264/AVC** - libx264 (most compatible)
- **H.265/HEVC** - libx265 (4K, HDR content)
- **AV1** - libdav1d, libaom (next-gen, efficient)
- **VP9** - libvpx (YouTube, WebM)
- **Theora** - libtheora (legacy open format)

### Audio Codecs
- **AAC** - libfdk-aac (high quality)
- **MP3** - libmp3lame
- **Opus** - libopus (modern, efficient)
- **Vorbis** - libvorbis (OGG container)

### HDR & Advanced Features
- **HDR10/HDR10+** - via HEVC/AV1 support
- **Dolby Vision** - passthrough support
- **Tone mapping** - OpenCL for HDR to SDR conversion
- **Vulkan** - modern GPU acceleration pipeline

### Subtitles & Fonts
- **ASS/SSA** - styled subtitles via libass
- **SRT, VTT** - standard subtitle formats
- **CJK fonts** - Noto CJK for Asian language support
- **Burn-in** - FreeType, HarfBuzz, Fribidi

### Physical Media
- **BluRay** - libbluray for disc rips
- **DVD** - standard container support

### Image Formats (thumbnails, album art)
- WebP, JPEG, PNG

## Prerequisites

- Docker Desktop with Docker Compose
- NVIDIA GPU (Maxwell architecture or newer)
- NVIDIA drivers (v522.25 or newer)
- NVIDIA Container Toolkit installed on host

## Usage

### Build and Run

```bash
# Build the hardened image
docker compose build

# Start the container
docker compose up -d

# Verify GPU access
docker exec -it jellyfin-hardened nvidia-smi
```

### Configuration

1. Edit `docker-compose.yml` and update `/path/to/your/media` to your media location
2. Adjust `JELLYFIN_UID` and `JELLYFIN_GID` build args if needed to match your host user

### Jellyfin Setup

1. Access web interface at `http://localhost:8096`
2. Navigate to Dashboard > Playback > Transcoding
3. Set Hardware Acceleration to "NVIDIA NVENC"
4. Enable supported codecs

## Volume Structure

| Volume | Purpose |
|--------|---------|
| `/config` | Jellyfin configuration and database |
| `/cache` | General cache data |
| `/transcode` | Transcoding temporary files (benefits from fast storage) |
| `/metadata` | Media metadata cache |
| `/media` | Media library (read-only mount) |

## Security Hardening

- Runs as non-root user by default
- Media mounted read-only
- Minimal additional packages installed
- Proper file permissions set at build time
