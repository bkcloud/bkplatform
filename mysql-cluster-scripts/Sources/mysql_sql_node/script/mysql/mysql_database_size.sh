#!/bin/bash

/usr/local/mysql-cluster/bin/mysqlshow -u $1 -p$2 --status $3 | cut -d\| -f 8,10 -s --output-delimiter="|" | awk -F"|" '{ total = total+$1+$2 } END {print total}'
