#!/bin/bash


echo SHOW GLOBAL STATUS| /usr/local/mysql-cluster/bin/mysql -u$1 -p$2 |grep "^Threads_running\s"|awk '{print $2}'
