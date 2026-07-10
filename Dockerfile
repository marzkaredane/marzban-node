# syntax=docker/dockerfile:1

FROM golang:1.23-alpine AS builder

RUN apk add --no-cache git make openssl

WORKDIR /src

RUN git clone --depth 1 https://github.com/gozargah/marzban-node.git .

RUN find . -name go.mod

# اگر go.mod در پوشه اصلی بود:
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

COPY --from=builder /src/ /app/

RUN mkdir -p /app/certs

RUN openssl req -x509 -newkey rsa:2048 -nodes \
    -keyout /app/certs/ssl_key.pem \
    -out /app/certs/ssl_cert.pem \
    -days 3650 \
    -subj "/CN=marzban-node"

ENV SERVICE_PORT=62050
ENV XRAY_API_PORT=62051
ENV SSL_CERT_FILE=/app/certs/ssl_cert.pem
ENV SSL_KEY_FILE=/app/certs/ssl_key.pem

EXPOSE 62050

CMD ["./marzban-node"]
