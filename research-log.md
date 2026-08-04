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

## 2026-07-30 — Custom rule for cron persistence now works

Checked rule 100020 on the Wazuh manager. It turned out to be
already installed — my earlier note saying otherwise was wrong.

Ran the T1053.003 cron attack again on linux-target. This time
Wazuh raised a proper alert at level 10, with the description
"Cron persistence: file written to a cron directory".

This gives me a clear before-and-after:
- Before (default Wazuh): event was recorded but scored 0, so no alert
- After (my rule): event scored 10, alert raised
Nothing else changed — only the rule.

The logs captured the whole attack: a temporary file was created in
the cron folder and then renamed to become root's crontab. The command
that did it was `crontab /tmp/persistevil`.

Worth noting: one attack produced three separate alerts, because the
rule matches on the cron label and the attack touched three system
calls. Good to discuss later when I look at false positives and how
much noise an analyst would face. I haven't decided whether to tune it.

Small tidy-up for later: the rule is sitting in a section labelled for
SSH rules. It works, but it's in the wrong place.

Next: capture the T1059.004 screenshot, then continue with the
remaining seven techniques.

### T1059.004 — logtest evidence captured
Ran the atomic again and pulled the audit line into logtest on the manager.
Result: rule 80700, level 0. Wazuh decoded every field but raised no alert.
Gap confirmed and evidenced. Custom rule still to be written.

Note: the shell execution itself was hard to isolate in the audit log. The
detectable telemetry actually came from the child process the script spawned
(ping). Says something about how visible this technique really is at the
audit layer — worth a mention in the results chapter.

Also noticed: my own commands (grep, tail, sudo, ausearch) generate audit
events constantly, and they bury the attack events I'm looking for. That's
the background noise level on a monitored host before any custom rule exists.
Useful for the false-positive discussion.

### T1082 — no Linux test available
Atomic Red Team returned "Found 0 atomic tests applicable to linux platform".
So T1082 joins the list of techniques needing a custom test, alongside
T1110.001, T1098.004 and T1070.002. Four ART gaps now, not three.
No result recorded — nothing was tested, so it isn't a detection failure.

### T1070.003 — clearing bash history
First attempt failed: /root/.bash_history didn't exist, so there was nothing
to delete. Created the file, re-ran, and the test succeeded. Worth remembering
that some atomic tests assume state a clean lab doesn't have — a failed test
isn't always a detection gap.

My own Auditd watch caught it properly, recording both the file creation and
the deletion. Key is history_tamper (I'd wrongly assumed bash_history and got
a false negative until I checked with auditctl -l — always verify key names).

Wazuh's verdict: rule 80700, level 0, no alert. Same as the others.

This is the clearest gap I've documented so far. I wrote the audit rule
specifically to watch this file, it worked exactly as intended, the key came
through named in the decoder output, and Wazuh still stayed silent. The
sensor did its job; the SIEM didn't act on it.

One caution: alerts.log did show rule 5402 "Successful sudo to ROOT" matching
on the filename, but that's only because the path appeared in my sudo command
line. Not a detection. An attacker deleting the file without sudo would
produce nothing.

### Unexpected: false-positive evidence
While searching the audit log I found my own bash session had triggered the
history_tamper watch twice at 14:57, just from normally saving shell history.

So a Wazuh rule keyed naively on history_tamper would alert every time any
user closes a shell. Good to know before writing the rule rather than after —
the rule should key on deletion or truncation specifically (the rm command,
or the DELETE nametype) instead of any access to the file.

### Where things stand
Four techniques with results: T1136.001, T1059.004, T1053.003, T1070.003.
T1082 needs a custom test. Five still to baseline.

Next: continue baseline on remaining techniques, and write the custom rules
for T1059.004 and T1070.003.

## 2026-07-31 — Baseline evaluation complete (10/10)

Finished the baseline today. All ten techniques now have results.

### What ran

