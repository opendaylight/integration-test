import requests
from datetime import datetime

payloadstart='''{ "config:module": ['''
payloadend='''] }'''
connector='''{{
                "type": "odl-sal-netconf-connector-cfg:sal-netconf-connector",
                "name": "{}-sim-device",
                "odl-sal-netconf-connector-cfg:sleep-factor": 1.5,
                "odl-sal-netconf-connector-cfg:between-attempts-timeout-millis": 2000,
                "odl-sal-netconf-connector-cfg:address": "{}",
                "odl-sal-netconf-connector-cfg:username": "admin",
                "odl-sal-netconf-connector-cfg:dom-registry": {{
                    "type": "opendaylight-md-sal-dom:dom-broker-osgi-registry",
                    "name": "dom-broker"
                }},
                "odl-sal-netconf-connector-cfg:client-dispatcher": {{
                    "type": "odl-netconf-cfg:netconf-client-dispatcher",
                    "name": "global-netconf-dispatcher"
                }},
                "odl-sal-netconf-connector-cfg:password": "admin",
                "odl-sal-netconf-connector-cfg:default-request-timeout-millis": 60000,
                "odl-sal-netconf-connector-cfg:reconnect-on-changed-schema": true,
                "odl-sal-netconf-connector-cfg:binding-registry": {{
                    "type": "opendaylight-md-sal-binding:binding-broker-osgi-registry",
                    "name": "binding-osgi-broker"
                }},
                "odl-sal-netconf-connector-cfg:max-connection-attempts": 0,
                "odl-sal-netconf-connector-cfg:connection-timeout-millis": 10000000,
                "odl-sal-netconf-connector-cfg:tcp-only": false,
                "odl-sal-netconf-connector-cfg:event-executor": {{
                    "type": "netty:netty-event-executor",
                    "name": "global-event-executor"
                }},
                "odl-sal-netconf-connector-cfg:port": {},
                "odl-sal-netconf-connector-cfg:processing-executor": {{
                    "type": "threadpool:threadpool",
                    "name": "global-netconf-processing-executor"
                }}
            }}'''


def get_ttool_url():
    url = 'http://nexus.opendaylight.org/service/local/repositories/opendaylight.snapshot/content/org/opendaylight/controller/netconf-testtool/0.3.0-SNAPSHOT/'
    try:
        rsp = requests.get(url)
        if (rsp.status_code == 200):
            i = 0;
            j = 0;
            list = []
            while (i!=-1):
                i = rsp.text.find('<resourceURI>', j)
                j = rsp.text.find('</resourceURI>', i)
                res = rsp.text[i+13:j]
                if res[-15:]=='-executable.jar':
                    if res[:5]=='https':        ## replacing https with http
                        res=res[:4]+res[5:]
                    list.append(res)
            list.sort()
            name = list[-1][list[-1].rindex('/')+1:]
            return list[-1], name
        else:
            return '',''
    except:
        return '',''

def get_stressclient_url():
    url = 'http://nexus.opendaylight.org/service/local/repositories/opendaylight.snapshot/content/org/opendaylight/controller/netconf-testtool/0.3.0-SNAPSHOT/'
    try:
        rsp = requests.get(url)
        if (rsp.status_code == 200):
            i = 0;
            j = 0;
            list = []
            while (i!=-1):
                i = rsp.text.find('<resourceURI>', j)
                j = rsp.text.find('</resourceURI>', i)
                res = rsp.text[i+13:j]
                if res[-18:]=='-stress-client.jar':
                    if res[:5]=='https':        ## replacing https with http
                        res=res[:4]+res[5:]
                    list.append(res)
            list.sort()
            name = list[-1][list[-1].rindex('/')+1:]
            return list[-1], name
        else:
            return '',''
    except:
        return '',''

