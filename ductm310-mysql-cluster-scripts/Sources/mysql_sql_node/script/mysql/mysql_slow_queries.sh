#!/bin/bash

echo SHOW GLOBAL STATUS| /usr/local/mysql-cluster/bin/mysql -u$1 -p$2 |grep "^Slow_queries\s"|awk '{print $2}'
