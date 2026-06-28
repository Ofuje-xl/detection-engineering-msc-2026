# Lab Network Topology

## VMware Network Configuration
- Network: VMnet2
- Type: Host-only (isolated, no DHCP, no host adapter)
- Subnet: 192.168.56.0/24
- Hypervisor: VMware Workstation Pro 17

## Virtual Machines

| Hostname | VM Name | IP Address | OS | Role |
|----------|---------|------------|----|----|
| wazuh-mgr | wazuh-manager | 192.168.56.10 | Ubuntu Server 24.04 LTS | Wazuh manager, indexer, dashboard |
| linux-target | ubuntu-target | 192.168.56.20 | Ubuntu Server 24.04 LTS | Target host with Auditd, Wazuh agent |
| cowrie-hp | cowrie-honeypot | 192.168.56.30 | Ubuntu Server 24.04 LTS | Cowrie SSH honeypot |
| kali-atk | kali-attacker | 192.168.56.40 | Kali GNU/Linux Rolling 2025.2 | Attack execution: Atomic Red Team, manual probes |

## Verification
All four VMs verified reachable via ICMP on date: 28/06/2026
