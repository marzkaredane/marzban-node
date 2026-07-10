FROM golang:1.23-alpine AS builder

RUN apk add --no-cache git make openssl

WORKDIR /src

RUN git clone --depth 1 https://github.com/gozargah/marzban-node.git .

RUN ls -la
RUN find . -name go.mod

RUN make build


FROM alpine:latest

RUN apk add --no-cache \
    ca-certificates \
    openssl \
    iproute2 \
    iptables

WORKDIR /app

COPY --from=builder /src /app

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

EXPOSE 62050

CMD ["./marzban-node"]
