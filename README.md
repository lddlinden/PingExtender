Verktyg för att lägga på latens i syfte att nå en målserver med en förbestämd ping hastighet.

Klona repon

chmod +x entrypoint.sh

docker build -t game-proxy-vpn .

docker run -d \
  --name game-proxy \
  --privileged \
  -p 500:500/udp \
  -p 4500:4500/udp \
  -p 9876:8080/tcp \
  --restart unless-stopped \
  game-proxy-vpn

  Nu kan du surfa till http://<din-server-ip>:9876 för att se live-data på anslutningar, justera mål-pingen i realtid, och ansluta dina Windows-datorer via IKEv2 helt isolerat från ditt övriga hemmanätverk!
