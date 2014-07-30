#!/bin/bash

/usr/local/mysql-cluster/bin/mysqladmin -u$1 -p$2 ping | grep -c alive
