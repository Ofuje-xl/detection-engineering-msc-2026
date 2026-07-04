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
  
## 2026-07-04 (afternoon)

### Pattern: Wazuh systemd startup timeouts on constrained hardware

After resuming lab work following several days of inactivity, all three
Wazuh services (manager, indexer, dashboard) failed to start with systemd
timeout errors. The packaged systemd unit files assume production-class
hardware; on this lab VM (6GB RAM, 2 vCPU, sharing a laptop host with three
other running VMs) each service's initialisation sequence exceeds the default
timeouts, causing systemd to terminate services mid-startup even though the
underlying processes are healthy.

**Diagnostic pattern:**
- `systemctl status` reports Active: failed with "Failed with result 'timeout'"
- `journalctl -u <service>` shows sub-components successfully reporting "Started"
- `ps aux | grep -i wazuh` shows Wazuh processes still running (orphaned)
- The service is actually healthy; systemd's expectations are wrong

**Overrides applied** (all via /etc/systemd/system/<service>.service.d/override.conf):

| Service          | Default | Override | Rationale |
|------------------|---------|----------|-----------|
| wazuh-manager    | 45s     | 300s     | Sequential daemon startup on constrained CPU |
| wazuh-dashboard  | 90s     | 300s     | Node.js startup + indexer discovery |
| wazuh-indexer    | 90s     | 600s     | JVM warm-up on modest RAM |

**Broader operational relevance:**
This pattern is likely to recur in any small-team or MSP deployment of Wazuh
on modest hardware. Vendor defaults are calibrated for production-class hosts;
lab and SME contexts routinely diverge from those assumptions. This gap between
vendor default configuration and realistic deployment environments is worth
flagging in the practical recommendations chapter of the dissertation as a
Wazuh deployment consideration for SMEs, consistent with the broader argument
about open-source SIEM viability for resource-constrained organisations
(Manzoor et al., 2024).

**Transferable practice for future deployments:**
When deploying a stack of related services to a new environment, run a
one-shot systemd audit up front:
`for svc in <services>; do systemctl cat $svc | grep -iE "Timeout|Restart|LimitNOFILE"; done`
Then apply generous overrides before first start rather than reactively.

### Next
- Register first Wazuh agent on linux-target
- Verify end-to-end log flow from linux-target to dashboard
- Snapshot wazuh-fully-operational-all-timeouts-fixed
- Close out M1
---
