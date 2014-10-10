import requests
import time
from threading import Thread
from functools import wraps
#from multiprocessing import Process

__all__ = ['configure_flows', 'wait_until', 'deconfigure_flows']

#class KeyWord(Process):
class KeyWord(Thread):
    def __init__(self, *args, **kwargs):
        super(KeyWord, self).__init__(*args, **kwargs)
        self._stop = False
        self._kw_result = None

    def stop(self):
        self._stop = True

    def result(self):
        return self._kw_result

def async_task(func):
    """Taken from http://code.activestate.com/recipes/576684-simple-threading-decorator/
    and modified
    """
    @wraps(func)
    def async_func(*args, **kwargs):
        func_hl = KeyWord(target = func, args = args, kwargs = kwargs)
        func_hl._Thread__args = (func_hl,) + func_hl._Thread__args
        #func_hl._args = (func_hl,) + func_hl._args
        func_hl.start()
        return func_hl

    return async_func


def wait_until(*tasks, **kwargs):
    tstart = time.time()

    timeout = 30
    if 'timeout' in kwargs:
        timeout = int(kwargs['timeout'])

    cnt = len(tasks)
    while time.time() < (timeout+tstart):
        tfinished = 0
        for t in tasks:
            if t.is_alive() == False:
                tfinished += 1
                continue
            t.join(timeout=0.2)
        if tfinished == cnt:
            return (time.time()-tstart)

    for t in tasks:
        if t.is_alive() == True:
            t.stop()
            #t.terminate()
            t.join()

    return (time.time()-tstart)

@async_task
def Example_of_robot_keyword(self, a, b, c):
    """be carefull, when calling this kw from robot,
    do not count on self, it is a thread object itself
    injected by decorator. The purpose is to make
    possibility to exit from thread on demand by 
    wait until keywork which makes thread.stop()
    if needed. In your fw you should use self._stop
    variable.


    robot sample:
    ${thread}=  Example Of Robot Keyword   a   b   c
    """
    while True:
        if self._stop == True:
            break



@async_task
def configure_flows(self, host, port, switchid, tableid, minid, maxid):
    flow_template = '''<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<flow xmlns="urn:opendaylight:flow:inventory">
    <strict>false</strict>
    <instructions>
        <instruction>
            <order>0</order>
            <apply-actions>
                <action>
                    <order>0</order>
                    <dec-nw-ttl/>
                </action>
            </apply-actions>
        </instruction>
    </instructions>
    <table_id>{}</table_id>
    <id>{}</id>
    <cookie_mask>255</cookie_mask>
    <installHw>false</installHw>
    <match>
        <ethernet-match>
            <ethernet-type>
                <type>2048</type>
            </ethernet-type>
        </ethernet-match>
        <ipv4-destination>10.0.1.0/24</ipv4-destination>
    </match>
    <cookie>1</cookie>
    <flow-name>FooXf{}</flow-name>
    <priority>{}</priority>
    <barrier>false</barrier>
</flow>'''

    self._kw_result = 0

    ses = requests.Session()

    for i in range(int(minid),int(maxid)+1):
        if self._stop == True:
            break
        fid = str(i)
        flow = flow_template.format(tableid,fid,fid,fid)
        url = 'http://{}:{}/restconf/config/opendaylight-inventory:nodes/node/openflow:{}/table/{}/flow/{}'.format(host,
            port, switchid, tableid, fid)

        try:
            rsp = ses.put(url, headers={'Content-Type':'application/xml'}, data=flow, timeout=3)
            if rsp.status_code == 200:
                self._kw_result += 1

        except Exception as e:
            pass


@async_task
def deconfigure_flows(self, host, port, switchid, tableid, minid, maxid):
    """Result will be the number of status code 200 returned"""
    self._kw_result = 0
    ses = requests.Session()

    for fid in range(int(minid),int(maxid)):
        if self._stop == True:
            break;
        url = 'http://{}:{}/restconf/config/opendaylight-inventory:nodes/node/openflow:{}/table/{}/flow/{}'.format(host,
            port, switchid, tableid, fid)

        try:
            rsp = ses.delete(url, headers={'Content-Type':'application/xml'}, timeout=3)
            if rsp.status_code == 200:
                self._kw_result += 1
        except Exception as e:
            pass
