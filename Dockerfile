FROM alpine:3.18

RUN apk add --no-cache \
    strongswan \
    iptables \
    iproute2 \
    iputils \
    python3 \
    py3-pip \
    py3-flask

WORKDIR /app
COPY app.py .
COPY ipsec.conf /etc/ipsec.conf
COPY templates/ templates/
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

EXPOSE 500/udp 4500/udp 8080/tcp

ENTRYPOINT ["/entrypoint.sh"]