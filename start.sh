#!/usr/bin/env bash

set -euo pipefail

# -----------------------------
# Runtime / Railway
# -----------------------------

export PORT="${PORT:-8080}"

export SERVICE_HOST="${SERVICE_HOST:-0.0.0.0}"
export SERVICE_PROTOCOL="${SERVICE_PROTOCOL:-rest}"
export SERVICE_TLS="${SERVICE_TLS:-true}"


# -----------------------------
# Xray
# -----------------------------

export XRAY_EXECUTABLE_PATH="${XRAY_EXECUTABLE_PATH:-/usr/local/bin/xray}"
export XRAY_ASSETS_PATH="${XRAY_ASSETS_PATH:-/usr/local/share/xray}"


# -----------------------------
# SSL
# -----------------------------

export SSL_DIR="${SSL_DIR:-/var/lib/marzban-node}"

mkdir -p "$SSL_DIR"

export SSL_CERT_FILE="${SSL_CERT_FILE:-$SSL_DIR/ssl_cert.pem}"
export SSL_KEY_FILE="${SSL_KEY_FILE:-$SSL_DIR/ssl_key.pem}"


# -----------------------------
# Generate Node Certificate
# -----------------------------

if [ ! -f "$SSL_CERT_FILE" ] || [ ! -f "$SSL_KEY_FILE" ]; then

    echo "[marzban-node] generating TLS certificate..."

    cat > /tmp/san.cnf <<EOF
[req]
distinguished_name=req_distinguished_name
x509_extensions=v3_req
prompt=no

[req_distinguished_name]
CN=marzban-node

[v3_req]
subjectAltName=@alt_names

[alt_names]
DNS.1=marzban-node.railway.internal
DNS.2=localhost
IP.1=127.0.0.1
EOF


    openssl req \
        -x509 \
        -newkey rsa:2048 \
        -nodes \
        -days 3650 \
        -keyout "$SSL_KEY_FILE" \
        -out "$SSL_CERT_FILE" \
        -config /tmp/san.cnf \
        -extensions v3_req


    chmod 644 "$SSL_CERT_FILE" "$SSL_KEY_FILE"

    echo "[marzban-node] TLS certificate created"

fi


# -----------------------------
# Debug info
# -----------------------------

echo "[marzban-node] starting with:"
echo " SERVICE_PROTOCOL = $SERVICE_PROTOCOL"
echo " SERVICE_TLS      = $SERVICE_TLS"
echo " listen           = $SERVICE_HOST:$PORT"
echo " ssl cert         = $SSL_CERT_FILE"
echo " ssl key          = $SSL_KEY_FILE"
echo " xray binary      = $XRAY_EXECUTABLE_PATH"
echo " xray assets      = $XRAY_ASSETS_PATH"


# -----------------------------
# Start Marzban Node
# -----------------------------

exec python main.py
