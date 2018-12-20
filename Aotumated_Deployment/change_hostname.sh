#!/bin/bash
# Change hostname in batches.
# Create By Luqm@alongtech.com.
# Date: 2018/12/18.


# Must defined variable "hostname=xxx" in inventory first.

ansible -i inventory all -m hostname -a 'name={{ hostname }}' >/dev/null 2>&1

#ansible -i inventory all -m debug -a 'msg={{ inventory_hostname }}'
ansible -i inventory all -m setup -a 'filter=ansible_fqdn'


