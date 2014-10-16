#!/usr/bin/python
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
import netaddr


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


class FlowConfigBlaster(object):
    putheaders = {'content-type': 'application/json'}
    getheaders = {'Accept': 'application/json'}

    FLWURL = "restconf/config/opendaylight-inventory:nodes/node/openflow:%d/table/0/flow/%d"
    INVURL = 'restconf/operational/opendaylight-inventory:nodes'

    ok_total = 0

    flows = {}

    def __init__(self, host, port, ncycles, nthreads, nnodes, nflows, startflow, auth, json_template):
        self.host = host
        self.port = port
        self.ncycles = ncycles
        self.nthreads = nthreads
        self.nnodes = nnodes
        self.nflows = nflows
        self.startflow = startflow
        self.auth = auth

        self.json_template = json_template
        self.url_template = 'http://' + self.host + ":" + self.port + '/' + self.FLWURL

        self.ok_rate = Counter(0.0)
        self.total_rate = Counter(0.0)

        self.ip_addr = Counter(int(netaddr.IPAddress('10.0.0.1')) + startflow)


        self.print_lock = threading.Lock()
        self.cond = threading.Condition()
        self.threads_done = 0

        for i in range(self.nthreads):
            self.flows[i] = {}


    def get_num_nodes(self, session):
        """
        Determines the number of OF nodes in the connected mininet network. If mininet is not connected, the default
        number of flows is 16
        """
        inventory_url = 'http://' + self.host + ":" + self.port + '/' + self.INVURL
        nodes = self.nnodes

        if not self.auth:
            r = session.get(inventory_url, headers=self.getheaders, stream=False)
        else:
            r = session.get(inventory_url, headers=self.getheaders, stream=False, auth=('admin', 'admin'))

        if r.status_code == 200:
            try:
                inv = json.loads(r.content)['nodes']['node']
                nn = 0
                for n in range(len(inv)):
                    if re.search('openflow', inv[n]['id']) is not None:
                        nn += 1
                if nn != 0:
                    nodes = nn
            except KeyError:
                pass

        return nodes


    def add_flow(self, session, tid, node, flow_id, ipaddr):
        """
        Adds a single flow to the config data store via REST
        """
        flow_data = self.json_template % (tid + flow_id, 'TestFlow-%d' % flow_id, 65000,
                                          str(flow_id), 65000, str(netaddr.IPAddress(ipaddr)))
        # print flow_data
        flow_url = self.url_template % (node, flow_id)
        # print flow_url

        if not self.auth:
            r = session.put(flow_url, data=flow_data, headers=self.putheaders, stream=False)
        else:
            r = session.put(flow_url, data=flow_data, headers=self.putheaders, stream=False, auth=('admin', 'admin'))

        return r.status_code


    def add_flows(self, start_flow, tid):
        """
        Adds flows into the ODL config space. This function is executed by a worker thread
        """

        add_res = {200: 0}

        s = requests.Session()

        n_nodes = self.get_num_nodes(s)

        with self.print_lock:
            print '    Thread %d:\n        Adding %d flows on %d nodes' % (tid, self.nflows, n_nodes)

        with Timer() as t:
            for flow in range(self.nflows):
                node_id = randrange(1, n_nodes + 1)
                flow_id = tid * (self.ncycles * self.nflows) + flow + start_flow + self.startflow
                self.flows[tid][flow_id] = node_id
                sts = self.add_flow(s, tid, node_id, flow_id, self.ip_addr.increment())
                try:
                    add_res[sts] += 1
                except KeyError:
                    add_res[sts] = 1

        add_time = t.secs
        add_ok_rate = add_res[200] / add_time
        add_total_rate = sum(add_res.values()) / add_time

        self.ok_rate.increment(add_ok_rate)
        self.total_rate.increment(add_total_rate)

        with self.print_lock:
            print '    Thread %d: ' % tid
            print '        Add time: %.2f,' % add_time
            print '        Add success rate:  %.2f, Add total rate: %.2f' % (add_ok_rate, add_total_rate)
            print '        Add Results: ',
            print add_res
            self.ok_total += add_res[200]
            self.threads_done += 1

        s.close()

        with self.cond:
            self.cond.notifyAll()


    def delete_flow(self, session, node, flow_id):
        """
        Deletes a single flow from the ODL config data store via REST

        :param session:
        :param url_template:
        :param node:
        :param flow_id:
        :return:
        """
        flow_url = self.url_template % (node, flow_id)

        if not self.auth:
            r = session.delete(flow_url, headers=self.getheaders)
        else:
            r = session.delete(flow_url, headers=self.getheaders, auth=('admin', 'admin'))

        return r.status_code


    def delete_flows(self, start_flow, tid):
        """
        Deletes flow from the ODL config space that have been added using the 'add_flows()' function. This function is
        executed by a worker thread
        """
        del_res = {200: 0}

        s = requests.Session()
        n_nodes = self.get_num_nodes(s)

        with self.print_lock:
            print 'Thread %d: Deleting %d flows on %d nodes' % (tid, self.nflows, n_nodes)

        with Timer() as t:
            for flow in range(self.nflows):
                flow_id = tid * (self.ncycles * self.nflows) + flow + start_flow + self.startflow
                sts = self.delete_flow(s, self.flows[tid][flow_id], flow_id)
                try:
                    del_res[sts] += 1
                except KeyError:
                    del_res[sts] = 1

        del_time = t.secs

        del_ok_rate = del_res[200] / del_time
        del_total_rate = sum(del_res.values()) / del_time

        self.ok_rate.increment(del_ok_rate)
        self.total_rate.increment(del_total_rate)

        with self.print_lock:
            print '    Thread %d: ' % tid
            print '        Delete time: %.2f,' % del_time
            print '        Delete success rate:  %.2f, Delete total rate: %.2f' % (del_ok_rate, del_total_rate)
            print '        Delete Results: ',
            print del_res
            self.threads_done += 1

        s.close()

        with self.cond:
            self.cond.notifyAll()


    def run_cycle(self, function):
        """
        Runs an add or delete cycle. Starts a number of worker threads that each add a bunch of flows. Work is done
        in context of the worker threads
        """

        for c in range(self.ncycles):
            with self.print_lock:
                print '\nCycle %d:' % c

            threads = []
            for i in range(self.nthreads):
                t = threading.Thread(target=function, args=(c * self.nflows, i))
                threads.append(t)
                t.start()

            # Wait for all threads to finish and measure the execution time
            with Timer() as t:
                while self.threads_done < self.nthreads:
                    with self.cond:
                        self.cond.wait()

            with self.print_lock:
                print '    Total success rate: %.2f, Total rate: %.2f' % (
                      self.ok_rate.value, self.total_rate.value)
                measured_rate = self.nthreads * self.nflows * self.ncycles / t.secs
                print '    Measured rate:      %.2f (%.2f%% of Total success rate)' % \
                      (measured_rate, measured_rate / self.total_rate.value * 100)
                self.threads_done = 0

            self.ok_rate.value = 0
            self.total_rate.value = 0


    def add_blaster(self):
        self.run_cycle(self.add_flows)

    def delete_blaster(self):
        self.run_cycle(self.delete_flows)

    def get_total_flows(self):
        return sum(len(self.flows[key]) for key in self.flows.keys())

    def get_ok_flows(self):
        return self.ok_total


