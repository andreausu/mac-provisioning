#!/bin/bash

set -ex

IPADDR=`ipconfig getifaddr en0 | tr -d '\n'`

sudo sed -E -i '' 's/("\/Users\/andrea\/Development\/[a-z]+" -alldirs -mapall=50[0-9]:20) 192\.168\.1\.[0-9]+/\1 '"$IPADDR"'/g' /etc/exports

#cat /etc/exports | sed -E -e 's/"(\/Users\/andrea\/Development\/[a-z]+" -alldirs -mapall=50[0-9]:20) 192\.168\.1\.[0-9]+/\1 '"$IPADDR"'/g'

sudo nfsd restart && sudo nfsd checkexports

docker-machine ssh dev "sudo sed -E -i 's/(sudo mount) 192.168.1.[0-9]+:/\1 '"$IPADDR":'/g' /var/lib/boot2docker/bootlocal.sh"

docker-machine ssh dev "sudo /bin/sh /var/lib/boot2docker/bootlocal.sh"
