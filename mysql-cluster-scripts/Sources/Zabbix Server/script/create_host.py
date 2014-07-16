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
def createHost(credentials):
    hostname = credentials["hostname"]
    ip = credentials["ip"]
    port = credentials["port"]
    nodetype = credentials["nodetype"]
    if nodetype == "sql":
        template_name = "MySQL SQL"
    elif nodetype == "data":
        template_name = "MySQL Data"
    else:
        template_name = "default"
    
    #find groups id
    group_id = zapi.hostgroup.get(
        output = "extend",
        filter = {
            "name": [
                template_name
            ]
        }
    )[0]["groupid"]
    
    # find template
    template = zapi.template.get(
        filter = {
            'host': [
                template_name
            ]
        }
    )
    if template:
        template_id = template[0]["templateid"]
        # create new host
        rs = zapi.host.create(
            host = hostname,
            interfaces = [
                {
                    "type": 1,
                    "main": 1,
                    "useip": 1,
                    "ip": ip,
                    "dns": "",
                    "port": port,
                }
            ],
            groups = [
                {
                    "groupid": group_id
                }
            ],
            templates = [
                {
                    "templateid": template_id
                }
            ],
        )
    else:
        rs = zapi.host.create(
            host = hostname,
            interfaces = [
                {
                    "type": 1,
                    "main": 1,
                    "useip": 1,
                    "ip": ip,
                    "dns": "",
                    "port": port,
                }
            ],
            groups = [
                {
                    "groupid": group_id
                }
            ],
        )
        
    host_id=rs["hostids"][0]

    # # get hostinterface id
    # hostinterface_id = zapi.hostinterface.get(
    #     output = "extend",
    #     hostids = host_id
    # )[0]["interfaceid"]
    # 
    # # add item
    # zapi.item.create(
    #     name = 'Used disk space on $1 in %',
    #     hostid = host_id,
    #     description = 'Used disk space on $1 in %',
    #     key_ = 'vfs.fs.size[/,pfree]',
    #     type = 0,
    #     value_type = 0,
    #     interfaceid = hostinterface_id,
    #     delay = 30
    # )
    # 
    # # add trigger
    # rs = zapi.trigger.create(
    #     description = "Disk Free is lower than 10%",
    #     expression = "{" + hostname + ":vfs.fs.size[/,pfree].last(0)}<10"
    # )
    # trigger_id = rs["triggerids"][0]

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
    cloudmonkey("set apikey I7_wlxR3IRfF7YSfh4PdnH22nynyTdBwdMrGd0M-vph6r9I3cUtpq1WICV-hfYZmBrMbVD6ZXdNFzZfGigt7IA")
    cloudmonkey("set secretkey zhH8Adqc7Sh33G1YrGg41k51T2qiLuxQjjdlSi0gr65nVGMV_68pcLUWFKke7VplLYD3I-ZGppuRwwWgHPMJOw")
    cloudmonkey("set asyncblock true")
    cloudmonkey("set color false")
    cloudmonkey("set display json")
    cloudmonkey("sync")
    
    print "cloudStack sync DONE"
    # f0ea5cbc-83fa-4080-a095-717a1c32d872 medium instance
    # 15b21986-1f84-44e7-a061-1b608ded627e large instance
    data_node_id = "91115649-e302-410d-af80-757adb0fa7e0" # template
    mgm_node_id = "23d894e9-75e5-478e-868b-645da6746c60"  # template
    sql_node_id = "9012a80b-0c75-4db2-871c-9e1efd9d57e3"  # template
    # sql_node_id = "bf86aecc-d19e-41ac-93de-6a55320f108d"  # template
    if sys.argv[1] == 'sql':
        instances = cloudmonkey("list virtualmachines account=bkcloud name=mysql-sql")
        id = 1
        for instance in instances['virtualmachine']:
            m = re.match(r'.*mysql-sql(\d+).*', instance['displayname'])
            if m != None and int(m.group(1)) >= id: id = int(m.group(1))+1
        instance_name = "ductm310-mysql-sql"+str(id)
        print instance_name
        new_instances = []
        instance = cloudmonkey("deploy virtualmachine serviceofferingid=57a97443-d9dd-4856-ba4a-ba7a7b769f89 templateid=%s zoneid=c70a4033-3a72-4900-8aa3-8f1bee765d4b name=%s displayname=%s" % (sql_node_id, instance_name, instance_name))
        if instance['jobstatus'] == "2":
            print "SQL node failed to deploy"
            exit(1)
        print "SQL node has been deployed"
        new_instances.append(instance)
        nodetype = "sql"
    elif sys.argv[1] == 'data':
        instances = cloudmonkey("list virtualmachines account=bkcloud name=mysql-data")
        id = 1
        for instance in instances['virtualmachine']:
            m = re.match(r'.*mysql-data(\d+).*', instance['displayname'])
            if m != None and int(m.group(1)) >= id: id = int(m.group(1))+1
        instance_name = "ductm310-mysql-data"+str(id)
        print instance_name
        new_instances = []
        instance = cloudmonkey("deploy virtualmachine serviceofferingid=57a97443-d9dd-4856-ba4a-ba7a7b769f89 templateid=%s zoneid=c70a4033-3a72-4900-8aa3-8f1bee765d4b name=%s displayname=%s" % (data_node_id, instance_name, instance_name))
        if instance['jobstatus'] == "2":
            print "Data node failed to deploy"
            exit(1)
        print "Data node has been deployed"
        new_instances.append(instance)
        instance_name = "ductm310-mysql-data"+str(id+1)
	print instance_name
        instance = cloudmonkey("deploy virtualmachine serviceofferingid=57a97443-d9dd-4856-ba4a-ba7a7b769f89 templateid=%s zoneid=c70a4033-3a72-4900-8aa3-8f1bee765d4b name=%s displayname=%s" % (data_node_id, instance_name, instance_name))
        if instance['jobstatus'] == "2":
            instance = cloudmonkey("destroy virtualmachine id=%s expunge=true" % new_instances[0]['jobresult']['virtualmachine']['id'])
            print "Data node failed to deploy"
            exit(1)
        print "Data node has been deployed"
        nodetype = "data"
        new_instances.append(instance)
    else:
        exit(1)
    
    for i in new_instances:        
	print i
        if isBooted(i['jobresult']['virtualmachine']['nic'][0]['ipaddress']) == True:
            pass
    
    #connect to cluster: rolling restart
    print "Perform rolling restart cluster"
    instances = cloudmonkey("list virtualmachines account=bkcloud name=mysql-mgm")
    mgm_ip = instances['virtualmachine'][0]['nic'][0]['ipaddress']
    
    client = paramiko.SSHClient()
    client.load_system_host_keys()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(mgm_ip, username='root', password=password)
    stdin, stdout, stderr = client.exec_command('service mysql-cluster restart')
    while not stdout.channel.exit_status_ready(): time.sleep(2)
    client.close()
    
    # add host
    for i in new_instances:
        createHost({"hostname": i['jobresult']['virtualmachine']['displayname'], "ip": i['jobresult']['virtualmachine']['nic'][0]['ipaddress'],"port": "10050", "nodetype": nodetype})
    
    exit(0)