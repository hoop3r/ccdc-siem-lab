## **Introduction**

For the CCDC competition, asset management and log visibility is a critical in the challenge of keeping the red team at bay. A SIEM (security information & event management) solution can be a handy tool in providing the following services: 

- Aggregate & centralize logs from Linux, Windows, cloud, & network devices
- Monitor compliance baselines ( NIST, CIS, etc. )
- Assess security configuration
- Vulnerability detection
- Single point of truth for forensics

Building off of this, XDR platforms combine the benefits of a SIEM with added threat intelligence, automated response workflows, and behavioral analysis.

Mapping to the CIS Controls, a tool like this (*your milage may very*) could help with the following Controls:

1 - inventory and control of enterprise assets

2 - inventory and control of software assets

4 - Secure configuration of enterprise assets and software

5 - Account management

6 - Access control management 

7 - Continuous vulnerability management 

8 -  Audit log management

10 - Malware Defenses

13 - Network Monitoring and Defense

17 - Incident Response Management

TLDR: *it is very useful for inject responses!*

## Overview

To demonstrate these capabilities, we will be spinning up a virtual environment built around Wazuh, which is an open-source XDR platform. The “Damn Vulnerable Web Application” (referred to DVWA in this lab) is going to be our victim server running a Wazuh agent that will report back to the mothership. 

The goal for this lab is to configure the Wazuh components such that all config files are centrally managed, all activity pertinent to threat hunting is available in the dashboard in real-time, and automated responses are enabled for common web-based attacks. This is not meant to be conclusive, but is instead a great launching point for fine-tuning for specific use cases.

Three nodes are provisioned automatically using Vagrant:

1. Wazuh server
2. DVWA server
3. Kali workstation

An automated attack script will be provided in the home directory of the kali box. It includes a basic SQL injection, XSS, and Hydra brute-force attacks that are to be ran against the DVWA. *Please aim your weapons only at the lab environment! ;)* 

## Wazuh Server Components & Setup

Wazuh is built of three primary central components: 

1. Manager → The manager is the heart which is in charge of rules, decoders, FIM (file integrity management), SCA (security configuration assessment), and agent management. 
2. Indexer → The indexer stores alerts, logs, and inventory data. (Powered by OpenSearch) 
3. Dashboard → Web UI for searching alerts, visualizing data, and much much more. 

The Wazuh agent provides capabilities such as log data collection, file integrity monitoring, threat detection, security configuration assessment, system inventory, vulnerability detection, and incident response

The provisioning script shipped with the lab installs the central components, and notably configures the standard agent configuration. Agents can be configured remotely by using the `agent.conf` file, which is located at `/var/ossec/etc/shared/default/agent.conf`.  Agents can be assinged groups which will distinguish which `agent.conf`ruleset applies to the agent. For example, if we had two machines with separate security models or active services, we can create a theoretical high-impact group for server agents which monitors logs in real-time with specific security automations enabled while having another low-impact group designated for workstations. The key of managing SIEMs is to cut down on anything unnecessarily noisy to provide the highest and cleanest visibility to things that you actually care about. 

For the scope of this lab, I have left the agent in the default group. We must consider the nature of the DVWA in order to understand what configurations need to be set in the `agent.conf` file. DVWA runs off of the Apache2 web server, which logs to /var/log/apache2/access.log and /var/log/apache2/error.log. The application additionally serves its content from the /var/www/html/DVWA location. For the sake of blue team sanity, it’s helpful to cast the floodlights on this directory. Enabling real-time file integrity monitoring for this directory is going to be especially crucial for detecting unauthorized changes, malicious file uploads, or other unwanted activity. With the attacks ran against DVWA, we will explore how the correlation of these three information sources can boost visibility and aid in effective response.  

## Lab File Structure

 `Vagrantfile`

 `Scripts` 

\\__ `provision-wazuh-manager.sh`

\\__ `provision-vuln-web.sh`

\\__ `provision-kali.sh`

\\__ `dvwa_attack.sh`

## Credentials

- **Wazuh Server:** `vagrant:vagrant`
- **Wazuh Dashboard:** `admin:*random*`(included in `/home/vagrant/passwords.txt` on the Wazuh server)
- **DVWA Server:** `vagrant:vagrant`
- **Kali Linux:** `vagrant:vagrant`
- **DVWA login:** `admin:*blank*`OR `admin:password`

## IP Addresses

- **Wazuh Server:** `192.168.56.10`
- **DVWA Server:** `192.168.56.20`
- **Kali Linux:** `192.168.56.30`

## Key Script Locations

- **Kali attack script:** `/home/vagrant/dvwa-attack.sh`
- **Wazuh passwords file:** `/home/vagrant/passwords.txt`
- **DVWA directory:** `/var/www/html/DVWA`

## Lab Setup Steps

1. Run `vagrant up` on your host machine
2. Once everything is provisioned, view the GUIs with a tool like virt-manager
3. Open the dashboard on the kali workstation in Firefox: `https://192.168.56.10`
4. Log in using the credentials saved to `/home/vagrant/passwords.txt` on the Wazuh machine -- (you can ssh into the wazuh machine to grab this password so you can copy and paste into the browser)
5. Save this password in Firefox to make life easier
6. Ensure the agent is connected successfully in the Wazuh dashboard. Running sudo on the machine should start to trigger some basic alerts.
7. Open the DVWA page on the kali workstation in Firefox: `http://192.168.56.20/DVWA` 
8. Log in using the default credentials `admin:*blank*`
9. In the admin page, scroll down and click `Create / Reset database` . This should change the default  credentials to `admin:password`
10. Try running the `dvwa-attach.sh` script from the kali workstation. Alerts will begin to populate.
11. The `Events` tab under the `Threat Hunting` view can be particularly useful for discovering high-impact activities taking place on the server. Although there is a separate view for FIM activity, these events will populate here as well under the following name: “Integrity checksum changed”. 
    
    Note: Remember to filter out any alerts that are triggering on the Wazuh server itself since we only care about DVWA in this case. 

12. Menu → Explore → Discover in the Wazuh dashboard is the central location for all alerting. Practice filtering by agent.name to filter out any noise 
13. Refer to public write-ups on DVWA and experiment with their attacks on the website itself. What can Wazuh detect? What are its limitations? 
14. Try a command injection attack that writes to the web directory. Navigate to `http://192.168.56.20/DVWA/vulnerabilities/exec` . Try entering `127.0.0.1 ; echo “testing testing 123” > test.txt` into the text box and hit submit. It logged by FIM? Notice the timestamp. How closely does it reflect the time of the attack?