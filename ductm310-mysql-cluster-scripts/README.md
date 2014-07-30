# Scripts for Dba

## How to install?

### Requirement
* CentOS. Tested with CentOS 6.5 Final.
* python and all required libarary is installed: paramiko, pyzabbix, cloudmonkey.
* Zabbix server and zabbix agent is ready. See Zabbix Manual for more information.
* MySQL Cluster installed.

### Install
1. Configure API and secret key of CloudStack, zabbix server address, zabbix port, password used for ssh for every scripts in folder __Sources__

2. Copy every file and folders in __Sources__ to corresponding node.

> Zabbix Server folder --> Zabbix Server
> HAProxy --> HAProxy server
> mysql_management_node --> MySQL Cluster management node
> mysql_data_node --> MySQL Cluster data node
> mysql_sql_node --> MySQL Cluster SQL node

3. Import MySQL template to Zabbix Server. File: __zbx_export_templates__

4. Create action in Zabbix Server.

> Action 1: Do when MySQL SQL Overload
> Condition:
> Maintenance status not in maintenance
> Trigger value = PROBLEM
> Trigger name like SQL Overload
> Operations:
> Run remote commands on current host, start immediately
> Execute on Zabbix Server
> Commands: sudo python /script/create_host.py sql

> Action 2: Do when MySQL SQL too low
> Condition:
> Maintenance status not in maintenance
> Trigger value = PROBLEM
> Trigger name like SQL too low
> Operations:
> Run remote commands on current host, start immediately
> Execute on Zabbix Server
> Commands: sudo python /script/delete_host.py sql {ITEM.LASTVALUE4} {ITEM.LASTVALUE2}

## Note
* folder __zombile__: scripts to flood mysql server for testing.
* zabbix scripts: scripts for monitoring controller, but not yet implemented.

###LICENSE
    /* This Source Code Form is subject to the terms of the Mozilla Public
    * License, v. 2.0. If a copy of the MPL was not distributed with this
    * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

