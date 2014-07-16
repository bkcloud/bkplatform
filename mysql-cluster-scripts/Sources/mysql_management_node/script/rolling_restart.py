from lib import config_ini
from pyzabbix import ZabbixAPI
import subprocess
import os
import sys
import json
import paramiko
import re
import time
import sqlite3

#proc    -> name/id of the process
#id = 1  -> search for pid
#id = 0  -> search for name (default)

haproxy_ip = "192.168.50.89"
password = "neverland"

def atoi(text):
    return int(text) if text.isdigit() else text

def natural_keys(text):
    '''
    alist.sort(key=natural_keys) sorts in human order
    http://nedbatchelder.com/blog/200712/human_sorting.html
    (See Toothy's implementation in the comments)
    '''
    return [ atoi(c) for c in re.split('(\d+)', text) ]

def process_exists(proc, id = 0):
   ps = subprocess.Popen("ps -A", shell=True, stdout=subprocess.PIPE)
   ps_pid = ps.pid
   output = ps.stdout.read()
   ps.stdout.close()
   ps.wait()

   for line in output.split("\n"):
      if line != "" and line != None:
        fields = line.split()
        pid = fields[0]
        pname = fields[3]

        if(id == 0):
            if(pname == proc):
                return True
        else:
            if(pid == proc):
                return True
   return False

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
        
def checkDB():
    global conn, cursor
    if os.path.isfile('/script/hosts.db') == True:
        conn = sqlite3.connect('/script/hosts.db')
        cursor = conn.cursor()
    else:
        conn = sqlite3.connect('/script/hosts.db')
        cursor = conn.cursor()
        cursor.execute('''CREATE TABLE hosts(id, ipaddress)''')
        conn.commit()

def getID(ipaddress):
    if 'conn' not in globals() or 'cursor' not in globals():
        checkDB()
    rs = cursor.execute("select id from hosts where ipaddress like '%s'" % ipaddress)
    rs = rs.fetchall()
    if len(rs) > 0:
        return eval(rs[0][0])
    else:
        return -1
        
def requestID(nodetype="data"):
    global request_tmp, request_tmp_sql
    if 'conn' not in globals() or 'cursor' not in globals():
        checkDB()
    rs = cursor.execute("select id from hosts")
    rs = rs.fetchall()
    rs = [eval(i[0]) for i in rs]
    rs.sort()
    if nodetype == "sql":
        i = 49 + request_tmp_sql + 1
        while i in rs:
            i += 4
        request_tmp_sql  = i - 49 + 3
        return i 
    else:    
	i = 1 + request_tmp + 1
	while i in rs and i < 49:
	    i += 1
        request_tmp = i - 1
        return i 
        
def updateID(ipaddress, id):
    if 'conn' not in globals() or 'cursor' not in globals():
        checkDB()
    if getID(ipaddress) > 0:
        cursor.execute("UPDATE hosts set id=:id where ipaddress=:ipaddress", {'id': str(id), 'ipaddress': str(ipaddress)})
    else:
        cursor.execute("INSERT INTO hosts (id, ipaddress) values (?,?)", (id, ipaddress))
    conn.commit()
    

