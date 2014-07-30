#!/bin/bash


echo SHOW GLOBAL STATUS| /usr/local/mysql-cluster/bin/mysql -u$1 -p$2 |grep "^Bytes_sent\s"|awk '{print $2}'
