#!/bin/bash

/usr/local/mysql-cluster/bin/mysql -N -B -u $1 -p$2 -e "select count(table_name) as Frag from information_schema.tables where table_schema not in ('information_schema','mysql') and data_free > 10000"

