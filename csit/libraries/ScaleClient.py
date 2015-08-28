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
_default_flow_template_json = {  # templease used for config datastore
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


_node_tmpl = "/opendaylight-inventory:nodes/opendaylight-inventory:node[opendaylight-inventory:id=\"openflow:{0}\"]"


_default_operations_item_json = {  # template used for sal operations
    "input": {
        "bulk-flow-item": [
            {
                "node": "to_be_replaced",
                "cookie": 0,
                "cookie_mask": 4294967295,
                "flags": "SEND_FLOW_REM",
                "hard-timeout": 65000,
                "idle-timeout": 65000,
                "instructions": {
                    "instruction": [{
                        "apply-actions": {
                            "action": [
                                {
                                    "drop-action": {},
                                    "order": 0
                                }
                            ]
                        },
                        "order": 0
                    }]
                },
                "match": {
                    "ipv4-destination": "0.0.0.0/32",
                    "ethernet-match": {
                        "ethernet-type": {
                            "type": 2048
                        }
                    },
                },
                "priority": 2,
                "table_id": 0
            }
        ]
    }
}


def _get_notes(fldet=[]):
    """For given list of flow details it produces a dictionary with statistics
    { swId1 : { tabId1 : flows_count1,
                tabId2 : flows_count2,
               ...
                'total' : switch count }
      swId2 ...
    }
    """
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
    """Returns a randomized switch or table id"""
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
    # we have to increse the switch index because mininet start indexing switches from 1 (not 0)
    fltables = [(s+1, _randomize(tabspread, tables), idx) for idx, s in enumerate(swflows)]
    notes = _get_notes(fltables)
    return fltables, notes


def _prepare_add(cntl, method, flows, template=None):
    """Creates a PUT http requests to configure a flow in configuration datastore.

    Args:
        :param cntl: controller's ip address or hostname

        :param method: determines http request method

        :param flows: list of flow details

        :param template: flow template to be to be filled

    Returns:
        :returns req: http request object
    """
    fl1 = flows[0]
    sw, tab, fl, ip = fl1
    url = 'http://' + cntl + ':' + '8181'
    url += '/restconf/config/opendaylight-inventory:nodes/node/openflow:' + str(sw)
    url += '/table/' + str(tab) + '/flow/' + str(fl)
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


def _prepare_table_add(cntl, method, flows, template=None):
    """Creates a POST http requests to configure a flow in configuration datastore.

    Args:
        :param cntl: controller's ip address or hostname

        :param method: determines http request method

        :param flows: list of flow details

        :param template: flow template to be to be filled

    Returns:
        :returns req: http request object
    """
    fl1 = flows[0]
    sw, tab, fl, ip = fl1
    url = 'http://' + cntl + ':' + '8181'
    url += '/restconf/config/opendaylight-inventory:nodes/node/openflow:' + str(sw) + '/table/' + str(tab)
    fdets = []
    for sw, tab, fl, ip in flows:
        flow = copy.deepcopy(template['flow'][0])
        flow['cookie'] = fl
        flow['flow-name'] = 'TestFlow-%d' % fl
        flow['id'] = str(fl)
        flow['match']['ipv4-destination'] = '%s/32' % str(netaddr.IPAddress(ip))
        flow['table_id'] = tab
        fdets.append(flow)
    fmod = copy.deepcopy(template)
    fmod['flow'] = fdets
    req_data = json.dumps(fmod)
    req = requests.Request('POST', url, headers={'Content-Type': 'application/json'}, data=req_data,
                           auth=('admin', 'admin'))
    return req


def _prepare_delete(cntl, method, flows, template=None):
    """Creates a DELETE http request to remove the flow from configuration datastore.

    Args:
        :param cntl: controller's ip address or hostname

        :param method: determines http request method

        :param flows: list of flow details

        :param template: flow template to be to be filled

    Returns:
        :returns req: http request object
    """
    fl1 = flows[0]
    sw, tab, fl, ip = fl1
    url = 'http://' + cntl + ':' + '8181'
    url += '/restconf/config/opendaylight-inventory:nodes/node/openflow:' + str(sw)
    url += '/table/' + str(tab) + '/flow/' + str(fl)
    req = requests.Request('DELETE', url, headers={'Content-Type': 'application/json'}, auth=('admin', 'admin'))
    return req


def _prepare_rpc_item(cntl, method, flows, template=None):
    """Creates a POST http requests to add or remove a flow using openflowplugin rpc.

    Args:
        :param cntl: controller's ip address or hostname

        :param method: determines http request method

        :param flows: list of flow details

        :param template: flow template to be to be filled

    Returns:
        :returns req: http request object
    """
    f1 = flows[0]
    sw, tab, fl, ip = f1
    url = 'http://' + cntl + ':' + '8181/restconf/operations/sal-bulk-flow:' + method
    fdets = []
    for sw, tab, fl, ip in flows:
        flow = copy.deepcopy(template['input']['bulk-flow-item'][0])
        flow['node'] = _node_tmpl.format(sw)
        flow['cookie'] = fl
        flow['flow-name'] = 'TestFlow-%d' % fl
        flow['match']['ipv4-destination'] = '%s/32' % str(netaddr.IPAddress(ip))
        flow['table_id'] = tab
        fdets.append(flow)
    fmod = copy.deepcopy(template)
    fmod['input']['bulk-flow-item'] = fdets
    req_data = json.dumps(fmod)
    req = requests.Request('POST', url, headers={'Content-Type': 'application/json'}, data=req_data,
                           auth=('admin', 'admin'))
    return req


def _prepare_ds_item(cntl, method, flows, template=None):
    """Creates a POST http requests to configure a flow in configuration datastore.

    Ofp uses write operation, standrd POST to config datastore uses read-write operation (on java level)

    Args:
        :param cntl: controller's ip address or hostname

        :param method: determines http request method

        :param flows: list of flow details

        :param template: flow template to be to be filled

    Returns:
        :returns req: http request object
    """
    f1 = flows[0]
    sw, tab, fl, ip = f1
    url = 'http://' + cntl + ':' + '8181/restconf/operations/sal-bulk-flow:' + method
    fdets = []
    for sw, tab, fl, ip in flows:
        flow = copy.deepcopy(template['input']['bulk-flow-item'][0])
        flow['node'] = _node_tmpl.format(sw)
        flow['cookie'] = fl
        flow['flow-name'] = 'TestFlow-%d' % fl
        flow['match']['ipv4-destination'] = '%s/32' % str(netaddr.IPAddress(ip))
        flow['table_id'] = tab
        flow['flow-id'] = fl
        fdets.append(flow)
    fmod = copy.deepcopy(template)
    del fmod['input']['bulk-flow-item']
    fmod['input']['bulk-flow-ds-item'] = fdets
    req_data = json.dumps(fmod)
    req = requests.Request('POST', url, headers={'Content-Type': 'application/json'}, data=req_data,
                           auth=('admin', 'admin'))
    return req


def _wt_request_sender(thread_id, preparefnc, inqueue=None, exitevent=None, controllers=[], restport='',
                       template=None, outqueue=None, method=None):
    """The funcion sends http requests.

    Runs in the working thread. It reads out flow details from the queue and sends apropriate http requests
    to the controller

    Args:
        :param thread_id: thread id

        :param preparefnc: function to preparesthe http request

        :param inqueue: input queue, flow details are comming from here

        :param exitevent: event to notify working thread that parent (task executor) stopped filling the input queue

        :param controllers: a list of controllers' ip addresses or hostnames

        :param restport: restconf port

        :param template: flow template used for creating flow content

        :param outqueue: queue where the results should be put

        :param method: method derermines the type of http request

    Returns:
        nothing, results must be put into the output queue
    """
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
        req = preparefnc(cntl, method, flowlist, template=template)
        # prep = ses.prepare_request(req)
        prep = req.prepare()
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


def _task_executor(method='', flow_template=None, flow_details=[], controllers=['127.0.0.1'],
                   restport='8181', nrthreads=1, fpr=1):
    """The main function which drives sending of http requests.

    Creates 2 queues and requested number of 'working threads'.  One queue is filled with flow details and working
    threads read them out and send http requests. The other queue is for sending results from working threads back.
    After the threads' join, it produces a summary result.

    Args:
        :param method: based on this the function which prepares http request is choosen

        :param flow_template: template to generate a flow content

        :param flow_details: a list of tupples with flow details (switch_id, table_id, flow_id, ip_addr) (default=[])

        :param controllers: a list of controllers host names or ip addresses (default=['127.0.0.1'])

        :param restport: restconf port (default='8181')

        :param nrthreads: number of threads used to send http requests (default=1)

        :param fpr: flow per request, number of flows sent in one http request

    Returns:
        :returns dict: dictionary of http response counts like {'http_status_code1: 'count1', etc.}
    """
    # TODO: multi controllers support
    ip_addr = Counter(int(netaddr.IPAddress('10.0.0.1')))

    # choose message prepare function
    if method == 'PUT':
        preparefnc = _prepare_add
        # put can contain only 1 flow, lets overwrite any value of flows per request
        fpr = 1
    elif method == 'POST':
        preparefnc = _prepare_table_add
    elif method == 'DELETE':
        preparefnc = _prepare_delete
        # delete flow can contain only 1 flow, lets overwrite any value of flows per request
        fpr = 1
    elif method in ['add-flows-ds', 'remove-flows-ds']:
        preparefnc = _prepare_ds_item
    elif method in ['add-flows-rpc', 'remove-flows-rpc']:
        preparefnc = _prepare_rpc_item
    else:
        raise NotImplementedError('Method {0} does not have it\'s prepeare function defined'.format(method))

    # lets enlarge the tupple of flow details with IP, to be used with the template
    flows = [(sw, tab, flo, ip_addr.increment()) for sw, tab, flo in flow_details]
    # lels divide flows into switches and tables - flow groups
    flowgroups = {}
    for flow in flows:
        sw, tab, _, _ = flow
        flowkey = (sw, tab)
        if flowkey in flowgroups:
            flowgroups[flowkey].append(flow)
        else:
            flowgroups[flowkey] = [flow]

    # lets fill the queue with details needed for one http requests
    # we have lists with flow details for particular (switch, table) tupples, now we need to split the lists
    # according to the flows per request (fpr) paramer
    sendqueue = Queue.Queue()
    for flowgroup, flow_list in flowgroups.iteritems():
        while len(flow_list) > 0:
            sendqueue.put(flow_list[:int(fpr)])
            flow_list = flow_list[int(fpr):]

    # result_gueue
    resultqueue = Queue.Queue()
    # creaet exit event
    exitevent = threading.Event()

    # lets start threads whic will read flow details fro queues and send
    threads = []
    for i in range(int(nrthreads)):
        thr = threading.Thread(target=_wt_request_sender, args=(i, preparefnc),
                               kwargs={"inqueue": sendqueue, "exitevent": exitevent,
                                       "controllers": controllers, "restport": restport,
                                       "template": flow_template, "outqueue": resultqueue, "method": method})
        threads.append(thr)
        thr.start()

    exitevent.set()

    result = {}
    # waitng for reqults and sum them up
    for t in threads:
        t.join()
        # reading partial resutls from sender thread
        part_result = resultqueue.get()
        for k, v in part_result.iteritems():
            if k not in result:
                result[k] = v
            else:
                result[k] += v
    return result


def configure_flows(*args, **kwargs):
    """Configure flows based on given flow details.

    Args:
        :param flow_details: a list of tupples with flow details (switch_id, table_id, flow_id, ip_addr) (default=[])

        :param controllers: a list of controllers host names or ip addresses (default=['127.0.0.1'])

        :param restport: restconf port (default='8181')

        :param nrthreads: number of threads used to send http requests (default=1)

    Returns:
        :returns dict: dictionary of http response counts like {'http_status_code1: 'count1', etc.}
    """
    return _task_executor(method='PUT', flow_template=_default_flow_template_json, **kwargs)


def deconfigure_flows(*args, **kwargs):
    """Deconfigure flows based on given flow details.

    Args:
        :param flow_details: a list of tupples with flow details (switch_id, table_id, flow_id, ip_addr) (default=[])

        :param controllers: a list of controllers host names or ip addresses (default=['127.0.0.1'])

        :param restport: restconf port (default='8181')

        :param nrthreads: number of threads used to send http requests (default=1)

    Returns:
        :returns dict: dictionary of http response counts like {'http_status_code1: 'count1', etc.}
    """
    return _task_executor(method='DELETE', flow_template=_default_flow_template_json, **kwargs)


def configure_flows_bulk(*args, **kwargs):
    """Configure flows based on given flow details using a POST http request..

    Args:
        :param flow_details: a list of tupples with flow details (switch_id, table_id, flow_id, ip_addr) (default=[])

        :param controllers: a list of controllers host names or ip addresses (default=['127.0.0.1'])

        :param restport: restconf port (default='8181')

        :param nrthreads: number of threads used to send http requests (default=1)

    Returns:
        :returns dict: dictionary of http response counts like {'http_status_code1: 'count1', etc.}
    """
    return _task_executor(method='POST', flow_template=_default_flow_template_json, **kwargs)


def operations_add_flows_ds(*args, **kwargs):
    """Configure flows based on given flow details.

    Args:
        :param flow_details: a list of tupples with flow details (switch_id, table_id, flow_id, ip_addr) (default=[])

        :param controllers: a list of controllers host names or ip addresses (default=['127.0.0.1'])

        :param restport: restconf port (default='8181')

        :param nrthreads: number of threads used to send http requests (default=1)

    Returns:
        :returns dict: dictionary of http response counts like {'http_status_code1: 'count1', etc.}
    """
    return _task_executor(method='add-flows-ds', flow_template=_default_operations_item_json, **kwargs)


def operations_remove_flows_ds(*args, **kwargs):
    """Remove flows based on given flow details.

    Args:
        :param flow_details: a list of tupples with flow details (switch_id, table_id, flow_id, ip_addr) (default=[])

        :param controllers: a list of controllers host names or ip addresses (default=['127.0.0.1'])

        :param restport: restconf port (default='8181')

        :param nrthreads: number of threads used to send http requests (default=1)

    Returns:
        :returns dict: dictionary of http response counts like {'http_status_code1: 'count1', etc.}
    """
    return _task_executor(method='remove-flows-ds', flow_template=_default_operations_item_json, **kwargs)


def operations_add_flows_rpc(*args, **kwargs):
    """Configure flows based on given flow details using rpc calls.

    Args:
        :param flow_details: a list of tupples with flow details (switch_id, table_id, flow_id, ip_addr) (default=[])

        :param controllers: a list of controllers host names or ip addresses (default=['127.0.0.1'])

        :param restport: restconf port (default='8181')

        :param nrthreads: number of threads used to send http requests (default=1)

    Returns:
        :returns dict: dictionary of http response counts like {'http_status_code1: 'count1', etc.}
    """
    return _task_executor(method='add-flows-rpc', flow_template=_default_operations_item_json, **kwargs)


def operations_remove_flows_rpc(*args, **kwargs):
    """Remove flows based on given flow details using rpc calls.

    Args:
        :param flow_details: a list of tupples with flow details (switch_id, table_id, flow_id, ip_addr) (default=[])

        :param controllers: a list of controllers host names or ip addresses (default=['127.0.0.1'])

        :param restport: restconf port (default='8181')

        :param nrthreads: number of threads used to send http requests (default=1)

    Returns:
        :returns dict: dictionary of http response counts like {'http_status_code1: 'count1', etc.}
    """
    return _task_executor(method='remove-flows-rpc', flow_template=_default_operations_item_json, **kwargs)


def _get_operational_inventory_of_switches(controller):
    """Gets number of switches present in the operational inventory

    Args:
        :param controller: controller's ip or host name

    Returns:
        :returns switches: number of switches connected
    """
    url = 'http://' + controller + ':8181/restconf/operational/opendaylight-inventory:nodes'
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
    """Provides the operational inventory counts counts of switches and flows.

    Args:
        :param controller: controller's ip address or host name

    Returns:
        :returns (switches, flows_reported, flows-found): tupple with counts of switches, reported and found flows
    """
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
    """Gives the count of the switches presnt in the operational inventory nodes datastore.

    Args:
        :param controller: controller's ip address or host name

    Returns:
        :returns switches: returns the number of connected switches
    """
    switches = _get_operational_inventory_of_switches(controller)
    if switches is None:
        return 0
    return len(switches)


def validate_responses(received, expected):
    """Compares given response summary with expected results.

    Args:
        :param received: dictionary returned from operations_* and (de)configure_flows*
                         of this library
                         e.g. received = { 200:41 } - this means that we 41x receives response with status code 200

        :param expected: list of expected http result codes
                         e.g. expected=[200] - we expect only http status 200 to be present

    Returns:
        :returns True: if list of http statuses from received responses is the same as exxpected
        :returns False: elseware
    """
    return True if received.keys() == expected else False
