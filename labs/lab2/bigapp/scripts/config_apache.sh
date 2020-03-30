#!/bin/bash

# running php-fpm directly (not using systemd) does 
# not create the socket directory
mkdir -p /run/php-fpm
chmod 0755 /run/php-fpm
