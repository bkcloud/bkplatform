from pyzabbix import ZabbixAPI
import subprocess
import os
import sys
import json
import paramiko
import re
import time
# import sqlite3

ZABBIX_SERVER_ADDRESS="http://192.168.50.74/zabbix"
password="neverland"

# create new host
def deleteHost(credentials):
    hostname = credentials["hostname"]
    # ip = credentials["ip"]    
    
    hosts = zapi.host.get(
        output = "extend",
        filter = {
            "host": [
                hostname,
            ]
        }
    )
    for i in hosts:
        zapi.host.delete(
            {
                "hostid": i['hostid']
            },
        )
    
def atoi(text):
    return int(text) if text.isdigit() else text

def natural_keys(text):
    '''
    alist.sort(key=natural_keys) sorts in human order
    http://nedbatchelder.com/blog/200712/human_sorting.html
    (See Toothy's implementation in the comments)
    '''
    return [ atoi(c) for c in re.split('(\d+)', text) ]


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
        
def isBooted(hostname):
    count = 40
    while True:
        ret = os.system("ping -c 2 %s" % hostname)
        count -= 1
        if ret == 0: return True
        elif count <= 0: break
        time.sleep(3)
    return False

if __name__=='__main__':

    global zapi
    zapi = ZabbixAPI(ZABBIX_SERVER_ADDRESS)
    zapi.login("Admin","zabbix")
    print "Connected to Zabbix API Version %s" % zapi.api_version()

    #deploy new node (cloudstack)
    cloudmonkey("set host 192.168.50.11")
    cloudmonkey("set port 8080")
    cloudmonkey("set apikey your_api_key")
    cloudmonkey("set secretkey your_secret_key")
    cloudmonkey("set asyncblock true")
    cloudmonkey("set color false")
    cloudmonkey("set display json")
    cloudmonkey("sync")
    
    print "cloudStack sync DONE"
    
    if sys.argv[1] == 'sql':
        instances = cloudmonkey("list virtualmachines account=bkcloud name=mysql-sql")
        sorted_instances = instances['virtualmachine']
        sorted_instances.sort(key=lambda x:natural_keys(x['name']) )
        try: node = sys.argv[2] - sys.argv[3]
        except: node = 2
	if node < 2: node = 2
        delete_instances = sorted_instances[node:] if len(sorted_instances) > node else sorted_instances[1:]
        for i in delete_instances:
            rs = cloudmonkey("destroy virtualmachine id=%s expunge=true" % i['id'])
        print "SQL node has been decreased"
    elif sys.argv[1] == 'data':
        exit(1)
    else:
        exit(1)
    
    # delete host
    for i in delete_instances:
        deleteHost({"hostname": i['displayname']})
     
    exit(0)
