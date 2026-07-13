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
## 2026-07-04 (evening) — M1 CLOSED

### Milestone status
- Planned: 01 Jul 2026
- Actual: 04 Jul 2026 (3 days over, within tolerance)
- Slippage caused by the three failure patterns documented in this session

### What's operational
- wazuh-mgr: manager, indexer, dashboard, filebeat all stable with timeout overrides
- linux-target: Wazuh agent 4.13.1 registered as agent ID 001, reading from journald
- End-to-end log flow verified: SSH failures from kali-atk (192.168.56.40) triggering rules 5503 and 5710 in alerts.log

### Pattern 2: Silent detection failure via disk exhaustion

After the timeout fixes, SSH failure tests from Kali initially appeared not to be detected. Diagnosis revealed the wazuh-mgr root filesystem was 100% full. Root cause: Wazuh's default install enables the Vulnerability Detection module, which downloaded 15 GB of CVE databases to `/var/ossec/queue/vd` and `/var/ossec/queue/vd_updater`, exhausting the 29 GB root partition.

When disk pressure hit critical, OpenSearch flipped indices to `read_only_allow_delete` mode, silently blocking new event indexing. Every observability metric lied — services showed Active in systemd, dashboard widgets rendered, agents reported connected — but no new alerts were being generated. Wazuh's own Rule 1007 detected the disk-full condition but the alert was buried in low-severity noise.

Fix applied:
- Disabled Vulnerability Detection in ossec.conf (`<enabled>no</enabled>`)
- Deleted contents of `/var/ossec/queue/vd/*` and `/var/ossec/queue/vd_updater/*`
- Released OpenSearch read-only lock via API
- Disk usage dropped from 100% to 70%; 8.2 GB free

### Pattern 3: Signal-to-noise in default alert visibility

Even after the pipeline was working, SSH failure alerts weren't obviously visible in the default dashboard view because they were drowned in level-3 sudo and PAM administrative alerts from routine admin activity. Dashboard needed explicit filtering (`rule.id: 5710` or `data.srcip: 192.168.56.40`) to surface security-relevant events.

This is directly relevant to the dissertation's false-positive contribution: a "functioning" SIEM without noise tuning is operationally unusable. Alert volume without prioritisation defeats the purpose of centralised monitoring.

### MSP-track relevance across all three patterns
- Vendor defaults calibrated for production hosts, not SME reality (Manzoor et al., 2024)
- Silent failure modes where every observability metric lies except the one that matters
- Ship-defaults produce alert volumes that hide real signal without deliberate tuning

Deployment playbook implications for future MSP client engagements: systemd hardening audit up front, generous disk provisioning with external monitoring, mandatory post-deployment detection validation step with known-safe test events, and rule-tuning phase before handing over to analyst use.

### Next session
- Install Wazuh agent on cowrie-hp
- Configure Auditd rules on linux-target for the 10 target ATT&CK techniques
- Verify Auditd-sourced events appear in dashboard

## 2026-07-07 (morning) — Week 5 continuation

### What I worked on
- Installed Wazuh agent on cowrie-hp (agent ID 002, Active)
- Verified three agents in manager: wazuh-mgr (server), linux-target, cowrie-hp
- Started Auditd installation on linux-target
- Chose Neo23x0 open-source ruleset as base, tuned for the 10 target ATT&CK techniques

### Rationale for Neo23x0
Using an established community-maintained ruleset mirrors current professional detection engineering practice and matches the methodology a real MSP would deploy at a client site.

### Next
- Confirm Auditd is running on linux-target
- Pull Neo23x0 ruleset, review, deploy
- Tell Wazuh agent to read audit.log
- Verify one Auditd-sourced event appears in dashboard

## 2026-07-07 (afternoon) — Auditd deployed on linux-target

Deployed Neo23x0's community-maintained Auditd ruleset (v-latest, 225 rules
from https://github.com/Neo23x0/auditd) into /etc/audit/rules.d/neo23x0.rules.
206 rules loaded cleanly into the kernel; 19 silently skipped for kernel
syscall availability (SELinux-specific paths and RHEL-specific rules not
applicable to Ubuntu 24.04), using the ruleset's `-i` graceful fallback flag.

Added four custom rules for T1098.004 (SSH authorized_keys) and T1070.003
(bash_history) in /etc/audit/rules.d/99-custom-msc.rules:
- -w /root/.ssh/authorized_keys -p wa -k ssh_key_change
- -w /home/jeffrey/.ssh/authorized_keys -p wa -k ssh_key_change
- -w /root/.bash_history -p wa -k history_tamper
- -w /home/jeffrey/.bash_history -p wa -k history_tamper

Updated Wazuh agent config (/var/ossec/etc/ossec.conf) with localfile block
to read /var/log/audit/audit.log with the `audit` log format. Agent restarted
to pick up the new source.

