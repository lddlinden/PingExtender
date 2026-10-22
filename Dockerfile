FROM alpine:3.18

# Installera strongSwan, nödvändiga krypto-plugins, iptables, iproute2 och python
RUN apk add --no-cache \
    strongswan \
    iptables \
    iproute2 \
    iputils \
    openssl \
    python3 \
    py3-pip \
    py3-flask

WORKDIR /app
COPY app.py .
COPY templates/ templates/
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

EXPOSE 500/udp 4500/udp 8080/tcp

ENTRYPOINT ["/entrypoint.sh"]