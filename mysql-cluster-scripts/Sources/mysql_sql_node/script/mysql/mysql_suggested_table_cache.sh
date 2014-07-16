#!/bin/bash

a=$(/usr/local/mysql-cluster/bin/mysqladmin -u$1 -p$2 variables|grep 'max_connections'|awk '{print $4}')
b=256
echo $(($a>$b?$a:$b))
