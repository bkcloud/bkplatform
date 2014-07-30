#!/bin/bash

instance_name=$1
host_ip_address=$2

tmp_dir="/tmp/change_vm_setting"
cur_dir=`pwd`

# make temporary directory contain vm_setting.xml
mkdir -p $tmp_dir
cd $tmp_dir

virsh dumpxml $instance_name > $instance_name.xml
cp $instance_name.xml $instance_name.xml.bak

sed -i "s/type='vnc'/type='spice'/" $instance_name.xml
sed -i "s/type='cirrus'/type='qxl'/" $instance_name.xml

if ! cmp $instance_name.xml $instance_name.xml.bak >/dev/null 2>/dev/null
then
    virsh destroy $instance_name 1>/dev/null 2>/dev/null
    virsh create $instance_name.xml 1>/dev/null 2>/dev/null
fi

# re-check
virsh dumpxml $instance_name > $instance_name.xml

isspice=`grep -o -e "spice" $instance_name.xml`
port=`egrep -e spice $instance_name.xml| egrep -e "59[0-9][0-9]" -o`

if [ -z $isspice -o -z $port ]
then
    echo "{\"status\": \"ERROR\", \"message\": \"Cannot change vnc to spice\"}"
else
    echo "{\"status\": \"OK\", \"message\": [\"$host_ip_address\", \"$port\"]}"
fi


rm $instance_name.xml $instance_name.xml.bak
#rm -r $tmp_dir
cd $cur_dir