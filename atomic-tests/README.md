# Custom Atomic Tests

This directory contains project-developed test scripts used to execute Linux ATT&CK behaviours where suitable Atomic Red Team tests were not available for the evaluation.

Most attack procedures in the study were executed using the external Atomic Red Team framework. Atomic Red Team is maintained by Red Canary and is available from:

https://github.com/redcanaryco/atomic-red-team

The scripts in this directory are original project artefacts and are not copies of Atomic Red Team tests.

## Custom Tests

### T1082 — System Information Discovery

`T1082_system_info_discovery.sh`

Runs standard host-reconnaissance commands including `uname`, `hostname`, `os-release`, `lscpu`, `df`, `free`, and `id` to reproduce system-information discovery behaviour.

### T1070.002 — Clear Linux or Mac System Logs

`T1070_002_clear_logs.sh`

Creates and removes a decoy log file and truncates `wtmp`. A decoy file is used where appropriate to avoid unnecessarily destroying telemetry required by the evaluation.

## Usage

Run the required script on the instrumented Ubuntu target with Auditd active.

For example:

```bash
sudo ./T1082_system_info_discovery.sh
