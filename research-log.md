# Research Log

Daily journal of work completed on the MSc Cybersecurity dissertation:
*Evaluating ATT&CK-Based Detection Engineering for Linux Systems Using Cowrie, Auditd, and Wazuh Telemetry.*

Each entry follows the format below. Keep it short. Two or three sentences per heading is fine.

---

## 2026-06-07: Day 1

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

---
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