Checked what Atomic Red Team actually offers before running anything —
worth doing, because my earlier notes were wrong. T1110.001 and T1098.004
both have Linux tests after all. Only T1082 and T1070.002 genuinely needed
custom scripts, not four techniques as I'd assumed.

- T1098.004 (SSH authorized keys) — my ssh_key_change watch caught it.
  Wazuh: rule 80700, level 0.
- T1105 (download and run) — curl execution captured. Wazuh: 80700, level 0.
  Note: audit only sees curl running, not what was downloaded or from where.
- T1110.001 (sudo brute force) — DETECTED. Rules 5401 and 5503, level 5.
- T1078.003 (create local account) — DETECTED. Rules 5901 and 5902, level 8.
- T1082 (system info discovery) — custom script. Wazuh: 80700, level 0.
- T1070.002 (clear logs) — custom script. Wazuh: 80700, level 0.

### The main finding

Ten techniques, and the split is completely clean:

Three techniques reached Wazuh through journald. All three raised proper
alerts at levels 5-8, no custom rules needed.

Seven techniques reached Wazuh through Auditd. All seven ended at rule
80700, level 0, no alert. Every single one. Different tactics, different
syscalls, different keys — same result. It didn't matter whether the audit
rule came from the Neo23x0 set or whether I wrote it myself.

So this isn't seven separate gaps. It's one structural thing: Wazuh's
default rules don't act on Auditd telemetry at all beyond grouping it.
The sensors work fine. Nothing downstream uses what they produce.

That also changes how I describe my custom rules. They're not tuning
something that half works — they're supplying detection that isn't there.

### Things that nearly went wrong

Three atomic tests failed silently but still returned exit code 0:
- T1098.004 is wrapped in an `if [ -f ... ]` check
- T1078.003 refused because user 'art' already existed from the T1110.001
  test I'd run twenty minutes earlier
- T1070.003 yesterday, same pattern

Lesson: exit code 0 doesn't mean the test ran. I need to verify the attack
actually happened in the audit log before recording any result. Also need
to use -Cleanup between tests so they stop interfering with each other.

### Found old persistence still running

While looking at something else I spotted /bin/sh -c /tmp/evil.sh executing
as root every minute. Turned out root's crontab still had an entry from the
T1053.003 test, and /etc/cron.d/persistevil had been sitting there since
17 July — two weeks.

The cron persistence tests worked properly, in other words, and I never
cleaned up after them. Removed both. Captured evidence first.

This matters for two reasons. Anything I'd measured for false positives
before today would have been contaminated by root-level executions firing
every minute. And it shows the technique genuinely persists, which is worth
saying in the write-up.

### One result that needs care

T1070.002's truncate command did appear in an alert — rule 5402, level 3.
But 5402 is "Successful sudo to ROOT executed" and it fires for every sudo
command. Four other 5402 alerts in the same minute were just me running
ausearch and tail.

So the command string is in the log, but nothing identified it as log
tampering. An attacker already running as root would generate nothing at
all. Recording it as a gap, not a detection. Worth writing up properly —
an alert containing the attack isn't the same as an alert about the attack.

### Also worth noting

T1082 is a different kind of gap from the others. `uname` runs constantly
as normal system background activity — I saw several instances with no
terminal attached. A rule alerting on it would never stop firing. So Wazuh
staying quiet here might be the right call rather than a failure. Need to
distinguish that in the results chapter from the cases where silence is
genuinely a problem.

Audit IDs went from about 6,000 yesterday to 45,000 today. Roughly 39,000
audit events in a day on a lab VM doing almost nothing. That's the noise
level any detection rule has to work against.

### Where things stand

Objective 3 done — baseline complete for all ten techniques.

Next is Objective 4: custom rules for the seven gaps. Rule 100020 for cron
already proves the approach works. From the false positive I found yesterday,
I know not to key rules naively on the audit key alone — the history_tamper
rule needs to target deletion specifically, or it'll alert every time anyone
closes a shell.

## 2026-07-31 (afternoon) — First custom rules for the Auditd gaps

