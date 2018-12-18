#!/bin/bash
# Change hostname in batches.
# Created By Luqm@alongtech.com.
# Date: 2018/12/18.

INVENTORY=inventory

# Must defined variable "hostname=xxx" in inventory first.
# Please refer to the script "add_hostname_inventory.sh".

ansible -i $INVENTORY all -m hostname -a 'name={{ hostname }}'

