#!/usr/bin/env bash
# Railway entrypoint for Marzban-node.
# Railway injects $PORT (and other vars). We set sane defaults for local runs
# and ensure the runtime state directory exists and is writable.

set -euo pipefail

# --- Railway / runtime environment -------------------------------------------
export PORT="${PORT:-62050}"
export SERVICE_HOST="${SERVICE_HOST:-0.0.0.0}"

# Default to the REST protocol over plain HTTP. Railway terminates TLS at the
# edge and reaches this node over its private network, so in-container TLS
# (which also requires a client cert Railway cannot provide) is off by default.
export SERVICE_PROTOCOL="${SERVICE_PROTOCOL:-rest}"
export SERVICE_TLS="${SERVICE_TLS:-false}"

# Xray-core binary/asset locations (installed by the Dockerfile into the image).
export XRAY_EXECUTABLE_PATH="${XRAY_EXECUTABLE_PATH:-/usr/local/bin/xray}"
export XRAY_ASSETS_PATH="${XRAY_ASSETS_PATH:-/usr/local/share/xray}"

# Certificate / state directory. Use a writable, non-ephemeral-safe location.
# Railway's filesystem is ephemeral per deploy, which is fine: certificates are
# regenerated at startup when missing (see main.py generate_ssl_files()).
SSL_DIR="${SSL_DIR:-/var/lib/marzban-node}"
mkdir -p "$SSL_DIR"
export SSL_CERT_FILE="${SSL_CERT_FILE:-$SSL_DIR/ssl_cert.pem}"
export SSL_KEY_FILE="${SSL_KEY_FILE:-$SSL_DIR/ssl_key.pem}"

echo "[marzban-node] starting with:"
echo "  SERVICE_PROTOCOL = ${SERVICE_PROTOCOL}"
echo "  SERVICE_TLS      = ${SERVICE_TLS}"
echo "  listen           = ${SERVICE_HOST}:${PORT}"
echo "  xray binary      = ${XRAY_EXECUTABLE_PATH}"
echo "  xray assets      = ${XRAY_ASSETS_PATH}"

# Replace the shell with the node process so signals (SIGTERM from Railway)
# are delivered directly to Python and handled for a clean shutdown.
exec python main.py
