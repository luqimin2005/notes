#!/bin/bash
# Configurate SSH EASY Non-interactively.
# Create By Luqm@alongtech.com.
# Date: 2018/12/18.

HOST_PREFIX='ansible_host'
HOSTS=inventory
PASSWORD='password'

# Use ssh-keygen to generating the key pairs.
# Overwrite the key pairs even if existed.
echo "yes" | ssh-keygen -q -t rsa -P "" -f ~/.ssh/id_rsa >/dev/null 2>&1
echo "Public and private key pairs have been generated."

# Use ssh-copy-id to copy the Public key to everyhost in the inventory.
for HOST in $(cat ${HOSTS} | grep ${HOST_PREFIX} | grep -v ^'#' | cut -d ' ' -f2 | cut -d '=' -f2)
do 
  sshpass -p $PASSWORD ssh-copy-id root@$HOST -o stricthostkeychecking=no >/dev/null 2>&1

  if [ $? -eq 0 ]
  then
    echo "SUCCESS: Public key has been copied to ${HOST^^}."
  else
    echo "ERROR: password wrong or host unreachable."
  fi

done
