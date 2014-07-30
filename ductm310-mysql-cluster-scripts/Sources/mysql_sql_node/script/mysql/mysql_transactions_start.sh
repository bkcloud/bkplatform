#!/bin/bash

echo SHOW GLOBAL STATUS| /usr/local/mysql-cluster/bin/mysql -u$1 -p$2 |grep "^Ndb_api_trans_start_count\s"|awk '{print $2}'
