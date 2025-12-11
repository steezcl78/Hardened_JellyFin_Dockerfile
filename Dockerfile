# IT610 Midterm Project: Hardened Jellyfin Container
# Base: Official Jellyfin image (Debian-based)

FROM jellyfin/jellyfin:latest

# ============================================
# 1. ADD EXTRA CODECS & MEDIA LIBRARIES
# ============================================
# Comprehensive codec support for home media server
# Covers: HEVC/H.265, AV1, VP9, H.264, HDR, Dolby Vision, subtitles, fonts
USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
    # VA-API drivers (hardware acceleration fallback)
    libva-drm2 \
    libva2 \
    mesa-va-drivers \
    # OpenCL support (tone mapping, HDR processing)
    ocl-icd-libopencl1 \
    # Vulkan support (modern GPU acceleration)
    libvulkan1 \
    mesa-vulkan-drivers \
    # Font rendering for subtitles (ASS/SSA, SRT, etc.)
    fontconfig \
    fonts-dejavu-core \
    fonts-liberation \
    fonts-noto-core \
    fonts-noto-cjk \
    # FreeType for subtitle burn-in
    libfreetype6 \
    libfribidi0 \
    libharfbuzz0b \
    # Subtitle support
    libass9 \
    # Additional media libraries
    libdrm2 \
    libopus0 \
    libvorbis0a \
    libvorbisenc2 \
    libtheora0 \
    libx264-dev \
    libx265-dev \
    libvpx-dev \
    libdav1d-dev \
    libaom3 \
    # BluRay/DVD support
    libbluray2 \
    # Image formats (album art, thumbnails)
    libwebp7 \
    libjpeg62-turbo \
    libpng16-16 \
    # Audio codecs
    libmp3lame0 \
    libopusenc0 \
    # OpenSSL for secure streams
    openssl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# ============================================
# 2. CREATE NON-ROOT USER
# ============================================
ARG JELLYFIN_UID=1000
ARG JELLYFIN_GID=1000

RUN groupadd -g ${JELLYFIN_GID} jellyfin || true \
    && useradd -u ${JELLYFIN_UID} -g ${JELLYFIN_GID} -m -s /bin/bash jellyfin || true

# ============================================
# 3. SET UP DIRECTORY STRUCTURE WITH PROPER PERMISSIONS
# ============================================
RUN mkdir -p /config /cache /transcode /metadata \
    && chown -R ${JELLYFIN_UID}:${JELLYFIN_GID} /config /cache /transcode /metadata \
    && chmod 755 /config /cache /transcode /metadata

# ============================================
# 4. NVIDIA GPU ENVIRONMENT VARIABLES
# ============================================
ENV NVIDIA_DRIVER_CAPABILITIES=all
ENV NVIDIA_VISIBLE_DEVICES=all

# ============================================
# 5. EXPOSE PORTS
# ============================================
EXPOSE 8096
EXPOSE 7359/udp

# ============================================
# 6. SWITCH TO NON-ROOT USER
# ============================================
USER jellyfin

# ============================================
# 7. VOLUME MOUNT POINTS (separated for performance)
# ============================================
VOLUME ["/config", "/cache", "/transcode", "/metadata", "/media"]

# Entry point inherited from base image
