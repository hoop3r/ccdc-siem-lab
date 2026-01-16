#!/usr/bin/env bash
set -e

apt update -y

echo "[+] Installing DVWA (Damn Vulnerable Web Application)..."
sudo bash -c "$(curl --fail --show-error --silent --location https://raw.githubusercontent.com/IamCarron/DVWA-Script/main/Install-DVWA.sh)"

echo "[+] Installing auditd for full command visibility..."
apt install -y auditd audispd-plugins

echo "[+] Enabling auditd service..."
systemctl enable --now auditd

echo "[+] Applying audit rules for execve, sudo, su, and PAM..."

cat << 'EOF' > /etc/audit/rules.d/wazuh-dvwa.rules
# Log every executed command (execve)
-a always,exit -F arch=b64 -S execve -k exec_log
-a always,exit -F arch=b32 -S execve -k exec_log

# Monitor sudoers changes
-w /etc/sudoers -p wa -k sudoers_changes
-w /etc/sudoers.d/ -p wa -k sudoers_includes

# Monitor sudo and su binaries
-w /usr/bin/sudo -p x -k sudo_bin
-w /bin/su -p x -k su_bin

# Monitor authentication events
-w /var/log/auth.log -p wa -k auth_activity
EOF

echo "[+] Reloading audit rules..."
augenrules --load || true
systemctl restart auditd

echo "[+] Adding Wazuh GPG key and repo..."
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | apt-key add -
echo "deb https://packages.wazuh.com/4.x/apt/ stable main" \
  | tee /etc/apt/sources.list.d/wazuh.list

echo "[+] Installing Wazuh Agent..."
apt update -y
apt install -y wazuh-agent

echo "[+] Configuring Wazuh Agent to talk to manager..."
sed -i 's|<address>.*</address>|<address>192.168.56.10</address>|' \
  /var/ossec/etc/ossec.conf

echo "[+] Enabling Wazuh Agent..."
systemctl enable --now wazuh-agent

echo "[+] Restarting Apache..."
systemctl restart apache2

echo "[+] Vulnerable web server setup complete with auditing."