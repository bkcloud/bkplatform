from pyzabbix import ZabbixAPI
import subprocess
import os
import sys
import json
import paramiko
import re
import time

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
        ret = os.system("ping -c 10 %s" % ipAddress)
        count -= 1
        if ret == 0: return True
        elif count <= 0: break
        time.sleep(3)
    return False

#Check argument
if len(sys.argv) == 1:
	print "Please enter argument"
	exit(1)

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

#get id and ip resetedNode
result = cloudmonkey("list virtualmachines name=%s filter=id,ipaddress" %(sys.argv[1]))
if type(result) != type(dict()):
	print "Node isn't exsit"
	exit(1)
idNode = result['virtualmachine'][0]['id']

#reset node
resetedNode = cloudmonkey("restore virtualmachine virtualmachineid=%s" %(idNode))
if resetedNode['jobstatus'] == 2:
	print "Cannot reset node!"
	exit(1)
print "The node has been reseted"
resetedNodeIpAddress = resetedNode['jobresult']['virtualmachine']['nic'][0]['ipaddress']
if resetedNode['jobresult']['virtualmachine']['state'] != 'Running':
	print 'start node'
	print cloudmonkey("start virtualmachine id=%s" %(idNode))

if sys.argv[1] == 'CAS-1':
	seeds = resetedNodeIpAddress
else:
	zabbixHostid = zapi.host.get(filter = {"name":"CAS-1"})[0]['hostid']
	seeds = zapi.hostinterface.get(hostids=zabbixHostid, output="extend")[0]['ip']

if isBooted(resetedNodeIpAddress) == True:
	ret = os.system("sshpass -p '123456' scp -r -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null /Cassandra root@%s:/" % resetedNodeIpAddress)
	if ret != 0:
		print "copy fail"
		exit(1)
	client = paramiko.SSHClient()
	client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
	client.connect(resetedNodeIpAddress, username='root', password='123456')
	stdin, stdout, stderr = client.exec_command('/Cassandra/configCassandra.sh %s' %seeds)
	while not stdout.channel.exit_status_ready(): time.sleep(2)
	if seeds == resetedNodeIpAddress:
		stdin, stdout, stderr = client.exec_command('/Cassandra/bin/cassandra')
		while not stdout.channel.exit_status_ready(): time.sleep(2)
		time.sleep(60)
		stdin, stdout, stderr = client.exec_command('/Cassandra/bin/nodetool repair -h %s' %(resetedNodeIpAddress))
	else:
		stdin, stdout, stderr = client.exec_command('/Cassandra/bin/cassandra -Dcassandra.replace_address=%s' %resetedNodeIpAddress)
		while not stdout.channel.exit_status_ready(): time.sleep(2)
	client.close()
