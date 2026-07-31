sudo tee /opt/custom-tests/T1070_002_clear_logs.sh > /dev/null <<'EOF'
#!/bin/bash
# T1070.002 - Indicator Removal: Clear Linux Logs (custom test)
# Uses a decoy log to avoid destroying live telemetry.
echo "test log entry $(date)" | sudo tee /var/log/lab-test.log > /dev/null
sudo rm -f /var/log/lab-test.log
sudo truncate -s 0 /var/log/wtmp
EOF
sudo chmod +x /opt/custom-tests/T1070_002_clear_logs.sh
