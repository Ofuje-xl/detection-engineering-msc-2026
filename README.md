
## Dissertation

This repository accompanies the MSc Cybersecurity dissertation:

**Evaluating ATT&CK-Based Detection Engineering for Linux Systems Using Cowrie, Auditd, and Wazuh Telemetry**

**Author:** Jeffrey Ofuje Adegoke  
**Institution:** University of Sunderland  
**Programme:** MSc Cybersecurity  
**Year:** 2026

The repository contains the practical research artefacts produced during the study, including custom Sigma and Wazuh detection rules, Auditd configurations, reproducible attack procedures, controlled benign-testing evidence, and technique-level detection results.

The dissertation provides the authoritative analysis and interpretation of the experimental findings. The artefacts in this repository are provided to support transparency, traceability, and reproducibility.

## Project overview

This project evaluates ATT&CK-aligned detection engineering for Linux systems
using the open-source Wazuh SIEM and telemetry from Cowrie and Auditd.

Ten MITRE ATT&CK techniques relevant to SSH and Linux post-compromise activity
were executed in a controlled laboratory. Each technique was evaluated against
the baseline Wazuh configuration by verifying attack execution, confirming
telemetry capture, and recording the resulting Wazuh rule and alert level.

Where baseline detection was insufficient, custom detection logic was developed
and evaluated. Controlled benign scenarios were subsequently used to examine
false-positive behaviour and rule specificity.

## Research question

To what extent can Wazuh, supported by Cowrie and Auditd telemetry, reliably detect selected Linux post-compromise techniques, and what false-positive behaviour is observed when custom detection rules are evaluated against controlled benign activity?

## Evaluation approach

The evaluation uses two principal telemetry layers:

- **Protocol layer — Cowrie:** captures SSH authentication and session activity.
- **System-call layer — Auditd:** captures host-level activity including process
  execution, file access, and other audited system events.

Wazuh aggregates and processes this telemetry using its existing ruleset and
project-developed detection rules.

The evaluation follows four stages:

1. Execute and verify each ATT&CK technique.
2. Establish the baseline Wazuh detection outcome.
3. Develop and deploy custom detection logic for suitable identified gaps.
4. Re-execute attack procedures and test implemented rules against controlled
   benign activity.

## Key findings

Baseline evaluation produced a clear telemetry-path distinction. Three techniques
observed through journald generated actionable alerts, while seven techniques
observed through Auditd were captured and decoded but terminated at Wazuh rule
80700, level 0.

Five custom Wazuh rules (100020–100024) were implemented for selected Auditd
detection gaps. Two additional gaps, T1082 (System Information Discovery) and
T1059.004 (Unix Shell), were not assigned standalone alerting rules because the
available telemetry did not provide sufficiently discriminative conditions for
reliable alerting.

The evaluation also demonstrated that successful ATT&CK mapping does not imply
comprehensive procedure coverage. Detection effectiveness depended on the
specific procedure, available telemetry, fields exposed by the Wazuh decoder,
and the specificity of the detection rule.

Controlled benign testing further demonstrated the trade-off between detection
coverage and rule specificity. Broad key-only matching produced substantially more
benign matches than more specific detection conditions.

## Detection rules

Five custom Wazuh rules were implemented and evaluated:

| ATT&CK technique | Wazuh rule | Level | Detection condition |
|---|---:|---:|---|
| T1053.003 Cron | 100020 | 10 | Auditd `cron` key |
| T1070.003 Clear Command History | 100021 | 10 | Auditd `history_tamper` key + `rm`, `truncate`, or `shred` |
| T1098.004 SSH Authorized Keys | 100022 | 10 | Auditd `ssh_key_change` key |
| T1070.002 Clear Linux or Mac System Logs | 100023 | 10 | Auditd `log_tamper` key |
| T1105 Ingress Tool Transfer | 100024 | 8 | Auditd `process_creation` key + `curl` or `wget` |

The rules are provided in Sigma and Wazuh formats where applicable. Known
false-positive, decoder, telemetry, and procedure-coverage limitations are
documented alongside the detection content.

See [`rules/`](rules/) for the detection content and detailed documentation.

## Laboratory architecture

The controlled laboratory consists of four hosts:

- **Wazuh manager** — central telemetry ingestion, decoding and alerting.
- **Ubuntu target** — Linux endpoint instrumented with Auditd.
- **Cowrie SSH honeypot** — protocol-level SSH telemetry source.
- **Attacker host** — used to execute the selected ATT&CK procedures.

The environment was isolated from unsolicited external access and used solely
for controlled experimental testing.
## Reproducing the Evaluation

The repository contains the artefacts required to reproduce the principal stages of the evaluation. The experimental workflow was:

1. **Configure the laboratory environment**  
   Deploy the Wazuh manager, instrumented Ubuntu target, Cowrie SSH honeypot, and Kali Linux attacker within the isolated laboratory network.

2. **Configure telemetry collection**  
   Configure Auditd on the Linux target and Wazuh agents to forward Auditd and Cowrie telemetry to the Wazuh manager.

3. **Establish baseline detection behaviour**  
   Execute each selected ATT&CK procedure against the default Wazuh ruleset and record the telemetry source, matched rule, alert level, and detection outcome.

4. **Verify attack execution**  
   Confirm that the intended behaviour occurred using the underlying sensor telemetry. A successful test exit code alone was not treated as sufficient evidence of successful execution.

5. **Develop and deploy custom detection rules**  
   For identified Auditd-derived detection gaps, inspect the available decoded fields, author detection logic in Sigma where sufficiently discriminative conditions can be established, and implement the corresponding Wazuh-native rules.

6. **Re-execute the attack procedures**  
   Repeat the relevant procedures after rule deployment and record changes in rule matching and alert generation.

7. **Conduct controlled benign testing**  
   Execute defined legitimate administrative and user activities and record whether each custom rule also triggers on non-malicious behaviour.

8. **Analyse detection outcomes**  
   Compare baseline and post-rule results while considering telemetry availability, rule specificity, procedure coverage, benign triggering, and identified decoder or sensor limitations.

See the [`lab/`](lab/), [`atomic-tests/`](atomic-tests/), [`rules/`](rules/), and [`results/`](results/) directories for the corresponding configurations, procedures, detection content, and experimental evidence.

## Repository structure

```text
.
├── dissertation/        Dissertation-related material
├── lab/                 Laboratory configuration and supporting material
├── rules/
│   ├── sigma/           Vendor-neutral detection rules
│   ├── wazuh/           Wazuh implementations
│   └── auditd/          Auditd configuration required by custom rules
├── atomic-tests/        ATT&CK/Atomic Red Team test mappings
├── results/             Evaluation results and coverage matrix
├── references/          Research material
└── research-log.md      Experimental research log
