#!/bin/bash


echo SHOW GLOBAL STATUS| /usr/local/mysql-cluster/bin/mysql -u$1 -p$2 |grep "^Com_show_tables\s"|awk '{print $2}'
