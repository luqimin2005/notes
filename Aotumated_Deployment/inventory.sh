#!/bin/bash
# Determine the current working directory "PWD",
# And transport it to the inventory_vars.yml.
# inventory_var.yml provides IP_ADDRESSES, ADMIN_USERNAME, PWD and etc. 
# inventory.j2 is the template to generate the inventory file.
# inventory.yml import the inventory_vars and generate inventory file finally.
# Exec: ansible-playbook inventory.yml
# Created By Luqm@alongtech.com.
# Date: 2018/12/18.

echo '' > inventory

INVENTORY_VARS=inventory_vars.yml

# Get the current working directory.
PWD=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)

# Determine whether current_dir is exists or not. 
grep current_dir $INVENTORY_VARS >/dev/null

if [ $? -eq 0 ]
then
  # If current_dir is exists, replace it. 
  sed -i "/^current_dir/c current_dir: $PWD" $INVENTORY_VARS
else
  # If current_dir is not exists, add it into inventory_vars.yml. 
  echo "current_dir: $PWD" >> $INVENTORY_VARS
fi  

ansible-playbook -i inventory inventory.yml
