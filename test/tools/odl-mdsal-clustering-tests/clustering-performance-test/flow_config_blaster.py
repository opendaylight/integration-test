#!/usr/bin/python
__author__ = "Jan Medved"
__copyright__ = "Copyright(c) 2014, Cisco Systems, Inc."
__license__ = "New-style BSD"
__email__ = "jmedved@cisco.com"

from random import randrange
import json
import argparse
import time
import threading
import re
import copy

import requests
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
    TBLURL = "restconf/config/opendaylight-inventory:nodes/node/openflow:%d/table/0"
    INVURL = 'restconf/operational/opendaylight-inventory:nodes'

    flows = {}

    # The "built-in" flow template
    flow_mode_template = {
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

    class FcbStats(object):
        """
        FlowConfigBlaster Statistics: a class that stores and further processes
        statistics collected by Blaster worker threads during their execution.
        """
        def __init__(self):
            self.ok_rqst_rate = Counter(0.0)
            self.total_rqst_rate = Counter(0.0)
            self.ok_flow_rate = Counter(0.0)
            self.total_flow_rate = Counter(0.0)
            self.ok_rqsts = Counter(0)
            self.total_rqsts = Counter(0)
            self.ok_flows = Counter(0)
            self.total_flows = Counter(0)

        def process_stats(self, rqst_stats, flow_stats, elapsed_time):
            """
            Calculates the stats for RESTCONF request and flow programming
            throughput, and aggregates statistics across all Blaster threads.
            """
            ok_rqsts = rqst_stats[200] + rqst_stats[204]
            total_rqsts = sum(rqst_stats.values())
            ok_flows = flow_stats[200] + flow_stats[204]
            total_flows = sum(flow_stats.values())

            ok_rqst_rate = ok_rqsts / elapsed_time
            total_rqst_rate = total_rqsts / elapsed_time
            ok_flow_rate = ok_flows / elapsed_time
            total_flow_rate = total_flows / elapsed_time

            self.ok_rqsts.increment(ok_rqsts)
            self.total_rqsts.increment(total_rqsts)
            self.ok_flows.increment(ok_flows)
            self.total_flows.increment(total_flows)

            self.ok_rqst_rate.increment(ok_rqst_rate)
            self.total_rqst_rate.increment(total_rqst_rate)
            self.ok_flow_rate.increment(ok_flow_rate)
            self.total_flow_rate.increment(total_flow_rate)

            return ok_rqst_rate, total_rqst_rate, ok_flow_rate, total_flow_rate

        def get_ok_rqst_rate(self):
            return self.ok_rqst_rate.value

        def get_total_rqst_rate(self):
            return self.total_rqst_rate.value

        def get_ok_flow_rate(self):
            return self.ok_flow_rate.value

        def get_total_flow_rate(self):
            return self.total_flow_rate.value

        def get_ok_rqsts(self):
            return self.ok_rqsts.value

        def get_total_rqsts(self):
            return self.total_rqsts.value

        def get_ok_flows(self):
            return self.ok_flows.value

        def get_total_flows(self):
            return self.total_flows.value

    def __init__(self, host, port, ncycles, nthreads, fpr, nnodes, nflows, startflow, auth, flow_mod_template=None):
        self.host = host
        self.port = port
        self.ncycles = ncycles
        self.nthreads = nthreads
        self.fpr = fpr
        self.nnodes = nnodes
        self.nflows = nflows
        self.startflow = startflow
        self.auth = auth

        if flow_mod_template:
            self.flow_mode_template = flow_mod_template

        self.post_url_template = 'http://%s:' + self.port + '/' + self.TBLURL
        self.del_url_template = 'http://%s:' + self.port + '/' + self.FLWURL

        self.stats = self.FcbStats()
        self.total_ok_flows = 0
        self.total_ok_rqsts = 0

        self.ip_addr = Counter(int(netaddr.IPAddress('10.0.0.1')) + startflow)

        self.print_lock = threading.Lock()
        self.cond = threading.Condition()
        self.threads_done = 0

        for i in range(self.nthreads):
            self.flows[i] = {}

    def get_num_nodes(self, session):
        """
        Determines the number of OF nodes in the connected mininet network. If
        mininet is not connected, the default number of flows is set to 16.
        :param session: 'requests' session which to use to query the controller
                        for openflow nodes
        :return: None
        """
        hosts = self.host.split(",")
        host = hosts[0]
        inventory_url = 'http://' + host + ":" + self.port + '/' + self.INVURL
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

    def create_flow_from_template(self, flow_id, ipaddr):
        """
        Create a new flow instance from the flow template specified during
        FlowConfigBlaster instantiation. Flow templates are json-compatible
        dictionaries that MUST contain elements for flow cookie, flow name,
        flow id and the destination IPv4 address in the flow match field.
        :param flow_id: Id for the new flow to create
        :param ipaddr: IP Address to put into the flow's match
        :return: The newly created flow instance
        """
        flow = copy.deepcopy(self.flow_mode_template['flow'][0])
        flow['cookie'] = flow_id
        flow['flow-name'] = 'TestFlow-%d' % flow_id
        flow['id'] = str(flow_id)
        flow['match']['ipv4-destination'] = '%s/32' % str(netaddr.IPAddress(ipaddr))
        return flow

    def post_flows(self, session, node, flow_list, flow_count):
        """
        Performs a RESTCONF post of flows passed in the 'flow_list' parameters
        :param session: 'requests' session on which to perform the POST
        :param node: The ID of the openflow node to which to post the flows
        :param flow_list: List of flows (in dictionary form) to POST
        :return: status code from the POST operation
        """
        fmod = dict(self.flow_mode_template)
        fmod['flow'] = flow_list
        flow_data = json.dumps(fmod)
        # print flow_data

        hosts = self.host.split(",")
        host = hosts[flow_count % len(hosts)]
        flow_url = self.post_url_template % (host, node)
        # print flow_url

        if not self.auth:
            r = session.post(flow_url, data=flow_data, headers=self.putheaders, stream=False)
        else:
            r = session.post(flow_url, data=flow_data, headers=self.putheaders, stream=False, auth=('admin', 'admin'))

        return r.status_code

    def add_flows(self, start_flow_id, tid):
        """
        Adds flows into the ODL config data store. This function is executed by
        a worker thread (the Blaster thread). The number of flows created and
        the batch size (i.e. how many flows will be put into a RESTCONF request)
        are determined by control parameters initialized when FlowConfigBlaster
        is created.
        :param start_flow_id - the ID of the first flow. Each Blaster thread
                               programs a different set of flows
        :param tid: Thread ID - used to id the Blaster thread when statistics
                                for the thread are printed out
        :return: None
        """
        rqst_stats = {200: 0, 204: 0}
        flow_stats = {200: 0, 204: 0}

        s = requests.Session()

        n_nodes = self.get_num_nodes(s)

        with self.print_lock:
            print '    Thread %d:\n        Adding %d flows on %d nodes' % (tid, self.nflows, n_nodes)

        nflows = 0
        with Timer() as t:
            while nflows < self.nflows:
                node_id = randrange(1, n_nodes + 1)
                flow_list = []
                for i in range(self.fpr):
                    flow_id = tid * (self.ncycles * self.nflows) + nflows + start_flow_id + self.startflow
                    self.flows[tid][flow_id] = node_id
                    flow_list.append(self.create_flow_from_template(flow_id, self.ip_addr.increment()))
                    nflows += 1
                    if nflows >= self.nflows:
                        break
                sts = self.post_flows(s, node_id, flow_list, nflows)
                try:
                    rqst_stats[sts] += 1
                    flow_stats[sts] += len(flow_list)
                except KeyError:
                    rqst_stats[sts] = 1
                    flow_stats[sts] = len(flow_list)

        ok_rps, total_rps, ok_fps, total_fps = self.stats.process_stats(rqst_stats, flow_stats, t.secs)

        with self.print_lock:
            print '\n    Thread %d results (ADD): ' % tid
            print '        Elapsed time: %.2fs,' % t.secs
            print '        Requests/s: %.2f OK, %.2f Total' % (ok_rps, total_rps)
            print '        Flows/s:    %.2f OK, %.2f Total' % (ok_fps, total_fps)
            print '        Stats ({Requests}, {Flows}): ',
            print rqst_stats,
            print flow_stats
            self.threads_done += 1

        s.close()

        with self.cond:
            self.cond.notifyAll()

    def delete_flow(self, session, node, flow_id, flow_count):
        """
        Deletes a single flow from the ODL config data store using RESTCONF
        :param session: 'requests' session on which to perform the POST
        :param node: Id of the openflow node from which to delete the flow
        :param flow_id: ID of the to-be-deleted flow
        :return: status code from the DELETE operation
        """

        hosts = self.host.split(",")
        host = hosts[flow_count % len(hosts)]
        flow_url = self.del_url_template % (host, node, flow_id)
        # print flow_url

        if not self.auth:
            r = session.delete(flow_url, headers=self.getheaders)
        else:
            r = session.delete(flow_url, headers=self.getheaders, auth=('admin', 'admin'))

        return r.status_code

    def delete_flows(self, start_flow, tid):
        """
        Deletes flow from the ODL config space that have been added using the
        'add_flows()' function. This function is executed by a worker thread
        :param start_flow_id - the ID of the first flow. Each Blaster thread
                               deletes a different set of flows
        :param tid: Thread ID - used to id the Blaster thread when statistics
                                for the thread are printed out
        :return:
        """
        """
        """
        rqst_stats = {200: 0, 204: 0}

        s = requests.Session()
        n_nodes = self.get_num_nodes(s)

        with self.print_lock:
            print 'Thread %d: Deleting %d flows on %d nodes' % (tid, self.nflows, n_nodes)

        with Timer() as t:
            for flow in range(self.nflows):
                flow_id = tid * (self.ncycles * self.nflows) + flow + start_flow + self.startflow
                sts = self.delete_flow(s, self.flows[tid][flow_id], flow_id, flow)
                try:
                    rqst_stats[sts] += 1
                except KeyError:
                    rqst_stats[sts] = 1

        ok_rps, total_rps, ok_fps, total_fps = self.stats.process_stats(rqst_stats, rqst_stats, t.secs)

        with self.print_lock:
            print '\n    Thread %d results (DELETE): ' % tid
            print '        Elapsed time: %.2fs,' % t.secs
            print '        Requests/s:  %.2f OK,  %.2f Total' % (ok_rps, total_rps)
            print '        Flows/s:     %.2f OK,  %.2f Total' % (ok_fps, total_fps)
            print '        Stats ({Requests})',
            print rqst_stats
            self.threads_done += 1

        s.close()

        with self.cond:
            self.cond.notifyAll()

    def run_cycle(self, function):
        """
        Runs a flow-add or flow-delete test cycle. Each test consists of a
        <cycles> test cycles, where <threads> worker (Blaster) threads are
        started in each test cycle. Each Blaster thread programs <flows>
        OpenFlow flows into the controller using the controller's RESTCONF API.
        :param function: Add or delete, determines what test will be executed.
        :return: None
        """
        self.total_ok_flows = 0
        self.total_ok_rqsts = 0

        for c in range(self.ncycles):
            self.stats = self.FcbStats()
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
                print '\n*** Test summary:'
                print '    Elapsed time:    %.2fs' % t.secs
                print '    Peak requests/s: %.2f OK, %.2f Total' % (
                    self.stats.get_ok_rqst_rate(), self.stats.get_total_rqst_rate())
                print '    Peak flows/s:    %.2f OK, %.2f Total' % (
                    self.stats.get_ok_flow_rate(), self.stats.get_total_flow_rate())
                print '    Avg. requests/s: %.2f OK, %.2f Total (%.2f%% of peak total)' % (
                    self.stats.get_ok_rqsts() / t.secs,
                    self.stats.get_total_rqsts() / t.secs,
                    (self.stats.get_total_rqsts() / t.secs * 100) / self.stats.get_total_rqst_rate())
                print '    Avg. flows/s:    %.2f OK, %.2f Total (%.2f%% of peak total)' % (
                    self.stats.get_ok_flows() / t.secs,
                    self.stats.get_total_flows() / t.secs,
                    (self.stats.get_total_flows() / t.secs * 100) / self.stats.get_total_flow_rate())

                self.total_ok_flows += self.stats.get_ok_flows()
                self.total_ok_rqsts += self.stats.get_ok_rqsts()
                self.threads_done = 0

    def add_blaster(self):
        self.run_cycle(self.add_flows)

    def delete_blaster(self):
        self.run_cycle(self.delete_flows)

    def get_ok_flows(self):
        return self.total_ok_flows

    def get_ok_rqsts(self):
        return self.total_ok_rqsts


def get_json_from_file(filename):
    """
    Get a flow programming template from a file
    :param filename: File from which to get the template
    :return: The json flow template (string)
    """
    with open(filename, 'r') as f:
        try:
            ft = json.load(f)
            keys = ft['flow'][0].keys()
            if (u'cookie' in keys) and (u'flow-name' in keys) and (u'id' in keys) and (u'match' in keys):
                if u'ipv4-destination' in ft[u'flow'][0]['match'].keys():
                    print 'File "%s" ok to use as flow template' % filename
                    return ft
        except ValueError:
            print 'JSON parsing of file %s failed' % filename
            pass

    return None

###############################################################################
# This is an example of what the content of a JSON flow mode template should
# look like. Cut & paste to create a custom template. "id" and "ipv4-destination"
# MUST be unique if multiple flows will be programmed in the same test. It's
# also beneficial to have unique "cookie" and "flow-name" attributes for easier
# identification of the flow.
###############################################################################
example_flow_mod_json = '''{
    "flow": [
        {
            "id": "38",
            "cookie": 38,
            "instructions": {
                "instruction": [
                    {
                        "order": 0,
                        "apply-actions": {
                            "action": [
                                {
                                    "order": 0,
                                    "drop-action": { }
                                }
                            ]
                        }
                    }
                ]
            },
            "hard-timeout": 65000,
            "match": {
                "ethernet-match": {
                    "ethernet-type": {
                        "type": 2048
                    }
                },
                "ipv4-destination": "10.0.0.38/32"
            },
            "flow-name": "TestFlow-8",
            "strict": false,
            "cookie_mask": 4294967295,
            "priority": 2,
            "table_id": 0,
            "idle-timeout": 65000,
            "installHw": false
        }

    ]
}'''

if __name__ == "__main__":
    ############################################################################
    # This program executes the base performance test. The test adds flows into
    # the controller's config space. This function is basically the CLI frontend
    # to the FlowConfigBlaster class and drives its main functions: adding and
    # deleting flows from the controller's config data store
    ############################################################################
    parser = argparse.ArgumentParser(description='Flow programming performance test: First adds and then deletes flows '
                                                 'into the config tree, as specified by optional parameters.')

    parser.add_argument('--host', default='127.0.0.1',
                        help='Host where odl controller is running (default is 127.0.0.1).  '
                             'Specify a comma-separated list of hosts to perform round-robin load-balancing.')
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
    parser.add_argument('--fpr', type=int, default=1,
                        help='Flows-per-Request - number of flows (batch size) sent in each HTTP request; '
                             'default 1')
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
        flow_template = None

    fct = FlowConfigBlaster(in_args.host, in_args.port, in_args.cycles, in_args.threads, in_args.fpr, in_args.nodes,
                            in_args.flows, in_args.startflow, in_args.auth)

    # Run through <cycles>, where <threads> are started in each cycle and
    # <flows> are added from each thread
    fct.add_blaster()

    print '\n*** Total flows added: %s' % fct.get_ok_flows()
    print '    HTTP[OK] results:  %d\n' % fct.get_ok_rqsts()

    if in_args.delay > 0:
        print '*** Waiting for %d seconds before the delete cycle ***\n' % in_args.delay
        time.sleep(in_args.delay)

    # Run through <cycles>, where <threads> are started in each cycle and
    # <flows> previously added in an add cycle are deleted in each thread
    if in_args.delete:
        fct.delete_blaster()
        print '\n*** Total flows deleted: %s' % fct.get_ok_flows()
        print '    HTTP[OK] results:    %d\n' % fct.get_ok_rqsts()
