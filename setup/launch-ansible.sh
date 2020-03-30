#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
subscription-manager register --auto-attach
subscription-manager repos \
    --enable=ansible-2-for-rhel-8-x86_64-rpms
yum install -y ansible
ansible-playbook -i "localhost," -c local $DIR/ansible/main.yml 
