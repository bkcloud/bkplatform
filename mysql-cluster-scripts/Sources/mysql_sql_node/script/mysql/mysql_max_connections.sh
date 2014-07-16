#!/bin/bash

/usr/local/mysql-cluster/bin/mysqladmin -u$1 -p$2 variables|grep 'max_connections'|awk '{print $4}'
