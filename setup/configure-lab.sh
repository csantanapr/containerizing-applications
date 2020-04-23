#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
sudo subscription-manager register --auto-attach
sudo subscription-manager repos \
    --enable=ansible-2-for-rhel-8-x86_64-rpms
sudo yum install -y ansible git
git clone https://gitlab.com/2020-summit-labs/containerizing-applications \
    $DIR/containerizing-applications
ansible-playbook -i "localhost," -K -c local \
    $DIR/containerizing-applications/setup/ansible/main.yml 
