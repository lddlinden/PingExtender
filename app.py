import os
import subprocess
import threading
import time
import re
import urllib.request
from flask import Flask, render_template, request, redirect

app = Flask(__name__)

# Konfiguration via miljövariabler (från .env)
CONFIG = {
    "target_ping": float(os.getenv("TARGET_PING", "60.0")),
    "target_game_ip": os.getenv("TARGET_GAME_IP", "8.8.8.8"),
    "vpn_psk": os.getenv("VPN_PSK", "HemligNyckel123"),
    "vpn_user": os.getenv("VPN_USER", "spelare"),
    "vpn_pass": os.getenv("VPN_PASS", "losenord123")
}

clients_data = {}

def get_game_ping():
    try:
        res = subprocess.run(["ping", "-c", "1", "-W", "1", CONFIG["target_game_ip"]], stdout=subprocess.PIPE, text=True)
        m = re.search(r"time=([\d\.]+)\s*ms", res.stdout)
        return float(m.group(1)) if m else None
    except:
        return None

def get_ips():
    try:
        # Hämta publik IP via en extern pub-ip tjänst
        public_ip = urllib.request.urlopen('https://api.ipify.org', timeout=2).read().decode('utf8')
    except:
        public_ip = "Kunde ej hämta (Ingen internetåtkomst?)"
    return public_ip

def background_traffic_controller():
    # Initiera grundläggande tc på eth0
    subprocess.run("tc qdisc add dev eth0 root handle 1: prio", shell=True, stderr=subprocess.DEVNULL)
    
    while True:
        base_ping = get_game_ping()
        if base_ping is not None:
            # Hämta aktiva anslutna IPsec-klienter (via ipsec strokes / status)
            status_res = subprocess.run("ipsec status", shell=True, stdout=subprocess.PIPE, text=True)
            ips = re.findall(r"192\.168\.43\.\d+", status_res.stdout)
            active_ips = list(set(ips))
            
            global clients_data
            new_clients_data = {}
            
            for ip in active_ips:
                if ip not in clients_data:
                    clients_data[ip] = {"delay": 0.0}
                    # Skapa unik iptables markering och tc-filter för denna IP
                    mark_id = hash(ip) % 1000 + 10
                    subprocess.run(f"iptables -t mangle -A POSTROUTING -d {ip} -j MARK --set-mark {mark_id}", shell=True)
                    subprocess.run(f"tc qdisc replace dev eth0 parent 1:3 handle {mark_id}: netem delay 0ms", shell=True, stderr=subprocess.DEVNULL)
                    subprocess.run(f"tc filter replace dev eth0 protocol ip parent 1:0 prio 3 handle {mark_id} fw flowid 1:3", shell=True, stderr=subprocess.DEVNULL)
                
                # Räkna ut ny delay mot det globala målet
                diff = CONFIG["target_ping"] - base_ping
                current_delay = clients_data[ip]["delay"] + (diff * 0.5)
                current_delay = max(0.0, current_delay)
                clients_data[ip]["delay"] = current_delay
                
                mark_id = hash(ip) % 1000 + 10
                subprocess.run(f"tc qdisc change dev eth0 parent 1:3 handle {mark_id}: netem delay {int(current_delay)}ms", shell=True, stderr=subprocess.DEVNULL)
                
                new_clients_data[ip] = {"delay": round(current_delay, 1)}
            
            clients_data = new_clients_data
        time.sleep(3)

@app.route("/")
def index():
    base_ping = get_game_ping()
    public_ip = get_ips()  # Hämtar den publika IP-adressen
    return render_template("index.html", config=CONFIG, clients=clients_data, base_ping=base_ping, public_ip=public_ip)

@app.route("/update", methods=["POST"])
def update():
    CONFIG["target_ping"] = float(request.form.get("target_ping", 60.0))
    CONFIG["target_game_ip"] = request.form.get("target_game_ip", CONFIG["target_game_ip"])
    return redirect("/")

if __name__ == "__main__":
    # Starta bakgrundstråd för nätverksmanipulation
    t = threading.Thread(target=background_traffic_controller, daemon=True)
    t.start()
    app.run(host="0.0.0.0", port=8080)