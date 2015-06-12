'''
The purpose of this library is the ability to spread configured flows
over the specified tables and switches.

The idea how to configure and checks inventory operational data is taken from
../../../../tools/odl-mdsal-clustering-tests/clustering-performance-test/flow_config_blaster.py
../../../../tools/odl-mdsal-clustering-tests/clustering-performance-test/inventory_crawler.py
'''
import random
import threading
import netaddr
import Queue
import requests
import json
import copy


class Counter(object):
    def __init__(self, start=0):
        self.lock = threading.Lock()
        self.value = start

    def increment(self, value=1):
        self.lock.acquire()
        val = self.value
        try:
            self.value += value
        finally:
            self.lock.release()
        return val


_spreads = ['gauss', 'linear', 'first']    # possible defined spreads at the moment
_default_flow_template_json = {
    u'flow': [
        {
            u'hard-timeout': 65000,
            u'idle-timeout': 65000,
            u'cookie_mask': 4294967295,
            u'flow-name': u'FLOW-NAME-TEMPLATE',
            u'priority': 2,
            u'strict': False,
            u'cookie': 0,
            u'table_id': 0,
            u'installHw': False,
            u'id': u'FLOW-ID-TEMPLATE',
            u'match': {
                u'ipv4-destination': u'0.0.0.0/32',
                u'ethernet-match': {
                    u'ethernet-type': {
                        u'type': 2048
                    }
                }
            },
            u'instructions': {
                u'instruction': [
                    {
                        u'order': 0,
                        u'apply-actions': {
                            u'action': [
                                {
                                    u'drop-action': {},
                                    u'order': 0
                                }
                            ]
                        }
                    }
                ]
            }
        }
    ]
}


def _get_notes(fldet=[]):
    '''For given list of flow details it produces a dictionary with statistics
    { swId1 : { tabId1 : flows_count1,
                tabId2 : flows_count2,
               ...
                'total' : switch count }
      swId2 ...
    }
    '''
    notes = {}
    for (sw, tab, flow) in fldet:
        if sw not in notes:
            notes[sw] = {'total': 0}
        if tab not in notes[sw]:
            notes[sw][tab] = 0
        notes[sw][tab] += 1
        notes[sw]['total'] += 1
    return notes


def _randomize(spread, maxn):
    '''Returns a randomized switch or table id'''
    if spread not in _spreads:
        raise Exception('Spread method {} not available'.format(spread))
    while True:
        if spread == 'gauss':
            ga = abs(random.gauss(0, 1))
            rv = int(ga*float(maxn)/3)
            if rv < maxn:
                return rv
        elif spread == 'linear':
            rv = int(random.random() * float(maxn))
            if rv < maxn:
                return rv
            else:
                raise ValueError('rv >= maxn')
        elif spread == 'first':
            return 0


def generate_new_flow_details(flows=10, switches=1, swspread='gauss', tables=250, tabspread='gauss'):
    """Generate a list of tupples (switch_id, table_id, flow_id) which are generated
    according to the spread rules between swithces and tables.
    It also returns a dictionary with statsistics."""
    swflows = [_randomize(swspread, switches) for f in range(int(flows))]
    fltables = [(s, _randomize(tabspread, tables), idx) for idx, s in enumerate(swflows)]
    notes = _get_notes(fltables)
    return fltables, notes


def _prepare_add(cntl, sw, tab, fl, ip, template=None):
    '''Creates a PUT http requests to configure a flow in configuration datastore'''
    url = 'http://'+cntl+':'+'8181'
    url += '/restconf/config/opendaylight-inventory:nodes/node/openflow:'+str(sw)+'/table/'+str(tab)+'/flow/'+str(fl)
    flow = copy.deepcopy(template['flow'][0])
    flow['cookie'] = fl
    flow['flow-name'] = 'TestFlow-%d' % fl
    flow['id'] = str(fl)
    flow['match']['ipv4-destination'] = '%s/32' % str(netaddr.IPAddress(ip))
    flow['table_id'] = tab
    fmod = dict(template)
    fmod['flow'] = flow
    req_data = json.dumps(fmod)
    req = requests.Request('PUT', url, headers={'Content-Type': 'application/json'}, data=req_data,
                           auth=('admin', 'admin'))
    return req


