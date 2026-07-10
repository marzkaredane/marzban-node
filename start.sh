#!/usr/bin/env bash

set -euo pipefail

export PORT="${PORT:-8080}"

export SERVICE_HOST="${SERVICE_HOST:-0.0.0.0}"
export SERVICE_PROTOCOL="${SERVICE_PROTOCOL:-rest}"
export SERVICE_TLS="${SERVICE_TLS:-true}"

export XRAY_EXECUTABLE_PATH="${XRAY_EXECUTABLE_PATH:-/usr/local/bin/xray}"
export XRAY_ASSETS_PATH="${XRAY_ASSETS_PATH:-/usr/local/share/xray}"


export SSL_DIR="${SSL_DIR:-/var/lib/marzban-node}"

mkdir -p "$SSL_DIR"


export SSL_CERT_FILE="${SSL_CERT_FILE:-$SSL_DIR/ssl_cert.pem}"
export SSL_KEY_FILE="${SSL_KEY_FILE:-$SSL_DIR/ssl_key.pem}"
export SSL_CLIENT_CERT_FILE="${SSL_CLIENT_CERT_FILE:-$SSL_DIR/ssl_client_cert.pem}"


# Decode client certificate from Railway variable
if [ -n "${SSL_CLIENT_CERT_B64:-}" ]; then
    echo "$SSL_CLIENT_CERT_B64" | base64 -d > "$SSL_CLIENT_CERT_FILE"
    chmod 644 "$SSL_CLIENT_CERT_FILE"
    echo "[marzban-node] SSL client certificate created"
fi


# Generate server TLS certificate
if [ ! -f "$SSL_CERT_FILE" ] || [ ! -f "$SSL_KEY_FILE" ]; then

    echo "[marzban-node] generating server certificate..."

    openssl req \
    -x509 \
    -newkey rsa:2048 \
    -nodes \
    -keyout "$SSL_KEY_FILE" \
    -out "$SSL_CERT_FILE" \
    -days 3650 \
    -subj "/CN=marzban-node"

fi


chmod 644 "$SSL_DIR"/*.pem || true


echo "[marzban-node] starting with:"
echo " SERVICE_PROTOCOL=$SERVICE_PROTOCOL"
echo " SERVICE_TLS=$SERVICE_TLS"
echo " listen=$SERVICE_HOST:$PORT"
echo " SSL_CERT_FILE=$SSL_CERT_FILE"
echo " SSL_KEY_FILE=$SSL_KEY_FILE"
echo " SSL_CLIENT_CERT_FILE=$SSL_CLIENT_CERT_FILE"


exec python main.py
