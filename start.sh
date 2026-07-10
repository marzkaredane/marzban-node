#!/usr/bin/env bash

set -euo pipefail


# --- Railway / runtime environment -------------------------------------------

export PORT="${PORT:-8080}"
export SERVICE_HOST="${SERVICE_HOST:-0.0.0.0}"

export SERVICE_PROTOCOL="${SERVICE_PROTOCOL:-rest}"
export SERVICE_TLS="${SERVICE_TLS:-true}"


# Xray locations
export XRAY_EXECUTABLE_PATH="${XRAY_EXECUTABLE_PATH:-/usr/local/bin/xray}"
export XRAY_ASSETS_PATH="${XRAY_ASSETS_PATH:-/usr/local/share/xray}"


# SSL directory
export SSL_DIR="${SSL_DIR:-/var/lib/marzban-node}"

mkdir -p "$SSL_DIR"


export SSL_CERT_FILE="${SSL_CERT_FILE:-$SSL_DIR/ssl_cert.pem}"
export SSL_KEY_FILE="${SSL_KEY_FILE:-$SSL_DIR/ssl_key.pem}"
export SSL_CLIENT_CERT_FILE="${SSL_CLIENT_CERT_FILE:-$SSL_DIR/ssl_client_cert.pem}"


# Create client certificate from Railway variable
if [ -n "${SSL_CLIENT_CERT:-}" ]; then
    echo "$SSL_CLIENT_CERT" > "$SSL_CLIENT_CERT_FILE"
    chmod 644 "$SSL_CLIENT_CERT_FILE"
    echo "[marzban-node] SSL client certificate created"
else
    echo "[marzban-node] WARNING: SSL_CLIENT_CERT variable is empty"
fi


# Generate server certificate if missing
if [ ! -f "$SSL_CERT_FILE" ] || [ ! -f "$SSL_KEY_FILE" ]; then

    echo "[marzban-node] generating server certificate..."

    openssl req -x509 \
        -newkey rsa:2048 \
        -nodes \
        -keyout "$SSL_KEY_FILE" \
        -out "$SSL_CERT_FILE" \
        -days 3650 \
        -subj "/CN=marzban-node"

fi


chmod 644 "$SSL_DIR"/*.pem || true


echo "[marzban-node] starting with:"
echo "  SERVICE_PROTOCOL = ${SERVICE_PROTOCOL}"
echo "  SERVICE_TLS      = ${SERVICE_TLS}"
echo "  listen           = ${SERVICE_HOST}:${PORT}"
echo "  ssl cert         = ${SSL_CERT_FILE}"
echo "  ssl key          = ${SSL_KEY_FILE}"
echo "  ssl client cert  = ${SSL_CLIENT_CERT_FILE}"
echo "  xray binary      = ${XRAY_EXECUTABLE_PATH}"
echo "  xray assets      = ${XRAY_ASSETS_PATH}"


exec python main.py
