#!/usr/bin/python

import MySQLdb
import sys
import subprocess

if len(sys.argv) != 2:
    print("""{"status": "ERROR", "message": "Syntax Error"}""")
    sys.exit()
else:
    vm_uuid = sys.argv[1]


try:
    db = MySQLdb.connect(host='192.168.50.11',
                         user='cloud',
                         passwd='bkcloud@#@!',
                         db='cloud',
                         charset='utf8')
except:
    print("""{"status": "ERROR", "message": "Connect DB Error"}""")
    sys.exit()


conn = db.cursor()

try:
    conn.execute("""SELECT `instance_name`, `host_id`, `state`
                    FROM `vm_instance`
                    WHERE `vm_type`="User" AND `uuid`=%s
                    """, (vm_uuid))

    instance_name, host_id, state = conn.fetchone()

    if state != 'Running':
        print("""{"status": "ERROR", "message": "VM is not running"}""")
    else:
        conn.execute("""SELECT `private_ip_address`
                        FROM `host`
                        WHERE `id`=%s""", (host_id))
        host_ip_address = conn.fetchone()[0]

        subprocess.call(['/scripts/call_tunnel_ssh.sh',
                         instance_name, host_ip_address])
except:
    print("""{"status": "ERROR", "message": "Select DB Error"}""")

finally:
    db.close()