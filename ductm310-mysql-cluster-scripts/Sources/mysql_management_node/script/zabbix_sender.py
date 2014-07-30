import socket
import struct
import json
import os
import time
import sys
import re
import subprocess
import paramiko
import math

ZABBIX_SERVER="192.168.50.74"
ZABBIX_PORT=10051
password="neverland"

class ZSend:
   def __init__(self, server=ZABBIX_SERVER, port=ZABBIX_PORT):
      self.zserver = server
      self.zport = port
      self.list = []
      self.inittime = int(round(time.time()))
      self.header = '''ZBXD\1%s%s'''
      self.datastruct = '''
{ "host":"%s",
  "key":"%s",
  "value":"%s",
  "clock":%s }'''

   def add_data(self,host,key,value,evt_time=None):
      if evt_time is None:
         evt_time = self.inittime
      self.list.append((host,key,value,evt_time))

   def print_vals(self):
      for (h,k,v,t1) in self.list:
         print "Host: %s, Key: %s, Value: %s, Event: %s" % (h,k,v,t1)

   def build_all(self):
      tmpdata = "{\"request\":\"sender data\",\"data\":["
      count = 0
      for (h,k,v,t1) in self.list:
         tmpdata = tmpdata + self.datastruct % (h,k,v,t1)
         count += 1
         if count < len(self.list):
            tmpdata = tmpdata + ","
      tmpdata = tmpdata + "], \"clock\":%s}" % self.inittime
      return (tmpdata)

   def build_single(self,dataset):
      tmpdata = "{\"request\":\"sender data\",\"data\":["
      (h,k,v,t1) = dataset
      tmpdata = tmpdata + self.datastruct % (h,k,v,t1)
      tmpdata = tmpdata + "], \"clock\":%s}" % self.inittime
      return (tmpdata)

   def send(self,mydata):
      socket.setdefaulttimeout(5)
      data_length = len(mydata)
      data_header = struct.pack('i', data_length) + '\0\0\0\0'
      data_to_send = self.header % (data_header, mydata)
      try:
         sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
         sock.connect((self.zserver,self.zport))
         sock.send(data_to_send)
      except Exception as err:
         sys.stderr.write("Error talking to server: %s\n" % err)
         return (255,err)

      response_header = sock.recv(5)
      if not response_header == 'ZBXD\1':
         sys.stderr.write("Invalid response from server." + \
                          "Malformed data?\n---\n%s\n---\n" % mydata)
         return (254,err)
      response_data_header = sock.recv(8)
      response_data_header = response_data_header[:4]
      response_len = struct.unpack('i', response_data_header)[0]
      response_raw = sock.recv(response_len)
      sock.close()
      response = json.loads(response_raw)
      match = re.match("^.*Failed\s(\d+)\s.*$",str(response))
      if match is None:
         sys.stderr.write("Unable to parse server response - " + \
                          "\n%s\n" % response)
      else:
         fails = int(match.group(1))
         if fails > 0:
            sys.stderr.write("Failures reported by zabbix when sending:" + \
                             "\n%s\n" % mydata)
            return (1,response)
      return (0,response)


#####################################
# --- Examples of usage ---
#####################################
#
# Initiating a Zsend object -
# z = ZSend(server="10.0.0.10")
# z = ZSend(server="server1",port="10051")
# z = ZSend("server1","10051")
# z = ZSend() # Defaults to using ZABBIX_SERVER,ZABBIX_PORT
#

# --- Adding data to send later ---
# Host, Key, Value are all necessary
# z.add_data("host1","cpu.usage","12")
#
# Optionally you can provide a specific timestamp for the sample
# z.add_data("host1","cpu.usage","13","1365787627")
#
# If you provide no timestamp, the initialization time of the class
# is used.

# --- Printing values ---
# Not that useful, but if you would like to see your data in tuple form
# with assumed timestamps
# z.print_vals()

# --- Building well formatted data to send ---
# You can send all of the data in one batch -
# z.build_all() will return a string of packaged data ready to send
# z.build_single((host,key,value,timestamp)) will return a packaged single

