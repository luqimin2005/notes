#!/bin/bash


export ANSIBLE_HOST_KEY_CHECKING=False
ansible-playbook hosts_env_check.yml --tags=$1

# Args Input:
#   all                :  Run all the requried services checking.
#   firewalld_checking :  Run firewalld service status checking only.
#   selinux_checking   :  Run selinux status checking only.
#   timedate_checking  :  Run ntp service & ntp state checking only.
#   jdk_checking       :  Run jdk version checking only.
#   thp_checking       :  Run THP checking only.