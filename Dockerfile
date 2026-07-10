# syntax=docker/dockerfile:1

FROM golang:1.23-alpine AS builder

RUN apk add --no-cache git openssl make

WORKDIR /src

RUN git clone --depth 1 https://github.com/gozargah/marzban-node.git .

RUN go mod download

RUN make build


FROM alpine:latest

RUN apk add --no-cache \
    ca-certificates \
    curl \
    openssl \
    iproute2 \
    iptables

WORKDIR /app

COPY --from=builder /src/marzban-node /app/marzban-node

RUN mkdir -p /app/certs

# ساخت SSL خودامضا
RUN openssl req -x509 -newkey rsa:2048 -nodes \
    -keyout /app/certs/ssl_key.pem \
    -out /app/certs/ssl_cert.pem \
    -days 3650 \
    -subj "/CN=marzban-node"

ENV SERVICE_PORT=62050
ENV XRAY_API_PORT=62051
ENV SSL_CERT_FILE=/app/certs/ssl_cert.pem
ENV SSL_KEY_FILE=/app/certs/ssl_key.pem
ENV NODE_HOST=0.0.0.0

EXPOSE 62050

CMD ["/app/marzban-node"]