End-to-end validation: `sudo useradd testauditor` generated user-creation
alerts tagged with Neo23x0's `identity` key, visible in Wazuh manager's
alerts.log within seconds. Confirmed all seven links of the detection pipeline
work: kernel-level auditing → Neo23x0 rule match → local audit.log write →
Wazuh agent read → network forwarding → manager rule match → alerts.log
storage.

### Design rationale on rule scope
Custom rules watch specific file paths rather than directory trees, reflecting
Auditd's non-recursive directory-watch semantics. In an MSP production
deployment this would require per-user rule generation via templating
(Ansible/Jinja2), as the Neo23x0 documentation notes. For this project only
the `jeffrey` and `root` user paths are watched, which is sufficient for the
technique catalogue evaluation.

### Notable finding for methodology chapter
Neo23x0's design philosophy statement (rules provide broad, high-fidelity
telemetry; detection intelligence belongs in the SIEM/Sigma layer, not the
audit ruleset) directly matches this project's two-layer architecture: Auditd
as broad kernel-level sensor, Wazuh as intelligence and alerting layer. This
citation will support the methodology chapter's separation-of-concerns
argument for the lab design.

## 2026-07-07 (evening) — Auditd rule validation and the file-descriptor quirk

Verified custom rules `history_tamper` and `ssh_key_change` fire correctly
on file writes to their target paths. During validation, discovered that
Auditd file watches (`-w`) do not apply retroactively to file descriptors
opened by processes that predate the rule installation. This means the
first shell session used for validation (which inherited bash's already-open
handle on .bash_history from before rule load) produced no audit events on
appends, while a fresh SSH session opened after rule load fired the rule
immediately.

Operational implication for detection engineering: audit rule deployment
must be paired with either a fresh service restart or session recycling
in any environment where processes might hold long-lived file descriptors.
In production MSP deployments this typically means: deploy rules during
maintenance windows when service restarts are scheduled, or accept a rolling
enforcement window as sessions naturally cycle.

Verification evidence: audit record 1783462689.718:2755 shows bash (pid 2712)
opening /home/jeffrey/.bash_history via syscall 257 (openat), tagged with
key="history_tamper".

## 2026-07-08 (morning) — Cowrie deployed via Docker

Abandoned pip installation after five failure modes across three Cowrie
versions (3.0.0, 2.9.0, 2.7.0). Deployed via official cowrie/cowrie Docker
image with volume mounts to /opt/cowrie/{etc,var} on the host.

Runtime UID discovery: container declares cowrie:1001 in /etc/passwd but
actually runs as UID 999 at runtime (entrypoint drops privileges to a
different account). Diagnosed by running Cowrie with chmod 777 to identify
which UID Cowrie's process actually wrote files as. Fixed with
chown -R 999:999 /opt/cowrie and 755 permissions.

Known limitation: Cowrie 3.0.5's interactive shell hangs after successful
authentication when connecting from modern OpenSSH clients (both host and
Kali 2025.2). Protocol-layer capture (connections, KEX, credentials, hassh
fingerprints, environment vars) works completely; post-login command capture
(cowrie.command.input) does not fire in current version.

For dissertation methodology: this affects T1059.004 Unix Shell coverage
via Cowrie only. Command execution on the target host is still covered by
Auditd on linux-target, so the multi-layer telemetry contribution
(protocol layer via Cowrie for auth events, system-call layer via Auditd
for post-login) remains intact. The limitation will be documented in the
methodology and evaluation chapters.

## 2026-07-08 (afternoon) — Custom Wazuh rules for Cowrie honeypot

Wazuh 4.13 ships no built-in Cowrie decoders or rules. Verified via
temporary archive logging (logall=yes) that Cowrie events reach the manager
correctly but don't fire alerts because no rule matches them.

Added four custom rules in /var/ossec/etc/rules/local_rules.xml:
- 100010 (level 0): Cowrie event group parent, matches eventid ^cowrie\.
- 100011 (level 8): cowrie.login.failed → MITRE T1110.001
- 100012 (level 10): cowrie.login.success → MITRE T1078.003, T1110.001
- 100013 (level 5): cowrie.session.connect

Verified end-to-end: SSH from kali-atk (192.168.56.40) to cowrie-hp:2222
with credentials root/password123 fires rules 100013 and 100012 in
alerts.log within seconds. Alert descriptions correctly interpolate
src_ip and username via Wazuh variable substitution.

For MSP-track thinking: custom rules for third-party log sources are
routine at client sites. Every new data source (application logs, custom
appliances, honeypots) requires rule authoring or vendor rule packs.
Documenting rules as part of the deployment artefact (in this case,
committed to the project GitHub repo) is standard operational practice.

## 2026-07-08 (evening) — Atomic Red Team installed + coverage audit

Installed PowerShell 7.6.2 and Invoke-AtomicRedTeam 2.3.0 module on kali-atk.
Cloned atomics library (417MB, shallow clone) to ~/AtomicRedTeam.

Audited Atomic Red Team Linux coverage for all 10 target techniques:
- 7 fully covered: T1078.003, T1059.004 (17 tests), T1053.003, T1136.001,
  T1070.003 (10 tests), T1082, T1105
