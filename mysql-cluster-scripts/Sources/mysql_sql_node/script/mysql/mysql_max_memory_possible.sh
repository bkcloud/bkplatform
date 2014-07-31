#!/bin/bash


echo SHOW GLOBAL VARIABLES| /usr/local/mysql-cluster/bin/mysql -u$1 -p$2 > /tmp/mysql_variables
innodb_buffer_pool_size=$(cat /tmp/mysql_variables|grep innodb_buffer_pool_size| awk '{print $2}')
key_buffer_size=$(cat /tmp/mysql_variables|grep key_buffer_size| awk '{print $2}')
sort_buffer_size=$(cat /tmp/mysql_variables|grep "^sort_buffer_size"| awk '{print $2}')
read_buffer_size=$(cat /tmp/mysql_variables|grep "^read_buffer_size"| awk '{print $2}')
binlog_cache_size=$(cat /tmp/mysql_variables|grep "^binlog_cache_size"| awk '{print $2}')
max_connections=$(cat /tmp/mysql_variables|grep max_connections| awk '{print $2}')
size=$(echo $sort_buffer_size + $read_buffer_size + $binlog_cache_size|bc)
echo $innodb_buffer_pool_size+$key_buffer_size+$max_connections*$size+$max_connections*2*1024*1024|bc
