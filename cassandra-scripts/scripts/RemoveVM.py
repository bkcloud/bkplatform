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

def isTurnOff(ipAddress):
    while True:
        ret = os.system("ping -c 3 %s" % ipAddress)
        if ret != 0: return True
        time.sleep(30)
    return False

#Check argument
if len(sys.argv) == 1:
	print "Please enter argument"
	exit(1)
if sys.argv[1] != 'CAS-1':
        print "Don't remove node"
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

#get name of lastest node
zabbixGroupid = zapi.hostgroup.get(filter = {"name":"Cassandra"})[0]['groupid']
numberNode = zapi.host.get(groupids = zabbixGroupid, countOutput = 1)
nodeName = 'CAS-' + numberNode
print nodeName

if nodeName == 'CAS-3':
	print "Number of node is too few. Don't remove any node"
	exit(1)

#get id and ipaddress Node
result = cloudmonkey("list virtualmachines name=%s" %nodeName)

if type(result) != type(dict()):
	print "Node isn't exsit"
	exit(1)

idNode = result['virtualmachine'][0]['id']
ipAddressNode = result['virtualmachine'][0]['nic'][0]['ipaddress']

#decomission Node
client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect(ipAddressNode, username='root', password='123456')
stdin, stdout, stderr = client.exec_command('/Cassandra/bin/nodetool repair -h %s && /Cassandra/bin/nodetool decommission -h %s && shutdown -h now' %(ipAddressNode, ipAddressNode))
client.close()

#destroy Node
if isTurnOff(ipAddressNode) == True:
	cloudmonkey("destroy virtualmachine id=%s expunge=true" %(idNode))

#remove host from Zabbix
zabbixHostid = zapi.host.get(filter = {"name":"%s" %nodeName})[0]['hostid']
zapi.host.delete(zabbixHostid)
