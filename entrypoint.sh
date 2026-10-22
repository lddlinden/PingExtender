#!/bin/sh

VPN_USER="${VPN_USER:-spelare}"
VPN_PASS="${VPN_PASS:-losenord123}"

# Skapa ett enkelt självsignerat CA och servercertifikat för strongSwan om det saknas
if [ ! -f /etc/ipsec.d/certs/serverCert.pem ]; then
    ipsec pki --gen --type rsa --size 2048 --outform pem > /etc/ipsec.d/private/caKey.pem
    ipsec pki --self --ca --lifetime 3650 --in /etc/ipsec.d/private/caKey.pem --type rsa --outform pem > /etc/ipsec.d/cacerts/caCert.pem
    ipsec pki --gen --type rsa --size 2048 --outform pem > /etc/ipsec.d/private/serverKey.pem
    ipsec pki --pub --in /etc/ipsec.d/private/serverKey.pem --type rsa | \
        ipsec pki --issue --lifetime 730 --ca /etc/ipsec.d/cacerts/caCert.pem \
        --cakey /etc/ipsec.d/private/caKey.pem --dn "CN=GameProxyServer" --san "@$(hostname)" \
        --flag serverAuth --outform pem > /etc/ipsec.d/certs/serverCert.pem
fi

# Skriv användaruppgifter
cat <<EOF > /etc/ipsec.secrets
: RSA serverKey.pem
$VPN_USER : EAP "$VPN_PASS"
$VPN_USER : XAUTH "$VPN_PASS"
EOF

# Justera ipsec.conf så den känner till certifikatet
cat <<EOF > /etc/ipsec.conf
config setup
    uniqueids=yes

conn %default
    keyexchange=ikev2
    ike=aes256gcm16-prfsha384-ecp384,aes128gcm16-prfsha256-ecp256,aes256-sha256-modp2048,aes128-sha1-modp1024!
    esp=aes256gcm16-ecp384,aes128gcm16-ecp256,aes256-sha256-modp2048,aes128-sha1!
    dpdaction=clear
    dpddelay=30s
    rekey=no

conn ikev2-vpn
    auto=add
    compress=no
    type=tunnel
    left=%defaultroute
    leftsubnet=0.0.0.0/0
    leftcert=serverCert.pem
    leftauth=pubkey
    right=%any
    rightsourceip=192.168.43.0/24
    rightauth=eap-mschapv2
    eap_identity=%any
EOF

# Starta strongSwan i debug-läge så vi faktiskt ser loggar i Docker
ipsec start --nofork &

# Starta Python-webbservern
python3 app.py