#!/bin/bash
sed -i '/^.*# MYSQL START/,/^.*# MYSQL END/{/^.*#/!{/^\$/!d}}' /etc/haproxy/haproxy.cfg 
for i in $@
do
	sed -i "/^.*# MYSQL START/a\ \ \ \ server\t${i} ${i}:3306 check" /etc/haproxy/haproxy.cfg
done
service haproxy reload