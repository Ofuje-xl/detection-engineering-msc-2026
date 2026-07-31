# Custom Atomic Tests

Atomic Red Team provides no Linux tests for some techniques in this
evaluation. These scripts fill those gaps so every targeted technique
can be executed reproducibly.

## Tests

**T1082_system_info_discovery.sh** — System Information Discovery.
Runs standard host reconnaissance commands (uname, hostname, os-release,
lscpu, df, free, id) as an attacker would after gaining access.

**T1070_002_clear_logs.sh** — Clear Linux Logs. Creates and removes a
decoy log file, and truncates wtmp. Uses a decoy rather than live system
logs to avoid destroying the telemetry the evaluation depends on.

## Usage

    sudo ./T1082_system_info_discovery.sh

Run on the target host with Auditd active. Verify execution in the audit
log before recording any detection result — exit code alone is not
sufficient evidence a test ran.