- 3 gaps requiring custom atomic tests:
  - T1110.001: native Linux tests are local sudo brute-force, not remote SSH
    (which is the project's actual threat model)
  - T1098.004 SSH Authorized Keys: 0 Linux tests
  - T1070.002 Clear Linux Logs: no folder exists; parent T1070 has no
    relevant Linux log-clearing tests either

Finding for methodology/discussion: the industry-standard attack simulation
framework has Linux coverage gaps for specific post-compromise techniques.
An SME relying solely on off-the-shelf Atomic Red Team would have blind spots
for remote SSH brute force, SSH key persistence, and Linux log clearing.
Custom atomic tests (same YAML structure) will be authored and published to
the project GitHub repo, potentially contributed upstream.

## 2026-07-13 — First end-to-end attack-to-detection cycle validated

Executed first real Atomic Red Team test against linux-target: T1136.001-1
(Create Account: Local Account), GUID 40d8eabd-e394-46f6-8785-b9bfa1d011d2.

Command executed: useradd -M -N -r -s /bin/bash -c evil_account evil_user
Result: exit code 0, user created successfully.

Detection: Wazuh fired Rule 5902 (level 8) "New user added to the system"
within seconds, extracting username (evil_user), UID (999), home, and shell.
Alert auto-tagged with PCI-DSS, GDPR, HIPAA, NIST compliance mappings.

Full pipeline confirmed working end to end: Atomic Red Team → useradd →
journald/Auditd capture → Wazuh agent → manager → rule match → alert.

### Notable finding
Detection came from Wazuh's built-in journald rule 5902, not from the
Neo23x0 Auditd `identity` watch (which was also monitoring /etc/passwd).
For this technique the default ruleset already provides coverage; the
Auditd layer is redundant here. This is exactly the baseline-vs-custom
distinction the evaluation is designed to measure — some techniques are
caught by defaults, others will need custom rules. T1136.001 is a
"default-covered" technique.

### Operational learnings
- Invoke-AtomicRedTeam module must be installed AllUsers scope (or run
  under the same user that installed it) so root can load it plus its
  powershell-yaml dependency for elevation-required tests.
- Atomics folder path must be passed explicitly (-PathToAtomicsFolder)
  when running as root, since it defaults to $HOME/AtomicRedTeam which
  resolves to /root, not the user's clone location.

T1136.001: DETECTED (baseline ruleset)


## 2026-07-13 (session 2) — Baseline evaluation underway

- Lab recovered after downtime: linux-target agent had disconnected, restarted cleanly, all endpoints Active
- Installed PowerShell 7.6.3 + Invoke-AtomicRedTeam on linux-target (AllUsers scope so root can run elevation-required tests)
- Cloned atomics library to linux-target (~/AtomicRedTeam)
- T1136.001 executed and DETECTED (rule 5902, level 8) — baseline ruleset coverage. Terminal evidence captured.
- Set up evidence folder structure; deciding between terminal-only vs terminal+dashboard figures
- T1059.004 inspected (test 1, GUID 7e7ac3ed...), not yet executed — next session

### Method now established
Repeatable per-technique workflow: inspect test with -ShowDetails → set up 3-window
watch (alerts / audit telemetry / execution) → run → capture evidence → record result
category (baseline-detected vs captured-not-alerted vs undetected).

### Next session
- Run T1059.004-1, capture three-window evidence
- Continue through remaining techniques
- Decide terminal vs dashboard figure style

## 2026-07-13 (session 2 cont.) — T1059.004 evaluated: detection gap found

Executed T1059.004-1 (Create and Execute Bash Shell Script),
GUID 7e7ac3ed-f795-4fa5-b711-09d6fbe9b873.

Attack: created /tmp/art.sh, chmod +x, executed (printed message, pinged
8.8.8.8). Exit code 0.

RESULT: Captured, not alerted.
- Auditd captured the full chain at syscall level: chmod, sh execution,
  ping — all tagged process_creation by Neo23x0 rules, with complete
  process lineage (ppid/pid, AUID=jeffrey escalated to UID=root).
- Wazuh baseline ruleset generated NO security alert. Only level-3
  sudo/PAM noise from the operator's own commands appeared in alerts.log.

### Significance
Second result category established. Contrast with T1136.001:
- T1136.001: telemetry captured AND baseline-alerted (rule 5902, level 8)
- T1059.004: telemetry captured, NOT baseline-alerted

This demonstrates the gap between telemetry availability and alert
generation — the core justification for custom detection rule development
(Objective 4). A small team on default Wazuh would have this attack fully
logged but receive no notification. T1059.004 is a custom-rule candidate.

Evidence captured: attack execution, audit.log execve chain, absence of
security alert.

### Running coverage tally
- T1136.001 Create Account: BASELINE-DETECTED
- T1059.004 Unix Shell: CAPTURED-NOT-ALERTED (custom rule candidate)
---
