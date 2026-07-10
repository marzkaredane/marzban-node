# ---- Stage 1: build dependencies ----------------------------------------------
FROM python:3.12-slim AS build

ENV PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /code

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential curl unzip ca-certificates \
    && rm -rf /var/lib/apt/lists/*

ARG XRAY_VERSION=1.8.23

RUN set -eux; \
    arch=64; \
    url="https://github.com/XTLS/Xray-core/releases/download/v${XRAY_VERSION}/Xray-linux-${arch}.zip"; \
    curl -fSL "$url" -o /tmp/xray.zip \
    && unzip -o /tmp/xray.zip -d /tmp/xray_extract \
    && mkdir -p /usr/local/bin /usr/local/share/xray \
    && install -m 0755 /tmp/xray_extract/xray /usr/local/bin/xray \
    && cp -r /tmp/xray_extract/* /usr/local/share/xray/ \
    && chmod 0755 /usr/local/share/xray/xray \
    && rm -rf /tmp/xray.zip /tmp/xray_extract \
    && /usr/local/bin/xray version

COPY ./requirements.txt /code/

RUN python3 -m pip install --upgrade pip setuptools wheel \
    && pip install --no-cache-dir -r /code/requirements.txt


# ---- Stage 2: runtime image ---------------------------------------------------

FROM python:3.12-slim

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PORT=8080 \
    SERVICE_HOST=0.0.0.0 \
    SERVICE_PROTOCOL=rest \
    SERVICE_TLS=true \
    XRAY_EXECUTABLE_PATH=/usr/local/bin/xray \
    XRAY_ASSETS_PATH=/usr/local/share/xray \
    SSL_DIR=/var/lib/marzban-node \
    SSL_CERT_FILE=/var/lib/marzban-node/ssl_cert.pem \
    SSL_KEY_FILE=/var/lib/marzban-node/ssl_key.pem \
    SSL_CLIENT_CERT_FILE=/var/lib/marzban-node/ssl_client_cert.pem


WORKDIR /code


COPY --from=build /usr/local/lib/python3.12/site-packages \
    /usr/local/lib/python3.12/site-packages

COPY --from=build /usr/local/bin/xray \
    /usr/local/bin/xray

COPY --from=build /usr/local/share/xray \
    /usr/local/share/xray


COPY . /code


RUN groupadd --system --gid 1001 app \
    && useradd --system --uid 1001 --gid app \
       --home /var/lib/marzban-node app \
    && mkdir -p /var/lib/marzban-node \
    && touch /var/lib/marzban-node/ssl_client_cert.pem \
    && chown -R app:app /var/lib/marzban-node /code \
    && chmod 0644 /var/lib/marzban-node/ssl_client_cert.pem \
    && chmod 0755 /usr/local/bin/xray \
    && chmod 0755 /usr/local/share/xray/xray \
    && chmod 0755 /code/start.sh


USER app


EXPOSE 8080


HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
 CMD python -c "import urllib.request,sys; sys.exit(0 if urllib.request.urlopen('https://127.0.0.1:'+__import__('os').environ.get('PORT','8080')+'/health',context=__import__('ssl')._create_unverified_context()).status==200 else 1)"


ENTRYPOINT ["bash","/code/start.sh"]
