#!/bin/bash
echo SHOW GLOBAL STATUS| /usr/local/mysql-cluster/bin/mysql -u$1 -p$2 |grep "^Ndb_config_from_port\s"|awk '{print $2}'
