#!/bin/bash
# Add host_vars "hostname=xxx" into inventory.
# Created By Luqm@alongtech.com.
# Date: 2018/12/18.

DOMAIN='luqm.local'
HOSTNAMES=(name1 name2 name3)
INVENTORY=inventory

# Compare the number of HOSTNAMEs you input to that defined in INVENTORY.
# len=${#HOSTNAMES[@]}
if [ ${#HOSTNAMES[@]} -eq $(cat $INVENTORY | grep ansible_host | grep -v ^'#' | wc -l) ]
then

    n=0
    cat $INVENTORY | grep ansible_host | grep -v ^'#' | while read line 
    do
        # Get the line number of current line.
        line_num=$(grep -n "$line" $INVENTORY | cut -d ":" -f1)

        # Defined the new line for added strings "hostname=$fqdn".
        new_line=${line}' hostname='${HOSTNAMES[$n]}'.'${DOMAIN}

        # Replace the new line.
        sed -i "${line_num}c ${new_line}" $INVENTORY
        let n+=1
    done
    # cat $INVENTORY
    echo "SUCCESS: DONE."

else
    echo "ERROR: The number of hostname you inputed is not equal to the number of hosts defined in the inventory."
    echo "   >>: Please Check."

fi