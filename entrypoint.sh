#!/bin/sh

# Hämta uppgifter från miljövariabler eller använd standard
VPN_USER="${VPN_USER:-spelare}"
VPN_PASS="${VPN_PASS:-losenord123}"

# Skriv konfigurationen till strongSwans hemliga filer (enbart användare/lösenord)
cat <<EOF > /etc/ipsec.secrets
$VPN_USER : EAP "$VPN_PASS"
$VPN_USER : XAUTH "$VPN_PASS"
EOF

# Starta strongSwan
ipsec start

# Starta Python-webbservern
exec python3 app.py