def get_num_of_connected(url):
    headers = {'accept': 'application/json'}
    numdev = 0
    numcon = 0
    cfgcon = 0
    try:
        rsp = requests.get(url, headers=headers, timeout=60)
        if (rsp.status_code == 200):
            for node in rsp.text.split('"id":"'):
                if node[0]!='{':
                    name = node.split('"')[0]
                    if 'sim-device' in name:
                        numdev += 1
                        if 'connected":' in node:
                            connected = node.split('connected":')[1][0]
                            if connected == 't':
                                numcon += 1
                    if 'controller-config' in name:
                        if 'connected":' in node:
                            connected = node.split('connected":')[1][0]
                            if connected == 't':
                                cfgcon += 1
            return cfgcon,numdev,numcon,rsp.status_code,len(rsp.text)
        else:
            return 0,0,0,rsp.status_code,len(rsp.text)
    except:
        return -1,-1,-1,-1,-1

def exceptions_list(dir):
    text_file = open(dir+"/log/karaf.log", "r")
    log = text_file.read()
    text_file.close()
    data = []
    lin_num = 0
    for line in log.splitlines():
        if 'Exception:' in line:
            if ('Caused by:' not in line) & (line[0:3]!='201'):
                data.append('Line '+str(lin_num)+":   "+line)
        lin_num+=1
    return data

def perf_add_cpu_mem_to_report(dir,cpus,cpunames,memory):
    text_file = open(dir+"/log/report.txt", "w")
    text_file.write('Number of CPUs: '+cpus+'\n')
    for cpu in cpunames.splitlines():
        text_file.write(cpu.split(':')[1]+'\n')
    text_file.write('\n')
    text_file.write('Initial machine memory in MB:\n')
    text_file.write(memory+'\n\n')
    text_file.close()

def add_to_report(dir,data):
    text_file = open(dir+"/log/report.txt", "a")
    text_file.write(data)
    text_file.close()

def get_pids(dir,log,processes):
    text_file = open(dir+"/log/processes.txt", "w")
    text_file.write('Monitored processes: ')
    for process in processes:
        text_file.write(process+' ')
    text_file.write('\n\n')
    pids = []
    for process in processes:
        text_file.write('Name: ')
        text_file.write(process+'\n')
        first = True
        for line in log.splitlines():
            if (process in line) & (not 'bash' in line):
                if first:
                    pids.append(line.strip().split(' ')[0])
                    text_file.write('PID: ')
                    text_file.write(pids[-1]+'\n')
                    first = False
                    text_file.write('Memory configuration: ')
                    if '-Xmx' in line:
                        text_file.write(line[line.index('-Xmx'):1+line.index(' ',line.index('-Xmx'))])
                    if '-XX:MaxPermSize' in line:
                        text_file.write(line[line.index('-XX:MaxPermSize'):1+line.index(' ',line.index('-XX:MaxPermSize'))])
                    if '-Xms' in line:
                        text_file.write(line[line.index('-Xms'):1+line.index(' ',line.index('-Xms'))])
                    text_file.write('\n')
                else:
                    print '*WARN* Multiple PIDs for process '+process
                    text_file.write('*WARN* Multiple PIDs for process '+process+'\n')
        if first:
            pids.append('0')
            text_file.write('PID: ')
            text_file.write('Not found\n')
            print '*WARN* Process '+process+' not found'
            text_file.write('*WARN* Process '+process+' not found\n')
        else:
            pass
        text_file.write('\n')
    text_file.write('\n\nProcesses:\n'+log)
    text_file.close()
    return pids

def check_pids(log,processes):
    pids = []
    started = True
    for process in processes:
        first = True
        for line in log.splitlines():
            if (process in line) & (not 'bash' in line):
                if first:
                    pids.append(line.strip().split(' ')[0])
                    first = False
                else:
                    print '*WARN* Multiple PIDs for process '+process
        if first:
            pids.append('0')
            started = False
        else:
            pass
    return started

