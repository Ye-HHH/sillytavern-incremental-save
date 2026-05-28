#!/bin/bash
# ============================================================
# SillyTavern Incremental Save + Image Proxy + Token Fast
# Adapted from ransxd/sillytavern-incremental-save for ST 1.18.0
# ============================================================
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATCHED_DIR="$SCRIPT_DIR/patched-files"

if [ "$1" = "--docker" ]; then
    CONTAINER="${2:-sillytavern}"
    info "Backing up original files from container '$CONTAINER'..."
    BACKUP_DIR="$SCRIPT_DIR/backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    docker cp "$CONTAINER:/home/node/app/src/endpoints/chats.js"          "$BACKUP_DIR/"
    docker cp "$CONTAINER:/home/node/app/public/script.js"                "$BACKUP_DIR/"
    docker cp "$CONTAINER:/home/node/app/public/scripts/group-chats.js"   "$BACKUP_DIR/"
    docker cp "$CONTAINER:/home/node/app/public/scripts/chats.js"         "$BACKUP_DIR/"
    docker cp "$CONTAINER:/home/node/app/src/server-startup.js"           "$BACKUP_DIR/"
    docker cp "$CONTAINER:/home/node/app/public/scripts/tokenizers.js"   "$BACKUP_DIR/"
    info "Backups saved to $BACKUP_DIR"

    info "Installing patched files..."
    docker cp "$PATCHED_DIR/src_endpoints_chats.js"           "$CONTAINER:/home/node/app/src/endpoints/chats.js"
    docker cp "$PATCHED_DIR/src_endpoints_image-proxy.js"     "$CONTAINER:/home/node/app/src/endpoints/image-proxy.js"
    docker cp "$PATCHED_DIR/src_server-startup.js"            "$CONTAINER:/home/node/app/src/server-startup.js"
    docker cp "$PATCHED_DIR/public_script.js"                 "$CONTAINER:/home/node/app/public/script.js"
    docker cp "$PATCHED_DIR/public_scripts_group-chats.js"    "$CONTAINER:/home/node/app/public/scripts/group-chats.js"
    docker cp "$PATCHED_DIR/public_scripts_chats.js"          "$CONTAINER:/home/node/app/public/scripts/chats.js"
    docker cp "$PATCHED_DIR/public_scripts_tokenizers.js"     "$CONTAINER:/home/node/app/public/scripts/tokenizers.js"

    info "Restarting container..."
    docker restart "$CONTAINER"
    sleep 5
    info "Done! Incremental save + image proxy + token fast estimation installed."

elif [ "$1" = "--local" ]; then
    ST_DIR="${2:-.}"
    [ ! -f "$ST_DIR/server.js" ] && error "'$ST_DIR' does not look like a SillyTavern installation."

    info "Backing up original files..."
    BACKUP_DIR="$SCRIPT_DIR/backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    cp "$ST_DIR/src/endpoints/chats.js"          "$BACKUP_DIR/"
    cp "$ST_DIR/src/server-startup.js"            "$BACKUP_DIR/"
    cp "$ST_DIR/public/script.js"                 "$BACKUP_DIR/"
    cp "$ST_DIR/public/scripts/group-chats.js"    "$BACKUP_DIR/"
    cp "$ST_DIR/public/scripts/chats.js"          "$BACKUP_DIR/"
    cp "$ST_DIR/public/scripts/tokenizers.js"     "$BACKUP_DIR/"

    info "Installing patched files..."
    cp "$PATCHED_DIR/src_endpoints_chats.js"           "$ST_DIR/src/endpoints/chats.js"
    cp "$PATCHED_DIR/src_endpoints_image-proxy.js"     "$ST_DIR/src/endpoints/image-proxy.js"
    cp "$PATCHED_DIR/src_server-startup.js"            "$ST_DIR/src/server-startup.js"
    cp "$PATCHED_DIR/public_script.js"                 "$ST_DIR/public/script.js"
    cp "$PATCHED_DIR/public_scripts_group-chats.js"    "$ST_DIR/public/scripts/group-chats.js"
    cp "$PATCHED_DIR/public_scripts_chats.js"          "$ST_DIR/public/scripts/chats.js"
    cp "$PATCHED_DIR/public_scripts_tokenizers.js"     "$ST_DIR/public/scripts/tokenizers.js"

    info "Done! Restart SillyTavern to activate."
else
    echo "Usage:"
    echo "  $0 --docker [container_name]   Install to Docker container"
    echo "  $0 --local  [sillytavern_dir]  Install to local installation"
fi
