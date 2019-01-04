#!/bin/bash
# Working with the ansible playbook - hosts_ping_check.yml

# User Input:
IPADDRS="192.168.100.135 192.168.100.174 192.168.100.175"
USERNAME="root"
PASSWORD="password"

# Replace the username and password user input.
sed -i "s/ansible_ssh_user: *.*/ansible_ssh_user: $USERNAME/g" hosts_ping_check.yml
sed -i "s/ansible_ssh_pass: *.*/ansible_ssh_pass: $PASSWORD/g" hosts_ping_check.yml

# Create Log Directory.
LOG_DIR=/var/log/along
mkdir -p $LOG_DIR

# Get current timestamp.
c_time=$(date +%s)
LOG_FILE=$LOG_DIR/host_ping_check.log.$c_time

# Using command "Ping" to check if the network is connected.
for ip in $IPADDRS; do
    ping -c 1 -W 1 $ip | grep -q 'ttl=' && echo "$ip OK" || echo "$ip Failed"
done >$LOG_FILE 2>&1

grep "Failed" $LOG_FILE > /dev/null
if [ $? -eq 0 ]; then
    cat $LOG_FILE
    # -----------------------------------------------------+
    # Output Format:                                       |
    # 192.168.100.135  OK                                  |
    # 192.168.100.136  Failed                              |
    # 192.168.100.137  OK                                  |
    # -----------------------------------------------------+
    exit 1
else
    # Using ansible model "ping" to check if the username and password is right.
    # cat $LOG_FILE
    echo "[Ansible PING]"
    export ANSIBLE_HOST_KEY_CHECKING=False
    ansible-playbook hosts_ping_check.yml
    # ----------------------------------------------------------+
    # Output Format:                                            |
    # PLAY RECAP *********************************************  |
    # hdp-1   : ok=1    changed=0    unreachable=1    failed=0  |  
    # hdp-2   : ok=0    changed=0    unreachable=1    failed=0  | 
    # hdp-3   : ok=1    changed=0    unreachable=1    failed=0  |
    # ----------------------------------------------------------+
fi



