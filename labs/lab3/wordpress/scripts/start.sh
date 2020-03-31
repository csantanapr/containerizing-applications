#!/bin/bash
set -eux

MYDIR=$(dirname $0)

# Perform configurations
$MYDIR/config_wordpress.sh

# Start the fpm server
/usr/sbin/php-fpm

# Start apache in the foreground
/usr/sbin/httpd -D FOREGROUND
