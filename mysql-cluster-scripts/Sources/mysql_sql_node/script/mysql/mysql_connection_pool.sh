#!/bin/bash
echo SHOW GLOBAL VARIABLES| /usr/local/mysql-cluster/bin/mysql -u$1 -p$2 |grep "^ndb_cluster_connection_pool\s"|awk '{print $2}'
