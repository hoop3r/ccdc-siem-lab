#!/usr/bin/env bash
set -e

export DEBIAN_FRONTEND=noninteractive

echo "[+] Updating system and installing prerequisites..."
apt update -y
apt install -y curl apt-transport-https lsb-release gnupg unzip debconf adduser procps

echo "[+] Installing Wazuh..."
curl -sO https://packages.wazuh.com/4.14/wazuh-install.sh && sudo bash wazuh-install.sh -a

echo "[+] Writing DVWA monitoring policy to agent.conf..."

cat << 'EOF' > /var/ossec/etc/shared/default/agent.conf
<agent_config>

  <localfile>
    <log_format>audit</log_format>
    <location>/var/log/audit/audit.log</location>
  </localfile>

  <!-- Enable auditd module -->
  <wodle name="audit">
    <disabled>no</disabled>
    <audit_rules>
      -w /etc/sudoers -p wa -k sudoers_changes
      -w /etc/sudoers.d/ -p wa -k sudoers_includes
      -a always,exit -F arch=b64 -S execve -k exec_log
      -a always,exit -F arch=b32 -S execve -k exec_log
      -w /var/log/sudo.log -p wa -k sudo_activity
      -w /usr/bin/sudo -p x -k sudo_bin
      -w /bin/su -p x -k su_bin
    </audit_rules>
  </wodle>

  <!-- Apache Access/Error Logs -->
  <localfile>
    <log_format>apache</log_format>
    <location>/var/log/apache2/access.log</location>
  </localfile>

  <localfile>
    <log_format>apache</log_format>
    <location>/var/log/apache2/error.log</location>
  </localfile>

  <!-- DVWA FIM -->
  <syscheck>
    <directories realtime="yes" check_all="yes">/var/www/html/DVWA</directories>
    <directories realtime="yes" check_all="yes">/bin</directories>
    <directories realtime="yes" check_all="yes">/usr/bin</directories> 
    <directories realtime="yes" check_all="yes">/usr/sbin</directories>
  </syscheck>

  <!-- Command Execution Monitoring -->
  <command>
    <name>whoami</name>
    <executable>/usr/bin/whoami</executable>
    <frequency>3600</frequency>
  </command>

  <!-- System Inventory -->
  <wodle name="syscollector">
    <disabled>no</disabled>
    <interval>1h</interval>
    <os>yes</os>
    <packages>yes</packages>
    <ports>yes</ports>
    <processes>yes</processes>
    <hardware>yes</hardware>
    <netaddr>yes</netaddr>
  </wodle>

  <!-- Vulnerability Detection -->
  <wodle name="vulnerability-detector">
    <enabled>yes</enabled>
    <interval>1h</interval>
    <provider name="canonical">
      <enabled>yes</enabled>
      <os>ubuntu</os>
    </provider>
  </wodle>

</agent_config>
EOF

echo "[+] Restarting Wazuh Manager to apply agent.conf..."
systemctl restart wazuh-manager

echo "[+] Extracting Wazuh passwords..."
sudo tar -O -xvf wazuh-install-files.tar wazuh-install-files/wazuh-passwords.txt > /home/vagrant/passwords.txt

echo "[+] Wazuh all-in-one node provisioned successfully with DVWA monitoring policy."