Started Objective 4. Rule 100020 for cron already worked, so today was
about writing rules for the other gaps and learning what the platform
will and won't let me express.

### Rule 100021 — history tampering (T1070.003)

Wrote this one deliberately differently from 100020. Rule 100020 matches
only on the audit key, which is why it fires three times for a single
cron attack — every syscall in the operation carries the same key.

100021 requires two things instead of one: the history_tamper key AND
the command being rm, truncate or shred.

```xml
<rule id="100021" level="10">
  <if_group>audit</if_group>
  <field name="audit.key">history_tamper</field>
  <field name="audit.command">^rm$|^truncate$|^shred$</field>
  <description>History tampering: shell history file deleted or truncated (T1070.003)</description>
  <mitre>
    <id>T1070.003</id>
  </mitre>
</rule>
```

The command condition exists because of the false positive I found
yesterday: normal bash writes to .bash_history every time a shell
closes, and that has audit.command = bash. Excluding it by design
rather than discovering it after deployment.

Deployed, restarted the manager, re-ran atomic test 1.

Result: fired at level 10, and importantly it fired ONCE, not three
times like 100020. The command filter did what it was meant to. Alert
carried full context — nametype=DELETE on /root/.bash_history, proctitle
decoding to `rm /root/.bash_history`.

Worth comparing the two rules directly in the results chapter. Same
technique class, one rule keyed naively on the audit key producing three
alerts per attack, the other filtered on command producing one. Evidence
that rule design affects analyst workload, measured rather than asserted.

### Testing the rule's limits — and finding them

Then ran atomic test 3, which clears history a different way:

    cat /dev/null > ~/.bash_history

No alert. That's correct behaviour, not a failure, and it's worth
explaining properly because it took me a while to understand.

The `>` is the shell redirecting output. The shell opens the file and
empties it — cat just supplies nothing to write. So Auditd records the
command as bash, not cat. My rule requires rm/truncate/shred, so it
declines to match.

Which means an attacker who avoids the obvious commands walks straight
past this rule. Four of the ten atomic tests for T1070.003 use methods
100021 won't catch.

I'd rather document that than claim the technique is covered. Saying
"T1070.003 detected" would be exactly the overclaim Virkud et al. (2024)
criticise — coverage at technique level concealing which procedures are
actually detected.

### Options considered for closing that gap

Looked at three ways to catch the redirection variant:

**File Integrity Monitoring (syscheck).** Watches the file for changes
in size, hash and mtime regardless of how the change happened. This is
the architecturally right answer — it watches the outcome, not the
method. Not implemented yet; FIM on a home directory may be noisy and
needs testing before I commit to it.

**Match the truncation at syscall level.** When the shell does `> file`
it opens with the O_TRUNC flag, and that flag IS present in the raw
audit record (the a2 value). But Wazuh's auditd decoder doesn't expose
a0-a3 as fields — I can see this in my own logtest Phase 2 output, which
shows audit.syscall and audit.command but no argument registers. So the
flag never reaches the rule engine. Dead end without writing a custom
decoder, which is out of scope.

**Low-level rule plus correlation.** A second rule matching
history_tamper with comm=bash at level 0-3 — wouldn't alert alone but
would be available for frequency or correlation rules. Possible later.

Not implementing any of these for now. Recording the limitation.

### The bigger question this raised

Realised something uncomfortable while writing 100021. Chapter 2 argues
that behavioural detection is better than signature matching. But my
rule matches on a list of command strings — change the string, evade the
rule. Mechanically that is signature matching, just of commands rather
than file hashes.

Thought about it and I don't think the Chapter 2 argument is wrong, but
it needs qualifying. Detection sits on a spectrum rather than in two
boxes:

- artefact signature (this exact file hash)
- command indicator (this command touching this class of file) — where
  100021 sits
- behavioural (this outcome occurred, whatever the method) — FIM
- anomaly (this deviates from normal for this host)

100021 is more general than a hash: it doesn't care which user, which
session, which path, or what the file contained. But it's less general
than true behavioural detection.