def _prepare_table_add(cntl, flows, template=None):
    '''Creates a POST http requests to configure a flow in configuration datastore'''
    f1 = flows[0]
    sw, tab, fl, ip = f1
    url = 'http://'+cntl+':'+'8181'
    url += '/restconf/config/opendaylight-inventory:nodes/node/openflow:'+str(sw)+'/table/'+str(tab)
    fdets = []
    for sw, tab, fl, ip in flows:
        flow = copy.deepcopy(template['flow'][0])
        flow['cookie'] = fl
        flow['flow-name'] = 'TestFlow-%d' % fl
        flow['id'] = str(fl)
        flow['match']['ipv4-destination'] = '%s/32' % str(netaddr.IPAddress(ip))
        flow['table_id'] = tab
        fdets.append(flow)
    fmod = dict(template)
    fmod['flow'] = fdets
    req_data = json.dumps(fmod)
    req = requests.Request('POST', url, headers={'Content-Type': 'application/json'}, data=req_data,
                           auth=('admin', 'admin'))
    return req


def _prepare_delete(cntl, sw, tab, fl, ip, template=None):
    '''Creates a DELETE http request to remove the flow from configuration datastore'''
    url = 'http://'+cntl+':'+'8181'
    url += '/restconf/config/opendaylight-inventory:nodes/node/openflow:'+str(sw)+'/table/'+str(tab)+'/flow/'+str(fl)
    req = requests.Request('DELETE', url, headers={'Content-Type': 'application/json'}, auth=('admin', 'admin'))
    return req


def _wt_request_sender(thread_id, preparefnc, inqueue=None, exitevent=None, controllers=[], restport='', template=None,
                       outqueue=None):
    '''The funcion runs in a thread. It reads out flow details from the queue and configures
    the flow on the controller'''
    ses = requests.Session()
    cntl = controllers[0]
    counter = [0 for i in range(600)]

    while True:
        try:
            (sw, tab, fl, ip) = inqueue.get(timeout=1)
            sw, tab, fl, ip = sw+1, tab, fl+1, ip
        except Queue.Empty:
            if exitevent.is_set() and inqueue.empty():
                break
            continue
        req = preparefnc(cntl, sw, tab, fl, ip, template=template)
        prep = ses.prepare_request(req)
        try:
            rsp = ses.send(prep, timeout=5)
        except requests.exceptions.Timeout:
            counter[99] += 1
            continue
        counter[rsp.status_code] += 1
    res = {}
    for i, v in enumerate(counter):
        if v > 0:
            res[i] = v
    outqueue.put(res)


def _wt_bulk_request_sender(thread_id, preparefnc, inqueue=None, exitevent=None, controllers=[], restport='',
                            template=None, outqueue=None):
    '''The funcion runs in a thread. It reads out flow details from the queue and configures
    the flow on the controller'''
    ses = requests.Session()
    cntl = controllers[0]
    counter = [0 for i in range(600)]
    loop = True

    while loop:
        try:
            flowlist = inqueue.get(timeout=1)
        except Queue.Empty:
            if exitevent.is_set() and inqueue.empty():
                loop = False
            continue
        req = preparefnc(cntl, flowlist, template=template)
        prep = ses.prepare_request(req)
        try:
            rsp = ses.send(prep, timeout=5)
        except requests.exceptions.Timeout:
            counter[99] += 1
            continue
        counter[rsp.status_code] += 1
    res = {}
    for i, v in enumerate(counter):
        if v > 0:
            res[i] = v
    outqueue.put(res)


def _config_task_executor(preparefnc, flow_details=[], flow_template=None, controllers=['127.0.0.1'], restport='8181',
                          nrthreads=1):
    '''Function starts thread executors and put required information to the queue. Executors read the queue and send
    http requests. After the thread's join, it produces a summary result.'''
    # TODO: multi controllers support
    ip_addr = Counter(int(netaddr.IPAddress('10.0.0.1')))
    if flow_template is not None:
        template = flow_template
    else:
        template = _default_flow_template_json

    # lets enlarge the tupple of flow details with IP, to be used with the template
    flows = [(s, t, f, ip_addr.increment()) for s, t, f in flow_details]

    # lets fill the qurue
    q = Queue.Queue()
    for f in flows:
        q.put(f)

    # result_gueue
    rq = Queue.Queue()
    # creaet exit event
    ee = threading.Event()

    # lets start threads whic will read flow details fro queues and send
    threads = []
    for i in range(int(nrthreads)):
        t = threading.Thread(target=_wt_request_sender, args=(i, preparefnc),
                             kwargs={"inqueue": q, "exitevent": ee, "controllers": controllers, "restport": restport,
                                     "template": template, "outqueue": rq})
        threads.append(t)
        t.start()

    ee.set()

    result = {}
    # waitng for them
    for t in threads:
        t.join()
        res = rq.get()
        for k, v in res.iteritems():
            if k not in result:
                result[k] = v
            else:
                result[k] += v
    return result


