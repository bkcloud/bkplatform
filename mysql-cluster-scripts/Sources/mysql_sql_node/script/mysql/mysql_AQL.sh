#!/bin/bash
echo SHOW GLOBAL VARIABLES| /usr/local/mysql-cluster/bin/mysql -u$1 -p$2 |grep "^ndb_join_pushdown\s"|awk '{print $2}'