def add_performance_data(dir,events):
    report = ''
    adding = True
    text_file = open(dir+"/log/perflog.txt", "r")
    log = text_file.read()
    text_file.close()
    text_file = open(dir+"/log/perflog.txt", "w")
    mem = []
    swap = []
    for data in log.splitlines():
        if 'KiB Mem' in data:
            mem.append(data)
        if 'KiB Swap' in data:
            swap.append(data)
    mem.sort()
    swap.sort()
    if not mem == []:
        report += 'Maximum machine memory usage:\n'
        report += mem[-1]+'\n'
        report += 'Maximum machine swap usage:\n'
        report += swap[-1]+'\n'
        report +='\n\n'
    start = datetime.strptime(events[0][0], "%Y-%m-%d %H:%M:%S.%f")
    time1 = start
    text_file.write('Events:                      start   duration\n')
    report += 'Events:                      start   duration\n'
    for i in range(0,len(events)):
        if i != len(events)-1:
            time2 = datetime.strptime(events[i+1][0], "%Y-%m-%d %H:%M:%S.%f")
        else:
            time2 = datetime.strptime(events[i][0], "%Y-%m-%d %H:%M:%S.%f")
        timedelta1 = (time2 - time1).total_seconds()
        timedelta2 = (time1 - start).total_seconds()
        text_file.write('{} {:10.3f} {:10.3f} - {}\n'.format(events[i][0],timedelta2,timedelta1,events[i][1]))
        report += '{} {:10.3f} {:10.3f} - {}\n'.format(events[i][0],timedelta2,timedelta1,events[i][1])
        time1 = time2
    text_file.write('\n\n\n')
    report += '\n\n\n'
    text_file.write(log)
    text_file.close()

    text_file = open(dir+"/log/processes.txt", "r")
    processes = text_file.read()
    text_file.close()
    text_file = open(dir+"/log/processes.txt", "w")
    pid = ''
    for line in processes.splitlines():
        if 'PID:' in line:
            pid = line.split()[1]
            if not pid.isdigit():
                pid = ''
        if pid.isdigit() & (line==''):
            mem = []
            cpu = []
            for data in log.splitlines():
                if data.strip().split(' ')[0] == pid:
                    memusage = data.strip().split()[5]
                    if memusage[-1]=='m':
                        memusage = float(memusage[:-1])*1024
                    elif memusage[-1]=='g':
                        memusage = float(memusage[:-1])*1024*1024
                    else:
                        memusage = float(memusage)
                    mem.append(memusage)
                    cpu.append(float(data.strip().split()[8]))
            if not mem == []:
                text_file.write('Memory usage in MB:   ')
                report += 'Memory usage in MB:   '
                text_file.write('Min: '+str(min(mem)/1024.0)+'  Max: '+str(max(mem)/1024.0)+'  Avg: '+str(sum(mem)/1024.0/len(mem))+'\n')
                report += 'Min: '+str(min(mem)/1024.0)+'  Max: '+str(max(mem)/1024.0)+'  Avg: '+str(sum(mem)/1024.0/len(mem))+'\n'
            if not cpu == []:
                text_file.write('CPU usage:            ')
                report += 'CPU usage:            '
                text_file.write('Min: '+str(min(cpu))+'  Max: '+str(max(cpu))+'  Avg: '+str(sum(cpu)/len(cpu))+'\n')
                report += 'Min: '+str(min(cpu))+'  Max: '+str(max(cpu))+'  Avg: '+str(sum(cpu)/len(cpu))+'\n'
            if not mem == []:
                text_file.write('  PID USER      PR  NI  VIRT  RES  SHR S  %CPU %MEM    TIME+  COMMAND\n')
            for data in log.splitlines():
                if data.strip().split(' ')[0] == pid:
                    text_file.write(data+'\n')
            pid = ''
        text_file.write(line+'\n')
        if 'Processes:' in line:
            adding = False
        if adding:
            report += line+'\n'
    text_file.close()
    add_to_report(dir,report)

def spawn_connectors(url,ttoolip,startport,amount):
    ses = requests.Session()
    headers = {'accept': 'application/json','content-type' : 'application/json'}
    payload = payloadstart
    code = -1
    for port in range(int(startport), int(startport)+int(amount)):
        payload = payload + connector.format(port,ttoolip,port)
        if port < int(startport)+int(amount)-1:
            payload = payload + ','
    payload = payload + payloadend

    try:
        request = requests.Request('POST', url, data=payload, headers=headers).prepare()
        rsp = ses.send(request)
        code = rsp.status_code
        return code
    except:
        code = -666
        return code