The useful point for the dissertation is the reason WHY it sits there.
It isn't laziness — it's that Wazuh's auditd decoder doesn't expose the
fields needed to express "the file was emptied" as a rule condition.
Only "these commands ran" can be written.

So there's a gap between what ATT&CK asks defenders to do (detect
behaviours) and what an open-source SIEM's telemetry and rule syntax
actually permit. That's an implementation gap, evidenced from my own
lab, and it's a stronger contribution than claiming I did behavioural
detection and hoping nobody checks.

### Tracker updates

T1070.003: Custom Rule ID 100021, Deployed Yes, Post-Rule Result
"Detected by custom rule", Post-Rule Level 10.

### Next

Six custom rules still to write. T1098.004 is the easiest — any write to
authorized_keys is suspicious, so it needs no command filter and should
be a clean single-condition rule.

2026-08-04 — Cowrie protocol-layer detection working (multi-layer proven)

Went back to the honeypot today because I realised Cowrie and the Kali attacker VM had barely been used — all ten baseline techniques were run on the target directly, so the protocol layer of the architecture had no results behind it. That's a problem, because the whole premise of the dissertation is detection across two telemetry layers, not one.

The old problem, finally explained

I remembered Cowrie "not working" before — you'd SSH in, enter a password, and it would hang with a blank screen. Turns out that's the emulated shell failing to load, not a logging failure. Kali runs OpenSSH 10.0, and Cowrie's fake interactive shell doesn't render properly for modern clients.

But that doesn't matter for detection. The events my rules watch for — connection, failed login, successful login — are all logged by Cowrie the moment they happen, before the shell ever loads. So the hang is cosmetic as far as the results are concerned. Worth stating clearly in the write-up: protocol-layer detection is fully functional; only post-login command emulation is degraded, and none of my rules depend on it.

What I ran

Confirmed Cowrie was up (docker container, port 2222) and that the Wazuh agent forwards /opt/cowrie/var/log/cowrie/cowrie.json. Honeypot is at 192.168.56.30, attacker (Kali) at 192.168.56.40.

From Kali, SSH'd into the honeypot with root/wrongpass. Checked the Cowrie JSON log — the whole session was captured: client version, key exchange with SSH fingerprint, and the login event.

Results — both rules fired

On the manager:

Rule 100013 (level 5) — new SSH connection from 192.168.56.40, logged the instant the connection opened
Rule 100012 (level 10) — successful root login, captured username, password, and source IP

So I now have real detection results at the protocol layer, sitting alongside the ten host-layer results. The multi-layer architecture is demonstrated, not just described. Cowrie and Kali have earned their place.

The finding worth drawing out

Same story on both layers. My custom Cowrie rules fired at levels 5 and 10 because I wrote them. My custom Auditd rules produced level 0 under the default config until I wrote rules for those too. In both cases the raw telemetry was fine and the default platform did nothing useful with it — detection came only from rules I authored. Open-source SIEM supplies the pipeline; the detection engineering is the contribution. That holds across both telemetry layers, which strengthens the argument rather than complicating it.

Two honest caveats

Cowrie accepted root/wrongpass as a SUCCESS. Its default userdb accepts almost any password for root, so rule 100012 (success) and 100013 (connect) fire readily, but generating a genuine FAILED login for rule 100011 needs userdb configuration. Either configure it or note as future work.

The lab isn't as isolated as the methodology currently claims. The honeypot VM has two interfaces — 192.168.56.30 on VMnet2 (the lab network) and 192.168.138.153 on a DHCP subnet with internet access. That second interface is why the target could reach 8.8.8.8 earlier. Need to describe the network accurately: isolated on one interface, internet-reachable on another, rather than fully air-gapped.

Evidence

results/cowrie/cowrie_01_login-success-and-connect_alerts.png

Next

Back to the Results chapter. Section 4.1 (baseline) drafted. The Cowrie result gives 4.2 or a dedicated protocol-layer subsection real material.
---

