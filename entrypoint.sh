#!/bin/sh

# Hämta uppgifter från miljövariabler eller använd standard
VPN_USER="${VPN_USER:-spelare}"
VPN_PASS="${VPN_PASS:-losenord123}"
VPN_PSK="${VPN_PSK:-HemligNyckel123}"

# Skriv konfigurationen till strongSwans hemliga filer
cat <<EOF > /etc/ipsec.secrets
: PSK "$VPN_PSK"
$VPN_USER : EAP "$VPN_PASS"
$VPN_USER : XAUTH "$VPN_PASS"
EOF

# Starta strongSwan
ipsec start

# Starta Python-webbservern
exec python3 app.py