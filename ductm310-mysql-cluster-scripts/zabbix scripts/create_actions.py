from pyzabbix import ZabbixAPI

ZABBIX_SERVER_ADDRESS="http://123.30.234.253:81/zabbix"

if __name__=='__main__':
    global zapi
    zapi = ZabbixAPI(ZABBIX_SERVER_ADDRESS)
    zapi.login("Admin","zabbix")
    print "Connected to Zabbix API Version %s" % zapi.api_version()
    
    zapi.action.create(
        name = "do on low disk space",
        def_longdata = "Trigger: {TRIGGER.NAME}\r\nTrigger status: {TRIGGER.STATUS}\r\nTrigger severity: {TRIGGER.SEVERITY}\r\nTrigger URL: {TRIGGER.URL}\r\n\r\nItem values:\r\n\r\n1. {ITEM.NAME1} ({HOST.NAME1}:{ITEM.KEY1}): {ITEM.VALUE1}\r\n2. {ITEM.NAME2} ({HOST.NAME2}:{ITEM.KEY2}): {ITEM.VALUE2}\r\n3. {ITEM.NAME3} ({HOST.NAME3}:{ITEM.KEY3}): {ITEM.VALUE3}\r\n\r\nOriginal event ID: {EVENT.ID}",
        def_shortdata = "{TRIGGER.STATUS}: {TRIGGER.NAME}",
        esc_period =    3600, #Default operation step duration
        eventsource = 0,
        evaltype = 1, #type of condition 1 = AND
        status = 0,
        conditions = [
            {
                "conditiontype": 5, #Trigger Value
                "operator": 0, # = 
                "value": 1 # PROBLEM
            },
            {
                "conditiontype": 4, # Trigger severity
                "operator": 0, # = 
                "value": 2 # Warning
            },
            {
                "conditiontype": 3, # Trigger name
                "operator": 2, # like
                "value": "Disk Free is lower than 10%"
            }
        ],
        operations = [
            {
                "operationtype": 1, # remote command
                "esc_step_from": 1, # do immediately
                "esc_step_to": 1,
                "esc_period": 0,
                "evaltype": 0, # custom script
                "opconditions": [
                ],
                "opcommand_grp": [
                ],
                "opcommand_hst": [ # target lists
                    {
                        "hostid": 0,    # current host
                        "opcommand_hstid": 1
                    }
                ],
                "opcommand": {
                    "type": 0,
                    "scriptid": 0,
                    "execute_on": 0, # 0 --> zabbix agent, 1 --> zabbix server
                    "command": "touch /tmp/hello.txt", # command HERE
                    "authtype": 0
                }
            }
        ]
    )
    
    zapi.action.create(
        name = "do when mysql sql overload",
        def_longdata = "Trigger: {TRIGGER.NAME}\r\nTrigger status: {TRIGGER.STATUS}\r\nTrigger severity: {TRIGGER.SEVERITY}\r\nTrigger URL: {TRIGGER.URL}\r\n\r\nItem values:\r\n\r\n1. {ITEM.NAME1} ({HOST.NAME1}:{ITEM.KEY1}): {ITEM.VALUE1}\r\n2. {ITEM.NAME2} ({HOST.NAME2}:{ITEM.KEY2}): {ITEM.VALUE2}\r\n3. {ITEM.NAME3} ({HOST.NAME3}:{ITEM.KEY3}): {ITEM.VALUE3}\r\n\r\nOriginal event ID: {EVENT.ID}",
        def_shortdata = "{TRIGGER.STATUS}: {TRIGGER.NAME}",
        esc_period =    3600, #Default operation step duration
        eventsource = 0,
        evaltype = 1, #type of condition 1 = AND
        status = 0,
        conditions = [
            {
                "conditiontype": 5, #Trigger Value
                "operator": 0, # = 
                "value": 1 # PROBLEM
            },
            {
                "conditiontype": 4, # Trigger severity
                "operator": 0, # = 
                "value": 2 # Warning
            },
            {
                "conditiontype": 3, # Trigger name
                "operator": 2, # like
                "value": "MySQL SQL overload"
            }
        ],
        operations = [
            {
                "operationtype": 1, # remote command
                "esc_step_from": 1, # do immediately
                "esc_step_to": 1,
                "esc_period": 0,
                "evaltype": 0, # custom script
                "opconditions": [
                ],
                "opcommand_grp": [
                ],
                "opcommand_hst": [ # target lists
                    {
                        "hostid": 0,    # current host
                        "opcommand_hstid": 1
                    }
                ],
                "opcommand": {
                    "type": 0,
                    "scriptid": 0,
                    "execute_on": 1, # 0 --> zabbix agent, 1 --> zabbix server
                    "command": "python /script/create_sql.py sql", # command HERE
                    "authtype": 0
                }
            }
        ]
    )
