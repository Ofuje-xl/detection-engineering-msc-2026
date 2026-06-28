# Research Log

Daily journal of work completed on the MSc Cybersecurity dissertation:
*Evaluating ATT&CK-Based Detection Engineering for Linux Systems Using Cowrie, Auditd, and Wazuh Telemetry.*


---

## 2026-06-07

**What I did**
- Created the GitHub repository.
- Drafted and committed the initial README.
- Set up the folder structure with `.gitkeep` placeholders.
- Initialised this research log.

**What I learned**
- First day, mostly project setup. No technical learning yet.

**What blocked me**
- Nothing significant.

**Next step**
- Read Winkler and Sharma (2025), *Proactive Threat Detection in Enterprise Systems Using Wazuh: A MITRE ATT&CK Evaluation*, in full.
- Take notes against three questions: what they measured, what they found, what they did not do that this project will do.

## 2026-06-28  

### M1 Lab Build Progress
- Created VMnet2 isolated network in VMware Workstation Pro 17
- Provisioned four VMs: wazuh-manager, ubuntu-target, cowrie-honeypot, kali-attacker (existing 2025.2 install repurposed)
- Configured static IPs across 192.168.56.0/24
- Resolved layer-2 connectivity issue (VMs were initially on Host-only/VMnet1 instead of VMnet2)
- All four VMs verified reachable via ping
- Baseline snapshots taken on all four VMs

### Next
- Add NAT adapters for internet access during installs
- Install Wazuh manager all-in-one stack on wazuh-mgr
- Install Cowrie on cowrie-hp
- Configure Auditd on linux-target
- Install Atomic Red Team on kali-atk

## 2026-06-29 

### What I worked on
- Added second network adapter (NAT/VMnet8) to all four VMs for internet access
- Updated netplan configs on three Ubuntu VMs to bring up both interfaces simultaneously
- Verified dual-network operation: lab network (VMnet2) for inter-VM traffic, NAT for outbound internet

### What I learned / problems hit
- Ubuntu 24.04 netplan does not auto-configure new network interfaces detected after install.
  Must explicitly add the new interface to /etc/netplan/50-cloud-init.yaml and run `netplan apply`.
- Kali (NetworkManager) handles new interfaces automatically. Ubuntu (netplan/networkd) does not.
- Important: lab interface in netplan should have NO gateway or nameservers configured.
  The NAT interface's DHCP provides the default route and DNS for the whole VM.

### Next
- Install Wazuh manager (all-in-one) on wazuh-mgr
- Install Auditd configuration on linux-target
- Install Cowrie on cowrie-hp
- Install Atomic Red Team on kali-atk

---
