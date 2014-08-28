__author__ = "Jan Medved"
__copyright__ = "Copyright(c) 2014, Cisco Systems, Inc."
__license__ = "New-style BSD"
__email__ = "jmedved@cisco.com"

from random import randrange
import json
import argparse
import requests
import time
import threading
import re

class Counter(object):
    def __init__(self, start=0):
        self.lock = threading.Lock()
        self.value = start
    def increment(self, value=1):
        self.lock.acquire()
        try:
            self.value = self.value + value
        finally:
            self.lock.release()


class Timer(object):
    def __init__(self, verbose=False):
        self.verbose = verbose

    def __enter__(self):
        self.start = time.time()
        return self

    def __exit__(self, *args):
        self.end = time.time()
        self.secs = self.end - self.start
        self.msecs = self.secs * 1000  # millisecs
        if self.verbose:
            print ("elapsed time: %f ms" % self.msecs)


putheaders = {'content-type': 'application/json'}
getheaders = {'Accept': 'application/json'}
# ODL IP:port
# We fist delete all existing service functions
DELURL  = "restconf/config/opendaylight-inventory:nodes/node/openflow:%d/table/0/flow/%d"
GETURL  = "restconf/config/opendaylight-inventory:nodes/node/openflow:%d/table/0/flow/%d"
# Incremental PUT. This URL is for a list element
PUTURL  = "restconf/config/opendaylight-inventory:nodes/node/openflow:%d/table/0/flow/%d"

INVURL = 'restconf/operational/opendaylight-inventory:nodes'
N1T0_URL = 'restconf/operational/opendaylight-inventory:nodes/node/openflow:1/table/0'


print_lock = threading.Lock()
threads_done = 0

JSON_FLOW_MOD1 = '''{
    "flow-node-inventory:flow": [
        {
            "flow-node-inventory:cookie": %d,
            "flow-node-inventory:cookie_mask": 65535,
            "flow-node-inventory:flow-name": "%s",
            "flow-node-inventory:hard-timeout": %d,
            "flow-node-inventory:id": "%s",
            "flow-node-inventory:idle-timeout": %d,
            "flow-node-inventory:installHw": false,
            "flow-node-inventory:instructions": {
                "flow-node-inventory:instruction": [
                    {
                        "flow-node-inventory:apply-actions": {
                            "flow-node-inventory:action": [
                                {
                                    "flow-node-inventory:dec-nw-ttl": {},
                                    "flow-node-inventory:order": 0
                                }
                            ]
                        },
                        "flow-node-inventory:order": 0
                    }
                ]
            },
            "flow-node-inventory:match": {
                "flow-node-inventory:metadata": {
                    "flow-node-inventory:metadata": %d
                }
            },
            "flow-node-inventory:priority": 2,
            "flow-node-inventory:strict": false,
            "flow-node-inventory:table_id": 0
        }
    ]
}'''

add_ok_rate = Counter(0.0)
add_total_rate = Counter(0.0)
del_ok_rate = Counter(0.0)
del_total_rate = Counter(0.0)

flows = {}

def add_flow(session, url_template, res, tid, node, flow_id, metadata):
    flow_data = JSON_FLOW_MOD1 % (tid + flow_id, 'TestFlow-%d' % flow_id, 65000,
                                  str(flow_id), 65000, metadata)
    flow_url = url_template % (node, flow_id)
    r = session.put(flow_url, data=flow_data, headers=putheaders, stream=False )

    try:
        res[r.status_code] += 1
    except(KeyError):
        res[r.status_code] = 1


def delete_flow(session, url_template, res, tid, node, flow_id):
    flow_url = url_template % (node, flow_id)
    r = session.delete(flow_url, headers=getheaders)
    try:
        res[r.status_code] += 1
    except(KeyError):
        res[r.status_code] = 1


def get_num_nodes(session, inventory_url, default_nodes):
    """
    Determines the number of OF nodes in the connected mininet network. If
    mininet is not connected, the default number of flows is 16
    """
    nodes = default_nodes
    r = session.get(inventory_url, headers=getheaders, stream=False )
    if (r.status_code == 200):
        try:
            inv = json.loads(r.content)['nodes']['node']
            nn = 0
            for n in range(len(inv)):
                if re.search('openflow', inv[n]['id']) != None:
                    nn = nn + 1
            if nn != 0:
                nodes = nn
        except(KeyError):
            pass

    return nodes

def add_flows(put_url, nnodes, nflows, start_flow, tid, cond):
    """
    The function that add flows into the ODL config space.
    """
    global threads_done

    add_res = {}
    add_res[200] = 0

    s = requests.Session()

    nnodes = get_num_nodes(s, inv_url, nnodes)

    with print_lock:
        print '    Thread %d:\n        Adding %d flows on %d nodes' % (tid, nflows, nnodes)

    with Timer() as t:
        for flow in range(nflows):
            node_id = randrange(1, nnodes+1)
            flow_id = tid*100000 + flow + start_flow
            flows[tid][flow_id] = node_id
            add_flow(s, put_url, add_res, tid, node_id, flow_id, flow*2+1)

    add_time = t.secs
    add_ok_rate_t = add_res[200]/add_time
    add_total_rate_t = sum(add_res.values())/add_time

    add_ok_rate.increment(add_ok_rate_t)
    add_total_rate.increment(add_total_rate_t)

    with print_lock:
        print '    Thread %d: ' % tid
        print '        Add time: %.2f,' % add_time
        print '        Add success rate:  %.2f, Add total rate: %.2f' % \
                        (add_ok_rate_t, add_total_rate_t)
        print '        Add Results: ',
        print add_res
        threads_done = threads_done + 1

    s.close()

    with cond:
        cond.notifyAll()


