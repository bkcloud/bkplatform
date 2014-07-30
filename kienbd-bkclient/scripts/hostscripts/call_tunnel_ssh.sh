#!/bin/bash

instance_name=$1
host_ip_address=$2

# scp change_vnc_to_spice.sh root@$host_ip_address:/scripts/
ssh -2 -p 22 root@$host_ip_address /scripts/change_vnc_to_spice.sh $instance_name $host_ip_address

