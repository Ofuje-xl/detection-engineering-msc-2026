# Detection Rules

Custom detection content developed for the dissertation *Evaluating ATT&CK-Based
Detection Engineering for Linux Systems Using Cowrie, Auditd, and Wazuh Telemetry*.

Each rule exists in two forms. The Sigma rule in `sigma/` expresses the detection
logic in a vendor-neutral format. The Wazuh rule in `wazuh/` is the platform-specific
implementation deployed to the manager. Authoring in Sigma before translating keeps
the detection content portable rather than tied to this deployment.

## Why these rules exist

Baseline evaluation of ten ATT&CK techniques found that every technique observed
through the Linux Auditing System was decoded correctly by Wazuh 4.13 and then
scored at level 0 under rule 80700 ("Audit: Messages grouped"), producing no alert.
The telemetry was present and complete; no technique-specific detection logic
existed to act on it. These rules supply that logic.

## Rules

| ATT&CK | Rule ID | Level | Detects |
|---|---|---|---|
| T1053.003 Scheduled Task/Job: Cron | 100020 | 10 | File written to a cron directory |
| T1070.003 Indicator Removal: Clear Command History | 100021 | 10 | Shell history file deleted or truncated |

### Design note

The two rules differ deliberately in how narrowly they match.

Rule 100020 matches on the audit key alone. It detects reliably but fires once per
system call, producing three alerts for a single cron persistence action.

Rule 100021 requires the audit key **and** a destructive command. This prevents the
multiplication seen in 100020, and excludes the false positive observed at baseline,
where the same audit key is recorded whenever a shell writes to its history file
during normal operation.

### Known limitation

Rule 100021 does not detect redirection-based history clearing
(`cat /dev/null > ~/.bash_history`), because the shell performs the write and the
event records the shell as the command rather than a deletion command. Four of the
ten Atomic Red Team tests for this technique use methods the rule does not match.
The behaviour "the file was emptied" cannot be expressed as a rule condition on this
platform, as the relevant syscall flag is not exposed by Wazuh's auditd decoder.

## Deployment

Rules are deployed to `/var/ossec/etc/rules/local_rules.xml` on the Wazuh manager.
The manager requires a restart before a newly added rule takes effect.

## Status

Both rules are marked `experimental`: validated in the project laboratory, not
tested in production.