def delete_flows(del_url, nnodes, nflows, start_flow, tid, cond):
    """
    The function that deletes flow from the ODL config space that have been
    added using the 'add_flows()' function.
    """
    global threads_done

    del_res = {}
    del_res[200] = 0

    s = requests.Session()
    nnodes = get_num_nodes(s, inv_url, nnodes)

    with print_lock:
        print 'Thread %d: Deleting %d flows on %d nodes' % (tid, nflows, nnodes)

    with Timer() as t:
        for flow in range(nflows):
            flow_id = tid*100000 + flow + start_flow
            delete_flow(s, del_url, del_res, 100, flows[tid][flow_id], flow_id)

    del_time = t.secs

    del_ok_rate_t = del_res[200]/del_time
    del_total_rate_t = sum(del_res.values())/del_time

    del_ok_rate.increment(del_ok_rate_t)
    del_total_rate.increment(del_total_rate_t)

    with print_lock:
        print '    Thread %d: ' % tid
        print '        Delete time: %.2f,' % del_time
        print '        Delete success rate:  %.2f, Delete total rate: %.2f' % \
                        (del_ok_rate_t, del_total_rate_t)
        print '        Delete Results: ',
        print del_res
        threads_done = threads_done + 1

    s.close()

    with cond:
        cond.notifyAll()


def driver(function, ncycles, nthreads, nnodes, nflows, url, cond, ok_rate, total_rate):
    """
    The top-level driver function that drives the execution of the flow-add and
    flow-delete tests.
    """
    global threads_done

    for c in range(ncycles):
        with print_lock:
            print '\nCycle %d:' % c

        threads = []
        for i in range(nthreads):
            t = threading.Thread(target=function,
                                 args=(url, nnodes, nflows, c*nflows, i, cond))
            threads.append(t)
            t.start()

        # Wait for all threads to finish
        while threads_done < in_args.nthreads:
            with cond:
                cond.wait()

        with print_lock:
             print '    Overall success rate:  %.2f, Overall rate: %.2f' % \
                            (ok_rate.value, total_rate.value)
             threads_done = 0

        ok_rate.value = 0
        total_rate.value = 0


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Flow programming performance test: '
                                     'First adds and then deletes flows into '
                                     'the config tree, as specified by optional parameters.')
    parser.add_argument('--odlhost', default='127.0.0.1', help='Host where '
                        'odl controller is running (default is 127.0.0.1)')
    parser.add_argument('--odlport', default='8080', help='Port on '
                        'which odl\'s RESTCONF is listening (default is 8080)')
    parser.add_argument('--nflows', type=int, default=10, help='Number of '
                        'flow add/delete requests to send in  each cycle; default 10')
    parser.add_argument('--ncycles', type=int, default=1, help='Number of '
                        'flow add/delete cycles to send in each thread; default 1')
    parser.add_argument('--nthreads', type=int, default=1,
                        help='Number of request worker threads, default=1. '
                        'Each thread will add/delete nflows.')
    parser.add_argument('--nnodes', type=int, default=16,
                        help='Number of nodes if mininet is not connected, default=16. '
                        'If mininet is connected, flows will be evenly distributed '
                        '(programmed) into connected nodes.')
    parser.add_argument('--delete', dest='delete', action='store_true', default=True,
                        help='Delete all added flows one by one, benchmark delete '
                        'performance.')
    parser.add_argument('--no-delete', dest='delete', action='store_false',
                        help='Add flows and leave them in the config data store.')

    in_args = parser.parse_args()

    put_url = 'http://' + in_args.odlhost + ":" + in_args.odlport + '/' + PUTURL
    del_url = 'http://' + in_args.odlhost + ":" + in_args.odlport + '/' + DELURL
    get_url = 'http://' + in_args.odlhost + ":" + in_args.odlport + '/' + GETURL
    inv_url = 'http://' + in_args.odlhost + ":" + in_args.odlport + '/' + INVURL

    cond = threading.Condition()

    # Initialize the flows array
    for i in range(in_args.nthreads):
        flows[i] = {}

    # Run through ncycles, where nthreads are started in each cycles and
    # nflows added from each thread
    driver(add_flows, in_args.ncycles, in_args.nthreads, in_args.nnodes, \
           in_args.nflows, put_url, cond, add_ok_rate, add_total_rate)


    # Run through ncycles, where nthreads are started in each cycles and
    # nflows added from each thread
    if in_args.delete == True:
        driver(delete_flows, in_args.ncycles, in_args.nthreads, in_args.nnodes, \
               in_args.nflows, del_url, cond, del_ok_rate, del_total_rate)
