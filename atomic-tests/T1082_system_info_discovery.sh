sudo mkdir -p /opt/custom-tests
sudo tee /opt/custom-tests/T1082_system_info_discovery.sh > /dev/null <<'EOF'
#!/bin/bash
# T1082 - System Information Discovery (custom test)
# ART has no Linux atomic for this technique.
uname -a
hostname
cat /etc/os-release
lscpu
df -h
free -m
id
EOF
sudo chmod +x /opt/custom-tests/T1082_system_info_discovery.sh
