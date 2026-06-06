# Detection Engineering MSc 2026

> Evaluating ATT&CK-based detection engineering for Linux systems using Cowrie, Auditd, and Wazuh telemetry.

![Status](https://img.shields.io/badge/status-in%20progress-yellow)
![License](https://img.shields.io/badge/license-MIT-blue)
![University](https://img.shields.io/badge/MSc%20Cybersecurity-University%20of%20Sunderland-007a33)

This repository contains the lab infrastructure, detection rules, evaluation methodology, and supporting materials for my MSc Cybersecurity dissertation at the University of Sunderland, expected August 2026.

## What this project does

It runs a controlled set of known attacker techniques against a purpose-built Linux lab, then measures how well an open-source SIEM (Wazuh) detects each one using telemetry from two sources: the Cowrie SSH honeypot at the protocol layer, and Linux Auditd at the system-call layer. Where the default Wazuh ruleset misses an attack, custom detection rules are developed in Sigma format and translated to Wazuh's native syntax. The headline deliverable is a detection coverage matrix mapped to the MITRE ATT&CK framework, accompanied by measured false-positive rates against benign baseline activity.

## Research question

To what extent can an open-source SIEM (Wazuh), combined with multi-layer telemetry from Cowrie and Auditd, reliably detect a defined set of MITRE ATT&CK techniques relevant to Linux post-compromise activity, and at what false-positive rate against realistic benign activity?

## Why this matters

Most academic detection engineering research targets enterprise SOCs with budgets for commercial SIEM platforms. Very little research evaluates open-source detection capability through the lens of small organisations and managed service providers, which are the dominant real-world consumers of free SIEM. This project addresses three specific gaps in the literature:

- **Rigorous false-positive measurement** against realistic benign activity (most papers report detection rate without measuring false-positive rate)
- **MSP and SME framing** of detection capability evaluation
- **Multi-layer telemetry evaluation** comparing protocol-level (Cowrie) and system-level (Auditd) detection visibility per ATT&CK technique

## Closest published precedent

Winkler, A.M. and Sharma, P. (2025) "Proactive Threat Detection in Enterprise Systems Using Wazuh: A MITRE ATT&CK Evaluation," *Computers & Security*, 159. This project extends their evaluation framework by adding false-positive measurement, post-compromise tactics (Execution, Discovery, Defense Evasion, Persistence, Credential Access), and multi-layer telemetry.

## Lab architecture

The lab runs on VMware Workstation and consists of three virtual machines:

- **Ubuntu target** with Linux Auditd configured for system-call and authentication auditing
- **Cowrie SSH honeypot** for protocol-level capture of SSH attack sessions
- **Wazuh SIEM** for log ingestion, decoding, correlation, and alerting

A network diagram will live in `lab/diagrams/` once drafted.

## Repository structure

```
.
├── dissertation/        Drafts of the dissertation chapters
├── lab/                 VM configurations, network diagrams, install scripts
├── rules/               Sigma + Wazuh custom detection rules
├── atomic-tests/        Selected Atomic Red Team test mappings
├── results/             Test outputs and the detection coverage matrix
├── references/          Annotated literature
└── research-log.md      Daily research journal
```

## Tooling

- [Wazuh](https://wazuh.com/) - open-source SIEM and XDR platform
- [Cowrie](https://github.com/cowrie/cowrie) - medium-interaction SSH/Telnet honeypot
- [Auditd](https://linux.die.net/man/8/auditd) - Linux audit subsystem
- [Atomic Red Team](https://github.com/redcanaryco/atomic-red-team) - reproducible attack test framework mapped to MITRE ATT&CK
- [Sigma](https://github.com/SigmaHQ/sigma) - generic SIEM detection rule format
- [MITRE ATT&CK](https://attack.mitre.org/) - knowledge base of adversary tactics and techniques

## Status

This project is in active development. Expected submission: August 2026.

| Milestone | Target | Status |
|-----------|--------|--------|
| Workspace setup | Week 1 | In progress |
| Lab build | Week 2 | Not started |
| ATT&CK technique selection | Week 3 | Not started |
| Baseline evaluation | Weeks 4-6 | Not started |
| Custom rule development | Weeks 7-8 | Not started |
| False-positive evaluation | Weeks 9-10 | Not started |
| Coverage matrix and dissertation writing | Weeks 11-12 | Not started |

## Author

Jeffrey Ofuje Adegoke  
MSc Cybersecurity, University of Sunderland  
[Portfolio](https://ofuje-xl.github.io) | [GitHub](https://github.com/Ofuje-xl) 

## Licence

MIT, see [LICENSE](LICENSE).