def get_json_from_file(filename):
    with open(filename, 'r') as f:
        read_data = f.read()
    return read_data


if __name__ == "__main__":

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
                                        "flow-node-inventory:drop-action": {},
                                        "flow-node-inventory:order": 0
                                    }
                                ]
                            },
                            "flow-node-inventory:order": 0
                        }
                    ]
                },
                "flow-node-inventory:match": {
                    "flow-node-inventory:ipv4-destination": "%s/32",
                    "flow-node-inventory:ethernet-match": {
                        "flow-node-inventory:ethernet-type": {
                            "flow-node-inventory:type": 2048
                        }
                    }
                },
                "flow-node-inventory:priority": 2,
                "flow-node-inventory:strict": false,
                "flow-node-inventory:table_id": 0
            }
        ]
    }'''

    parser = argparse.ArgumentParser(description='Flow programming performance test: First adds and then deletes flows '
                                                 'into the config tree, as specified by optional parameters.')

    parser.add_argument('--host', default='127.0.0.1',
                        help='Host where odl controller is running (default is 127.0.0.1)')
    parser.add_argument('--port', default='8181',
                        help='Port on which odl\'s RESTCONF is listening (default is 8181)')
    parser.add_argument('--cycles', type=int, default=1,
                        help='Number of flow add/delete cycles; default 1. Both Flow Adds and Flow Deletes are '
                             'performed in cycles. <THREADS> worker threads are started in each cycle and the cycle '
                             'ends when all threads finish. Another cycle is started when the previous cycle finished.')
    parser.add_argument('--threads', type=int, default=1,
                        help='Number of request worker threads to start in each cycle; default=1. '
                             'Each thread will add/delete <FLOWS> flows.')
    parser.add_argument('--flows', type=int, default=10,
                        help='Number of flows that will be added/deleted by each worker thread in each cycle; '
                             'default 10')
    parser.add_argument('--nodes', type=int, default=16,
                        help='Number of nodes if mininet is not connected; default=16. If mininet is connected, '
                             'flows will be evenly distributed (programmed) into connected nodes.')
    parser.add_argument('--delay', type=int, default=0,
                        help='Time (in seconds) to wait between the add and delete cycles; default=0')
    parser.add_argument('--delete', dest='delete', action='store_true', default=True,
                        help='Delete all added flows one by one, benchmark delete '
                             'performance.')
    parser.add_argument('--no-delete', dest='delete', action='store_false',
                        help='Do not perform the delete cycle.')
    parser.add_argument('--auth', dest='auth', action='store_true', default=False,
                        help="Use the ODL default username/password 'admin'/'admin' to authenticate access to REST; "
                             'default: no authentication')
    parser.add_argument('--startflow', type=int, default=0,
                        help='The starting Flow ID; default=0')
    parser.add_argument('--file', default='',
                        help='File from which to read the JSON flow template; default: no file, use a built in '
                             'template.')

    in_args = parser.parse_args()

    if in_args.file != '':
        flow_template = get_json_from_file(in_args.file)
    else:
        flow_template = JSON_FLOW_MOD1

    fct = FlowConfigBlaster(in_args.host, in_args.port, in_args.cycles, in_args.threads, in_args.nodes,
                            in_args.flows, in_args.startflow, in_args.auth, flow_template)

    # Run through <cycles>, where <threads> are started in each cycle and <flows> are added from each thread
    fct.add_blaster()

    print '\n*** Total flows added: %s' % fct.get_total_flows()
    print '    HTTP[OK] results:  %d\n' % fct.get_ok_flows()

    if in_args.delay > 0:
        print '*** Waiting for %d seconds before the delete cycle ***\n' % in_args.delay
        time.sleep(in_args.delay)

    # Run through <cycles>, where <threads> are started in each cycle and <flows> previously added in an add cycle are
    # deleted in each thread
    if in_args.delete:
        fct.delete_blaster()
