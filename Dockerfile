# syntax=docker/dockerfile:1

FROM golang:1.23-alpine AS builder

RUN apk add --no-cache git make openssl

WORKDIR /src

RUN git clone --depth 1 https://github.com/gozargah/marzban-node.git .

# بررسی ساختار پروژه
RUN ls -la

# ساخت طبق Makefile پروژه
RUN make NAME=main build


FROM alpine:latest

RUN apk add --no-cache \
    ca-certificates \
    openssl \
    iproute2 \
    iptables

WORKDIR /app

COPY --from=builder /src/main /app/main

RUN mkdir -p /app/certs

RUN openssl req -x509 -newkey rsa:2048 -nodes \
    -keyout /app/certs/ssl_key.pem \
    -out /app/certs/ssl_cert.pem \
    -days 3650 \
    -subj "/CN=marzban-node"

ENV SSL_CERT_FILE=/app/certs/ssl_cert.pem
ENV SSL_KEY_FILE=/app/certs/ssl_key.pem
ENV SERVICE_PORT=62050
ENV XRAY_API_PORT=62051
ENV NODE_HOST=0.0.0.0

EXPOSE 62050

ENTRYPOINT ["/app/main"]