def configure_flows(*args, **kwargs):
    '''Configure flows based on given flow details
    Input parameters with default values: preparefnc, flow_details=[], flow_template=None,
                               controllers=['127.0.0.1'], restport='8181', nrthreads=1'''
    return _config_task_executor(_prepare_add, *args, **kwargs)


def deconfigure_flows(*args, **kwargs):
    '''Deconfigure flows based on given flow details.
    Input parameters with default values: preparefnc, flow_details=[], flow_template=None,
                               controllers=['127.0.0.1'], restport='8181', nrthreads=1'''
    return _config_task_executor(_prepare_delete, *args, **kwargs)


def _bulk_config_task_executor(preparefnc, flow_details=[], flow_template=None, controllers=['127.0.0.1'],
                               restport='8181', nrthreads=1, fpr=1):
    '''Function starts thread executors and put required information to the queue. Executors read the queue and send
    http requests. After the thread's join, it produces a summary result.'''
    # TODO: multi controllers support
    ip_addr = Counter(int(netaddr.IPAddress('10.0.0.1')))
    if flow_template is not None:
        template = flow_template
    else:
        template = _default_flow_template_json

    # lets enlarge the tupple of flow details with IP, to be used with the template
    flows = [(s, t, f, ip_addr.increment()) for s, t, f in flow_details]
    # lest divide flows into switches and tables
    fg = {}
    for fl in flows:
        s, t, f, ip = fl
        fk = (s, t)
        if (s, t) in fg:
            fg[fk].append(fl)
        else:
            fg[fk] = [fl]

    # lets fill the qurue
    q = Queue.Queue()
    for k, v in fg.iteritems():
        while len(v) > 0:
            q.put(v[:int(fpr)])
            v = v[int(fpr):]

    # result_gueue
    rq = Queue.Queue()
    # creaet exit event
    ee = threading.Event()

    # lets start threads whic will read flow details fro queues and send
    threads = []
    for i in range(int(nrthreads)):
        t = threading.Thread(target=_wt_bulk_request_sender, args=(i, preparefnc),
                             kwargs={"inqueue": q, "exitevent": ee, "controllers": controllers, "restport": restport,
                                     "template": template, "outqueue": rq})
        threads.append(t)
        t.start()

    ee.set()

    result = {}
    # waitng for them
    for t in threads:
        t.join()
        res = rq.get()
        for k, v in res.iteritems():
            if k not in result:
                result[k] = v
            else:
                result[k] += v
    return result


def configure_flows_bulk(*args, **kwargs):
    '''Configure flows based on given flow details
    Input parameters with default values: preparefnc, flow_details=[], flow_template=None,
                               controllers=['127.0.0.1'], restport='8181', nrthreads=1'''
    return _bulk_config_task_executor(_prepare_table_add, *args, **kwargs)


def _get_operational_inventory_of_switches(controller):
    '''GET requests to get operational inventory node details'''
    url = 'http://'+controller+':8181/restconf/operational/opendaylight-inventory:nodes'
    rsp = requests.get(url, headers={'Accept': 'application/json'}, stream=False, auth=('admin', 'admin'))
    if rsp.status_code != 200:
        return None
    inv = json.loads(rsp.content)
    if 'nodes' not in inv:
        return None
    if 'node' not in inv['nodes']:
        return []
    inv = inv['nodes']['node']
    switches = [sw for sw in inv if 'openflow:' in sw['id']]
    return switches


def flow_stats_collected(controller=''):
    '''Once flows are configured, thisfunction is used to check if flows are present in the operational datastore'''
    # print type(flow_details), flow_details
    active_flows = 0
    found_flows = 0
    switches = _get_operational_inventory_of_switches(controller)
    if switches is None:
        return 0, 0, 0
    for sw in switches:
        tabs = sw['flow-node-inventory:table']
        for t in tabs:
            active_flows += t['opendaylight-flow-table-statistics:flow-table-statistics']['active-flows']
            if 'flow' in t:
                found_flows += len(t['flow'])
    print "Switches,ActiveFlows(reported)/FlowsFound", len(switches), active_flows, found_flows
    return len(switches), active_flows, found_flows


def get_switches_count(controller=''):
    '''Count the switches presnt in the operational inventory nodes datastore'''
    switches = _get_operational_inventory_of_switches(controller)
    if switches is None:
        return 0
    return len(switches)
