import re
import sys

def SQLToString(hostname, id=-1):
    if id > 0:
        text = '[mysqld]\nNodeId='+str(id)+'\nhostname='+hostname+'\n\n[mysqld]\nhostname='+hostname+'\n\n[mysqld]\nhostname='+hostname+'\n\n[mysqld]\nhostname='+hostname+'\n\n'
    else:
        text = '[mysqld]\nhostname='+hostname+'\n\n'+'[mysqld]\nhostname='+hostname+'\n\n'+'[mysqld]\nhostname='+hostname+'\n\n'+'[mysqld]\nhostname='+hostname+'\n\n'
    return text

def DataToString(hostname, id=-1):
    if id > 0:
        text = '[ndbd]\nNodeId='+str(id)+'\nhostname='+hostname+'\nServerPort=40000\n\n'
    else:
        text = '[ndbd]\nhostname='+hostname+'\nServerPort=40000\n\n'
    return text

def MGMToString(hostname, id=-1):
    if id > 0:
        text = '[ndb_mgmd]\nNodeId='+str(id)+'\nDataDir = /var/lib/mysql-mgmd-data\nPortNumber = 1186\nHostName = '+hostname+'\n\n'
    else:
        text = '[ndb_mgmd]\nDataDir = /var/lib/mysql-mgmd-data\nPortNumber = 1186\nHostName = '+hostname+'\n\n'
    return text

def deleteNodeFromFile(hostname):
    with open("config.ini","r") as fp:
        lines = fp.readlines()
    with open("config.ini","w") as fp:
        i = 0
        while i < len(lines):
            if re.match(".*"+hostname,lines[i]) != None:
                print lines[i]
                j = i
                while i > 0 and re.match("\[.*\]", lines[i]) == None:
                    i -= 1
                while j < len(lines) and re.match("\[.*\]", lines[j]) == None:
                    print(len(lines))
                    print j
                    j += 1
                del lines[i:j]
            i += 1
        for l in lines:
            fp.write(l)

    return 0

def appendNodeToFile(nodetype, hostname, id):
    with open("config.ini","a") as fp:
        if nodetype == 'sql':
            fp.write(SQLToString(hostname, id))
        elif nodetype == 'data':
            fp.write(DataToString(hostname, id))
        elif nodetype == 'management':
            fp.write(MGMToString(hostname, id))