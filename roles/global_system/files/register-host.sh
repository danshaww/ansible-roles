#!/bin/bash

# Script to register current machine in DNS via nsupdate

# Variables
ttl="3600"
domain="epichouse.co.uk."
ip=$(hostname -I | cut -d' ' -f1 )
reverse=$(hostname -I | cut -d' ' -f1 | awk -F. '{print $4"."$3"." $2"."$1}')
a="$(hostname).$domain"
ptr="$reverse.in-addr.arpa."

# nsupdate execution
printf "update delete $a\n send" | nsupdate >> /dev/null
printf "update delete $ptr\n send" | nsupdate >> /dev/null
printf "update add $a $ttl A $ip\n send" | nsupdate
printf "update add $ptr $ttl PTR $a \n send" | nsupdate