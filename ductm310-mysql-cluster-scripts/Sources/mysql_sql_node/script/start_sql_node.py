import subprocess
import os
import sys
import json
import re
import socket


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

if __name__=='__main__':

    cloudmonkey("set host 192.168.50.11")
    cloudmonkey("set port 8080")
    cloudmonkey("set apikey your_api_key")
    cloudmonkey("set secretkey your_secret_key")
    cloudmonkey("set color false")
    cloudmonkey("set display json")
    cloudmonkey("sync")   

    instances = cloudmonkey("list virtualmachines account=bkcloud name=mysql-mgm")
    mgm_ip = instances['virtualmachine'][0]['nic'][0]['ipaddress']
    cmd = 'cd /usr/local/mysql-cluster/ && bin/mysqld_safe --defaults-extra-file=/etc/mysqld-cluster.cf --user=mysql --datadir=/var/lib/mysql-node-data --basedir=/usr/local/mysql-cluster --ndb-connectstring='+mgm_ip+' &' 
    rs = subprocess.Popen([cmd], stdout=subprocess.PIPE, shell=True)
    
    # instance = cloudmonkey("list virtualmachines name=%s" % socket.gethostname())
    # cloudmonkey("assign toloadbalancerrule id=%s virtualmachineids=%s" % ( , instance['virtualmachine'][0]['id']) )
    
    exit(0)