if __name__=='__main__':
    
    global request_tmp, request_tmp_sql
    request_tmp, request_tmp_sql = -1, -1

    cloudmonkey("set host 192.168.50.11")
    cloudmonkey("set port 8080")
    cloudmonkey("set apikey I7_wlxR3IRfF7YSfh4PdnH22nynyTdBwdMrGd0M-vph6r9I3cUtpq1WICV-hfYZmBrMbVD6ZXdNFzZfGigt7IA")
    cloudmonkey("set secretkey zhH8Adqc7Sh33G1YrGg41k51T2qiLuxQjjdlSi0gr65nVGMV_68pcLUWFKke7VplLYD3I-ZGppuRwwWgHPMJOw")
    cloudmonkey("set color false")
    cloudmonkey("set display json")
    cloudmonkey("sync")   
    
    # for SSH
    client = paramiko.SSHClient()
    client.load_system_host_keys()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    # create new config.ini
    print "Create New Config.ini"
    # get info all node in cluster
    instances = cloudmonkey("list virtualmachines account=bkcloud name=ductm310-mysql")
    # instances['virtualmachine][i]['displayname']
    # instances['virtualmachine'][0]['nic'][0]['ipaddress']
    text = '[ndbd default]\nNoOfReplicas = 2\nDataDir= /var/lib/mysql-ndb-data\nDataMemory = 1G\nIndexMemory = 512M\nServerPort=40000\n\n'
    with open("config.ini","w") as fp:
        fp.write(text)
    mgms, sqls, datas = [], [], []
    mgms_old, datas_old, sqls_old = [], [], []
    checkDB()
    cursor.execute("delete from hosts where ipaddress not in (%s)" % ', '.join('?' for i in instances['virtualmachine']), [i['nic'][0]['ipaddress'] for i in instances['virtualmachine']])
    
    stdout = subprocess.Popen(['/usr/local/mysql-cluster/bin/ndb_mgm -e show'], stdout=subprocess.PIPE, shell=True).communicate()[0]
    stdout = stdout.splitlines(True)
    for line in stdout:
        type = 0 if line.find("[ndbd(NDB)]") == 0 else 1 if line.find("[ndb_mgmd(MGM)]") == 0 else 2 if line.find("[mysqld(API)]") == 0 else type
        m = re.match(r'id=(\d+)\s*@(\d+\.\d+\.\d+\.\d+).*', line)
        #if m != None and type == 0:
  	#    if "no nodegroup" not in line:
	#	for i in instances['virtualmachine']:
         #           if i['nic'][0]['ipaddress'] == m.group(2): datas_old.append(i)
        # if m != None and type == 1: mgms_old.append((m.group(1),m.group(2))) 
        if m != None and type == 2:
            for i in instances['virtualmachine']:
		if i not in sqls_old:
                    if i['nic'][0]['ipaddress'] == m.group(2): sqls_old.append(i)

    for instance in instances['virtualmachine']:
        id = getID(instance['nic'][0]['ipaddress'])
        if 'mysql-mgm' in instance['displayname']:
            mgms.append(instance)
            if id > 0: mgms_old.append(instance)
            else: 
		id = requestID()
		updateID(instance['nic'][0]['ipaddress'],str(id))
            config_ini.appendNodeToFile('management', instance['nic'][0]['ipaddress'], id)
        elif 'mysql-sql' in instance['displayname']:
            sqls.append(instance)
            # if id > 0: sqls_old.append(instance)
            # else: id = requestID()
            # if instance['nic'][0]['ipaddress'] not in [i['nic'][0]['ipaddress'] for i in sqls_old]: 
            if id <= 0:
                id = requestID("sql")
		updateID(instance['nic'][0]['ipaddress'],str(id))
            config_ini.appendNodeToFile('sql', instance['nic'][0]['ipaddress'], id)
        elif 'mysql-data' in instance['displayname']:
            datas.append(instance)
            if 0 < id < 49:
		datas_old.append(instance)
            else:
	    #if id < 1 or id > 48:
		id = requestID()
		updateID(instance['nic'][0]['ipaddress'],str(id))
            config_ini.appendNodeToFile('data', instance['nic'][0]['ipaddress'], id)
    # scp config to management node
    subprocess.Popen(["cp config.ini /var/lib/mysql-mgmd-data/config.ini"], stdout=subprocess.PIPE, shell=True).communicate()[0] 
    
    # restart management node
    print "Restart management node"   
    print(len(sqls),len(sqls_old))
    if len(sqls) > len(sqls_old):
        if process_exists("ndb_mgmd") == True: 
            for m in mgms_old:
                stdout = subprocess.Popen(['/usr/local/mysql-cluster/bin/ndb_mgm -e "'+str(getID(m['nic'][0]['ipaddress']))+' stop"'], stdout=subprocess.PIPE, shell=True).communicate()[0]
                print stdout
                while process_exists('ndb_mgmd') == True:
                    time.sleep(2)
        i = 0
        while True:
            stdout = subprocess.Popen(['/usr/local/mysql-cluster/bin/ndb_mgmd --initial --configdir=/var/lib/mysql-mgmd-config-cache --config-file=/var/lib/mysql-mgmd-data/config.ini'], stdout=subprocess.PIPE, shell=True).communicate()[0]
            i += 1
            if "[MgmtSrvr] ERROR" not in stdout or i >= 3: break
        print stdout
    else:
        if process_exists("ndb_mgmd") == True: 
            for m in mgms_old:
                stdout = subprocess.Popen(['/usr/local/mysql-cluster/bin/ndb_mgm -e "'+str(getID(m['nic'][0]['ipaddress']))+' stop"'], stdout=subprocess.PIPE, shell=True).communicate()[0]
                while process_exists('ndb_mgmd') == True: time.sleep(2)
        stdout = subprocess.Popen(['/usr/local/mysql-cluster/bin/ndb_mgmd --reload --configdir=/var/lib/mysql-mgmd-config-cache --config-file=/var/lib/mysql-mgmd-data/config.ini'], stdout=subprocess.PIPE, shell=True).communicate()[0]
        print stdout
    
    #stdout = subprocess.Popen(['/usr/local/mysql-cluster/bin/ndb_mgm -e show'], stdout=subprocess.PIPE, shell=True).communicate()[0]
    #stdout = stdout.splitlines(True)
    #for line in stdout:
    	#type = 0 if line.find("[ndbd(NDB)]") == 0 else 1 if line.find("[ndb_mgmd(MGM)]") == 0 else 2 if line.find("[mysqld(API)]") == 0 else type
        #m = re.match(r'id=(\d+)\s*\D*(\d+\.\d+\.\d+\.\d+).*', line)
	#tmp = []
        #if m != None: 
	    #if m.group(2) not in tmp:
	    	#updateID(m.group(2),m.group(1))          
	    	#tmp.append(m.group(2))
	#if m != None and type == 0:
  	#    if "no nodegroup" not in line and "not connected" not in line:
	#	for i in instances['virtualmachine']:
        #            if i['nic'][0]['ipaddress'] == m.group(2): datas_old.append(i)
    


    
    # rolling restart datanode and initial new data node
    print "Restart data nodes"
    print(len(datas),len(datas_old))
    for i in datas_old:
	#if len(datas) == len(datas_old):
	#    stdout = subprocess.Popen(['/usr/local/mysql-cluster/bin/ndb_mgm -e "'+str(getID(i['nic'][0]['ipaddress']))+' status"'], stdout=subprocess.PIPE, shell=True).communicate()[0]
	#    if "started" in stdout: continue
	print("Restart %s" % i['name'])
        if i['state'] not in ['Running','Stopping','Destroying','Destroyed','Stopped']:
            rs = cloudmonkey("stop virtualmachine id="+str(i['id']))
            if rs['state'] != 'Stopped': rs = cloudmonkey("stop virtualmachine id="+str(i['id'])+" forced=true")
            rs = cloudmonkey("start virtualmachine id="+str(i['id']))
        elif i['state'] == 'Stopped':
            rs = cloudmonkey("start virtualmachine id="+str(i['id']))
        else:
            while True:
		# print i['nic'][0]['ipaddress']
                stdout = subprocess.Popen(['/usr/local/mysql-cluster/bin/ndb_mgm -e "'+str(getID(i['nic'][0]['ipaddress']))+' restart"'], stdout=subprocess.PIPE, shell=True).communicate()[0]
                if "5005-Send to process or receive failed" in stdout:
                    try:
                        client.connect(i['nic'][0]['ipaddress'], username='root', password=password)
                        stdin, stdout, stderr = client.exec_command('service mysql-data restart')
                        while not stdout.channel.exit_status_ready(): time.sleep(2)
                        client.close()
			break
                    except:
                        break
                elif "5063-Operation not allowed" in stdout:
		    time.sleep(4)
                    continue
                else:
                    break
             

    # rolling restart mysql nodes
    print "Restart API nodes"
    # print(len(sqls),len(sqls_old))
    sqls.sort(key=lambda x:natural_keys(x['name']))
    sqls.reverse()
    for i in sqls:
	print("Restart %s" % i['name'])
        if i['state'] not in ['Running','Stopping','Destroying','Destroyed','Stopped']:
            rs = cloudmonkey("stop virtualmachine id="+str(i['id']))
            if rs['state'] != 'Stopped': rs = cloudmonkey("stop virtualmachine id="+str(i['id'])+" forced=true")
            rs = cloudmonkey("start virtualmachine id="+str(i['id']))
        elif i['state'] == 'Stopped':
            rs = cloudmonkey("start virtualmachine id="+str(i['id']))
        else:
            try:
                client.connect(i['nic'][0]['ipaddress'], username='root', password=password)
                stdin, stdout, stderr = client.exec_command('service mysql-sql restart')
                while not stdout.channel.exit_status_ready(): time.sleep(2)
                client.close()
            except:
                pass

    
    # update haproxy
    print "Update HAProxy"
    client.connect(haproxy_ip, username='root', password=password)
    stdin, stdout, stderr = client.exec_command('/script/haproxy-mysql.sh ' + ' '.join([str(i['nic'][0]['ipaddress']) for i in sqls]))
    while not stdout.channel.exit_status_ready(): time.sleep(2)
    client.close()
    

    print "Initial new datanode"
    for i in datas:
	if i['nic'][0]['ipaddress'] not in [m['nic'][0]['ipaddress'] for m in datas_old]:
	    if i['state'] not in ['Running','Stopping','Destroying','Destroyed','Stopped']:
            	rs = cloudmonkey("stop virtualmachine id="+str(i['id']))
            	if rs['state'] != 'Stopped': rs = cloudmonkey("stop virtualmachine id="+str(i['id'])+" forced=true")
            	rs = cloudmonkey("start virtualmachine id="+str(i['id']))
            elif i['state'] == 'Stopped':
            	rs = cloudmonkey("start virtualmachine id="+str(i['id']))
            else:
	    	print i['nic'][0]['ipaddress']
            	try:
            	    client.connect(i['nic'][0]['ipaddress'], username='root', password=password)
                    stdin, stdout, stderr = client.exec_command('service mysql-data restart')
                    while not stdout.channel.exit_status_ready(): time.sleep(2)
                    client.close()
            	except:
                    pass
            

                
    # greate new node group
    print "Update Nodegroup"
    stdout = subprocess.Popen(['/usr/local/mysql-cluster/bin/ndb_mgm -e show'], stdout=subprocess.PIPE, shell=True).communicate()[0]
    # print stdout
    stdout = stdout.splitlines(True)
    new_data_ids = []
    for line in stdout:
        m = re.match(r'id=(\d+)\s*\D*(\d+\.\d+\.\d+\.\d+).*no.nodegroup', line)
        if m != None: new_data_ids.append(m.group(1))
    for i,k in zip(new_data_ids[0::2], new_data_ids[1::2]):
        stdout = subprocess.Popen(['/usr/local/mysql-cluster/bin/ndb_mgm -e ','"CREATE NODEGROUP '+i+','+k+'"'], stdout=subprocess.PIPE, shell=True).communicate()[0]
            

    exit(0)
[root@ductm