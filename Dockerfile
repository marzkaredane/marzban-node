FROM golang:1.23-alpine AS builder

RUN apk add --no-cache git make openssl

WORKDIR /src

RUN git clone --depth 1 https://github.com/gozargah/marzban-node.git .

RUN ls -la
RUN find . -maxdepth 3 -name Makefile -o -name go.mod

RUN cat Makefile
