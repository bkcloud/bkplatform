Cassandra is a highly scalable, eventually consistent, distributed, structured 
key-value store. 

Project description
-------------------
My project include some scripts to add, remove, reset node Cassandra on CloudStack. You can
use with Zabbix server to auto add, remove, reset node for Cassandra cluster.

For more information see http://cassandra.apache.org/

Requirements
------------
- CloudStack
- Zabbix
- To run scripts you must have Python with
  + cloudmonkey
  + pyzabbix
  https://github.com/lukecyca/pyzabbix/wiki
  + paramiko
  http://www.paramiko.org/

Getting started
---------------
- Make a template CentOS do not use swap and have installed ntp in CloudStack
- Place project in /Cassandra
- Config something in scripts such as CloudStack's ip address, apikey, secretkey, Zabbix's ip address, etc ...
- Run /Cassandra/scripts/AddVM.py several times to make some new nodes.
- Run /Cassandra/scripts/RemoveVM.py if you want to remove node.
- Run /Cassandra/scripts/ResetVM.py CAS-* if you want to reset a node.
- You can place project in /Cassandra at Zabbix server and config something in Zabbix to auto add, remove, reset node Cassandra.

Update
----------------
You can update Cassandra, Oracle Jre by downloading and placing them to the project.
After updating Cassandra, you shoud download jna, rename to jna.jar and place it to /Cassandra/lib
* Do not remove scripts directory and configCassandra.sh.
