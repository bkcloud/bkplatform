#!/bin/bash

#Install some software
#Install jre
rpm -ivh /Cassandra/jre*

#Install jna: has been store in /Cassandra/lib/jna.jar. Don't need install

#Make directory for Cassandra
mkdir /var/lib/cassandra
mkdir /var/log/cassandra

ip=$(ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')
seeds=$1
#Config cassandra.yaml
sed -i -e '/listen_address:/ c\listen_address: '"$ip" -e '/rpc_address:/ c\rpc_address: '"$ip" /Cassandra/conf/cassandra.yaml
sed -i  s/127.0.0.1/$seeds/ /Cassandra/conf/cassandra.yaml

#Config cassandra-env.sh
sed -i '/rmi.server/ c\JVM_OPTS="$JVM_OPTS -Djava.rmi.server.hostname='"$ip"'"' /Cassandra/conf/cassandra-env.sh

#Config hostname
name=$(hostname)
sed -i '/127.0.0.1/ s/$/ '$name'/' /etc/hosts

#Config firewall
sed -i "11i -A INPUT -m state --state NEW -m tcp -p tcp --dport 1024:65535 -j ACCEPT" /etc/sysconfig/iptables
service iptables restart

#Config auth in cassanddra.yaml
sed -i -e '/authenticator: AllowAllAuthenticator/ c\authenticator: PasswordAuthenticator' -e '/authorizer: AllowAllAuthorizer/ c\authorizer: CassandraAuthorizer' /Cassandra/conf/cassandra.yaml

#Tuning Cassandra
#Config /etc/security/limits.conf
printf "* - memlock unlimited\n* - nofile 100000\n* - nproc 32768\n* - as unlimited" >> /etc/security/limits.conf

#Config /etc/security/limits.d/90-nproc.conf
echo "* - nproc 32768" >> /etc/security/limits.d/90-nproc.conf

#Config /etc/sysctl.conf
echo "vm.max_map_count = 131072" >> /etc/sysctl.conf
sysctl -p