# --- Sending data ---
# Typical example - build all the data and send it in one batch -
#
# z.send(z.build_all())
#
# Alternate example - build the data individually and send it one by one
# so that we can see errors for anything that doesnt send properly -
#
# for i in z.list:
#    (code,ret) = z.send(z.build_single(i))
#    if code == 1:
#       print "Problem during send!\n%s" % ret
#    elif code == 0:
#       print ret
#
#
#####################################
# Mini example of a working program #
#####################################
#
z = ZSend() # Defaults to using ZABBIX_SERVER,ZABBIX_PORT

# data node memory report
stdout = subprocess.Popen(['/usr/local/mysql-cluster/bin/ndb_mgm -e "all report memory"'], stdout=subprocess.PIPE, shell=True).communicate()[0]
stdout = stdout.splitlines(True)
data_usage, index_usage, node_d, node_i= 0, 0, 0, 0
for line in stdout:
    m = re.match(r'^Node.(\d+):.(\w+).usage.*is.(\d+)%.*', line)
    if m != None and m.group(2) == 'Data':
        data_usage += eval(m.group(3))
	node_d += 1
        # z.add_data(socket.gethostname(),"data.usage[%s]" % m.group(1),m.group(3))
    elif m != None and m.group(2) == 'Index':
        index_usage += eval(m.group(3))
	node_i += 1
        # z.add_data(socket.gethostname(),"index.usage[%s]" % m.group(1),m.group(3))
    else: continue

z.add_data(socket.gethostname(),"data.usage", data_usage/node_d)
z.add_data(socket.gethostname(),"index.usage", index_usage/node_i)
print data_usage/node_d
print index_usage/node_i

# sql connections report
stdout = subprocess.Popen(['/usr/local/mysql-cluster/bin/ndb_mgm -e show'], stdout=subprocess.PIPE, shell=True).communicate()[0]
stdout = stdout.splitlines(True)
threads_connected, max_connections, node = 0, 0, 0
proccessed=[]
for line in stdout:
    type = 0 if line.find("[ndbd(NDB)]") == 0 else 1 if line.find("[ndb_mgmd(MGM)]") == 0 else 2 if line.find("[mysqld(API)]") == 0 else type
    m = re.match(r'id=(\d+)\s*@(\d+\.\d+\.\d+\.\d+).*', line)
    if m != None and type == 2:
        # print m.group(2)
	if m.group(2) in proccessed:
	    continue
        node += 1
        stdout = subprocess.Popen(["echo SHOW GLOBAL STATUS|/usr/local/mysql-cluster/bin/mysql -u%s -p%s -h %s |grep '^Threads_connected\s'|awk '{print $2}'" % ('root', '123456', m.group(2))], stdout=subprocess.PIPE, shell=True).communicate()[0]
        threads_connected += eval(stdout)
        stdout = subprocess.Popen(["/usr/local/mysql-cluster/bin/mysqladmin -u%s -p%s -h %s variables|grep 'max_connections'|awk '{print $4}'" % ('root', '123456', m.group(2))], stdout=subprocess.PIPE, shell=True).communicate()[0]
        max_connections += eval(stdout)
	proccessed.append(m.group(2))
    
#print threads_connected
#print max_connections
#print 1+(threads_connected/(max_connections/node))
if node > 0:
    th_over_max = threads_connected/(max_connections/node)
    suggest = 1+th_over_max
    temp = max_connections - threads_connected
    print node, suggest, temp
    if node == suggest and temp < 50:
    	suggested_node = 2+th_over_max
    elif temp > 270:
        suggested_node = 1+th_over_max
    else:
    	suggested_node = node 
else:
    suggested_node = 2

if suggested_node < 2: suggested_node = 2

z.add_data(socket.gethostname(),"sql.node", node)
z.add_data(socket.gethostname(),"sql.threads_connected", threads_connected)
z.add_data(socket.gethostname(),"sql.max_connections", max_connections)
z.add_data(socket.gethostname(),"sql.suggested_node", suggested_node)
        

z.print_vals()
for i in z.list:
   (code,ret) = z.send(z.build_single(i))
   if code == 1:
      print "Problem during send!\n%s" % ret
   elif code == 0:
      print ret
#
#####################################
