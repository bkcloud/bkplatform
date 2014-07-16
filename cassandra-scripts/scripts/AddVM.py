from pyzabbix import ZabbixAPI
import subprocess
import os
import sys
import json
import paramiko
import re
import time
from datetime import datetime, timedelta

#define cloudmonkey function
def cloudmonkey(argv):
    cmd = "cloudmonkey " + argv
    try:
        rs = subprocess.Popen([cmd], stdout=subprocess.PIPE, shell=True).communicate()[0] 
        i = 0
        while i < len(rs) and rs[i] != '{':
            i += 1
        return json.loads(rs[i:])
    except ValueError:
        return rs

#define check vm is booted function
def isBooted(ipAddress):
    count = 40
    while True:
        ret = os.system("ping -c 15 %s" % ipAddress)
        count -= 1
        if ret == 0: return True
        elif count <= 0: break
        time.sleep(3)
    return False

#Check argument
if len(sys.argv) == 1:
	print "Please enter argument"
	exit(1)

if sys.argv[1] != 'CAS-1':
	print "Don't add node"
	exit(1)

#set some info about vm
cloudstackServiceofferingid="57a97443-d9dd-4856-ba4a-ba7a7b769f89" #Medium instance 1gbps
cloudstackTemplateid = "45403fb3-15de-4227-88d4-fbb8c2a16fd6" #Template Cassandra
cloudstackZoneid="c70a4033-3a72-4900-8aa3-8f1bee765d4b" #BKZone-1

#Set up enviroment for cloudmonkey
cloudmonkey("set host 192.168.50.11")
cloudmonkey("set port 8080")
cloudmonkey("set apikey I7_wlxR3IRfF7YSfh4PdnH22nynyTdBwdMrGd0M-vph6r9I3cUtpq1WICV-hfYZmBrMbVD6ZXdNFzZfGigt7IA")
cloudmonkey("set secretkey zhH8Adqc7Sh33G1YrGg41k51T2qiLuxQjjdlSi0gr65nVGMV_68pcLUWFKke7VplLYD3I-ZGppuRwwWgHPMJOw")
cloudmonkey("set asyncblock true")
cloudmonkey("set color false")
cloudmonkey("set display json")
cloudmonkey("sync")

#Connect Zabbix server
zapi = ZabbixAPI("http://192.168.50.74/zabbix")
zapi.login("Admin", "zabbix")
print "Connected to Zabbix API Version %s" % zapi.api_version()

#Create name for new node
zabbixGroupid = zapi.hostgroup.get(filter = {"name":"Cassandra"})[0]['groupid']
numberNode = zapi.host.get(groupids = zabbixGroupid, countOutput = 1)
nodeName = 'CAS-' + str(int(numberNode) + 1)
print nodeName

#Deploy new node
newNode = cloudmonkey("deploy virtualmachine serviceofferingid=%s templateid=%s zoneid=%s name=%s displayname=%s" % (cloudstackServiceofferingid, cloudstackTemplateid, cloudstackZoneid, nodeName, nodeName))
if newNode['jobstatus'] == 2:
	result = cloudmonkey("list virtualmachines name=%s" % nodeName)
	cloudmonkey("destroy virtualmachine id=%s expunge=true" % result['virtualmachine'][0]['id'])	
	print "Cannot create a node cassandra!"
	exit(1)
print "A new node cassandra has been deployed"

#Run cassandra in new node
newNodeIpAddress = newNode['jobresult']['virtualmachine']['nic'][0]['ipaddress']

if nodeName == 'CAS-1':
	seeds = newNodeIpAddress
else:
	zabbixHostid = zapi.host.get(filter = {"name":"CAS-1"})[0]['hostid']
	seeds = zapi.hostinterface.get(hostids=zabbixHostid, output="extend")[0]['ip']

if isBooted(newNodeIpAddress) == True:
	ret = os.system("sshpass -p '123456' scp -r -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null /Cassandra root@%s:/" % newNodeIpAddress)
	if ret != 0:
		print "copy fail"
		exit(1)
	client = paramiko.SSHClient()
	client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
	client.connect(newNodeIpAddress, username='root', password='123456')
	stdin, stdout, stderr = client.exec_command('/Cassandra/configCassandra.sh %s' %seeds)
	while not stdout.channel.exit_status_ready(): time.sleep(2)
	stdin, stdout, stderr = client.exec_command('/Cassandra/bin/cassandra')
	while not stdout.channel.exit_status_ready(): time.sleep(2)
	time.sleep(60)
	stdin, stdout, stderr = client.exec_command('/Cassandra/bin/cassandra')
	while not stdout.channel.exit_status_ready(): time.sleep(2)
	client.close()

#Add new node to zabbix
zabbixTemplateid = zapi.template.get(filter = {"host":"Cassandra Monitoring"})[0]['templateid']
zabbixGroupid = zapi.hostgroup.get(filter = {"name":"Cassandra"})[0]['groupid']

zapi.host.create(
	host = nodeName,
	interfaces=[
		{
			"dns":"",
			"ip":newNodeIpAddress,
			"main":1,
			"port":"7199",
			"type":4,
			"useip":1
		}
	],
	groups=[
		{
			"groupid":zabbixGroupid
		}
	],
	templates=[
		{
			"templateid":zabbixTemplateid
		}
	]
)
