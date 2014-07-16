#!/bin/bash
echo SHOW GLOBAL STATUS| /usr/local/mysql-cluster/bin/mysql -u$1 -p$2 |grep "^Ndb_number_of_ready_data_nodes\s"|awk '{print $2}'
