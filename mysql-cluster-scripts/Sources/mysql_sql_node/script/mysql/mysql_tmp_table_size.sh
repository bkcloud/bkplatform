#!/bin/bash


/usr/local/mysql-cluster/bin/mysqladmin -u$1 -p$2 variables|grep 'tmp_table_size'|awk '{print $4}'
