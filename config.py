import os

from decouple import config
from dotenv import load_dotenv

load_dotenv()

# Railway injects the public port in the $PORT environment variable.
# Never hardcode the listen port — honor $PORT first, then SERVICE_PORT,
# and only fall back to the original default when neither is set.
_port_raw = os.environ.get("PORT") or config("SERVICE_PORT", default="")
SERVICE_PORT = int(_port_raw) if _port_raw else 62050
SERVICE_HOST = config("SERVICE_HOST", default="0.0.0.0")

XRAY_API_HOST = config("XRAY_API_HOST", default="0.0.0.0")
XRAY_API_PORT = config('XRAY_API_PORT', cast=int, default=62051)
XRAY_EXECUTABLE_PATH = config("XRAY_EXECUTABLE_PATH", default="/usr/local/bin/xray")
XRAY_ASSETS_PATH = config("XRAY_ASSETS_PATH", default="/usr/local/share/xray")

# TLS for the node REST/rpyc service.
# On Railway the node sits behind the platform's TLS-terminating proxy and is
# reached over the private network, so terminating TLS inside the container is
# unnecessary (and requires a client cert which Railway cannot provide).
# Set SERVICE_TLS=true to enable TLS again (requires SSL_CERT_FILE/SSL_KEY_FILE).
SERVICE_TLS = config('SERVICE_TLS', cast=bool, default=False)

SSL_CERT_FILE = config("SSL_CERT_FILE", default="/var/lib/marzban-node/ssl_cert.pem")
SSL_KEY_FILE = config("SSL_KEY_FILE", default="/var/lib/marzban-node/ssl_key.pem")
SSL_CLIENT_CERT_FILE = config("SSL_CLIENT_CERT_FILE", default="")

DEBUG = config("DEBUG", cast=bool, default=False)

SERVICE_PROTOCOL = config('SERVICE_PROTOCOL', cast=str, default='rest')

INBOUNDS = config("INBOUNDS", cast=lambda v: [x.strip() for x in v.split(',')] if v else [], default="")
