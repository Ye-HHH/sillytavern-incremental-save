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
    # ---- Detect docker-compose directory ----
    COMPOSE_DIR="${2:-.}"
    if [ ! -f "$COMPOSE_DIR/docker-compose.yml" ] && [ ! -f "$COMPOSE_DIR/docker-compose.yaml" ]; then
        # Try common locations
        for try in /opt/sillytavern ~/sillytavern ~/SillyTavern .; do
            [ -f "$try/docker-compose.yml" ] && COMPOSE_DIR="$try" && break
            [ -f "$try/docker-compose.yaml" ] && COMPOSE_DIR="$try" && break
        done
    fi
    YML="$COMPOSE_DIR/docker-compose.yml"
    [ -f "$YML" ] || YML="$COMPOSE_DIR/docker-compose.yaml"
    [ -f "$YML" ] || error "docker-compose.yml not found. Usage: $0 --docker /path/to/docker-compose/dir"

    info "Docker compose directory: $COMPOSE_DIR"

    # ---- Copy patched files to host ----
    PATCHED_HOST="$COMPOSE_DIR/patched"
    mkdir -p "$PATCHED_HOST"
    cp "$PATCHED_DIR/public_script.js"              "$PATCHED_HOST/script.js"
    cp "$PATCHED_DIR/src_endpoints_chats.js"         "$PATCHED_HOST/chats.js"
    cp "$PATCHED_DIR/src_endpoints_image-proxy.js"   "$PATCHED_HOST/image-proxy.js"
    cp "$PATCHED_DIR/src_server-startup.js"          "$PATCHED_HOST/server-startup.js"
    cp "$PATCHED_DIR/public_scripts_chats.js"        "$PATCHED_HOST/chats-client.js"
    cp "$PATCHED_DIR/public_scripts_group-chats.js"  "$PATCHED_HOST/group-chats.js"
    cp "$PATCHED_DIR/public_scripts_tokenizers.js"   "$PATCHED_HOST/tokenizers.js"
    info "Patched files copied to $PATCHED_HOST/"

    # ---- Backup docker-compose.yml ----
    cp "$YML" "$YML.bak.$(date +%Y%m%d_%H%M%S)"
    info "docker-compose.yml backed up"

    # ---- Check if bind mounts already exist ----
    if grep -q 'patched/script.js' "$YML" 2>/dev/null; then
        info "Bind mounts already present in docker-compose.yml, skipping."
    else
        # Insert bind mounts before the last 'volumes:' entry's last line
        # Simpler: just append mount instructions and let user verify
        info "Adding bind mounts to docker-compose.yml..."
        MOUNTS='
      - ./patched/script.js:/home/node/app/public/script.js
      - ./patched/chats.js:/home/node/app/src/endpoints/chats.js
      - ./patched/image-proxy.js:/home/node/app/src/endpoints/image-proxy.js
      - ./patched/server-startup.js:/home/node/app/src/server-startup.js
      - ./patched/chats-client.js:/home/node/app/public/scripts/chats.js
      - ./patched/group-chats.js:/home/node/app/public/scripts/group-chats.js
      - ./patched/tokenizers.js:/home/node/app/public/scripts/tokenizers.js'
        # Insert after 'volumes:' line's last entry
        sed -i "/- \.\/data:\/home\/node\/app\/data/a\\$MOUNTS" "$YML"
        info "Bind mounts added"
    fi

    # ---- Recreate container ----
    info "Rebuilding container with bind mounts..."
    cd "$COMPOSE_DIR"
    docker compose down 2>/dev/null || true
    docker compose up -d
    sleep 5
    info "Done! Incremental save installed persistently."

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
    echo "  $0 --docker [compose_dir]   Install to Docker setup (persistent)"
    echo "  $0 --local  [st_dir]        Install to local installation"
fi
