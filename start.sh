#!/usr/bin/env bash
set -euo pipefail


# ==============================
# Environment
# ==============================

export PORT="${PORT:-8080}"

export SERVICE_HOST="${SERVICE_HOST:-0.0.0.0}"

export SERVICE_PROTOCOL="${SERVICE_PROTOCOL:-rest}"

export SERVICE_TLS="${SERVICE_TLS:-true}"


export XRAY_EXECUTABLE_PATH="${XRAY_EXECUTABLE_PATH:-/usr/local/bin/xray}"

export XRAY_ASSETS_PATH="${XRAY_ASSETS_PATH:-/usr/local/share/xray}"


SSL_DIR="${SSL_DIR:-/var/lib/marzban-node}"

mkdir -p "$SSL_DIR"


export SSL_CERT_FILE="$SSL_DIR/ssl_cert.pem"

export SSL_KEY_FILE="$SSL_DIR/ssl_key.pem"

export SSL_CLIENT_CERT_FILE="$SSL_DIR/ssl_client_cert.pem"



# ==============================
# Copy Marzban Main Client Cert
# ==============================

if [ -f "/code/ssl_client_cert.pem" ]; then

    echo "[marzban-node] copying client certificate"

    cp /code/ssl_client_cert.pem \
    "$SSL_CLIENT_CERT_FILE"

    chmod 644 "$SSL_CLIENT_CERT_FILE"

else

    echo "[ERROR] /code/ssl_client_cert.pem not found"

    exit 1

fi



# ==============================
# Generate node TLS certificate
# ==============================

if [ ! -f "$SSL_CERT_FILE" ] || [ ! -f "$SSL_KEY_FILE" ]; then


    echo "[marzban-node] generating TLS certificate..."


    openssl req \
    -x509 \
    -newkey rsa:2048 \
    -nodes \
    -days 3650 \
    -keyout "$SSL_KEY_FILE" \
    -out "$SSL_CERT_FILE" \
    -subj "/CN=marzban-node"


    chmod 644 "$SSL_CERT_FILE" "$SSL_KEY_FILE"


    echo "[marzban-node] TLS certificate created"

fi



# ==============================
# Check
# ==============================

if [ ! -s "$SSL_CLIENT_CERT_FILE" ]; then

    echo "[ERROR] client certificate empty"

    exit 1

fi



echo "[marzban-node] starting with:"
echo " SERVICE_PROTOCOL=$SERVICE_PROTOCOL"
echo " SERVICE_TLS=$SERVICE_TLS"
echo " listen=$SERVICE_HOST:$PORT"
echo " SSL_CERT_FILE=$SSL_CERT_FILE"
echo " SSL_KEY_FILE=$SSL_KEY_FILE"
echo " SSL_CLIENT_CERT_FILE=$SSL_CLIENT_CERT_FILE"



exec python main.py
