import subprocess
import os
import sys
import json
import re

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
    cloudmonkey("set apikey I7_wlxR3IRfF7YSfh4PdnH22nynyTdBwdMrGd0M-vph6r9I3cUtpq1WICV-hfYZmBrMbVD6ZXdNFzZfGigt7IA")
    cloudmonkey("set secretkey zhH8Adqc7Sh33G1YrGg41k51T2qiLuxQjjdlSi0gr65nVGMV_68pcLUWFKke7VplLYD3I-ZGppuRwwWgHPMJOw")
    cloudmonkey("set color false")
    cloudmonkey("set display json")
    cloudmonkey("sync")
    
    instances = cloudmonkey("list virtualmachines account=bkcloud name=mysql-mgm")
    mgm_ip = instances['virtualmachine'][0]['nic'][0]['ipaddress']
    if os.system("ls /script|grep initial") == 0: 
        cmd = "/usr/local/mysql-cluster/bin/ndbmtd -c %s --initial" % mgm_ip 	
        rs = subprocess.Popen([cmd], stdout=subprocess.PIPE, shell=True).communicate()[0] 
        os.system("rm -f /script/initial")
    else:
        cmd = "/usr/local/mysql-cluster/bin/ndbmtd -c %s" % mgm_ip 	
        rs = subprocess.Popen([cmd], stdout=subprocess.PIPE, shell=True).communicate()[0] 
    exit(0)