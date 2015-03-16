#!/usr/bin/python
__author__ = "Jan Medved"
__copyright__ = "Copyright(c) 2014, Cisco Systems, Inc."
__license__ = "New-style BSD"
__email__ = "jmedved@cisco.com"

from flow_config_blaster import FlowConfigBlaster
import argparse
import netaddr
import time
import json


class FlowConfigBlasterFLE(FlowConfigBlaster):
    """
    FlowConfigBlaster, Floodlight Edition; Uses the Floodlight Static Flow Entry Pusher REST API to inject flows.
    """
    flow = {
        'switch': "00:00:00:00:00:00:00:01",
        "name": "flow-mod",
        "cookie": "0",
        "priority": "32768",
        "ether-type": "2048",
        "dst-ip": "10.0.0.1/32",
        "active": "true",
        "actions": "output=flood"
    }

    def __init__(self, host, port, ncycles, nthreads, nnodes, nflows, startflow):
        FlowConfigBlaster.__init__(self, host, port, ncycles, nthreads, nnodes, nflows, startflow, False, '')

        # Create the service URL
        self.url = 'http://' + self.host + ":" + self.port + '/wm/staticflowentrypusher/json'

    def get_num_nodes(self, session):
        """
        Determines the number of nodes in the network. Overrides the get_num_nodes method in FlowConfigBlaster.
        :param session:
        :return:
        """
        url = 'http://' + self.host + ":" + self.port + '/wm/core/controller/switches/json'
        nodes = self.nnodes

        r = session.get(url, headers=self.getheaders, stream=False)

        if r.status_code == 200:
            try:
                nodes = len(json.loads(r.content))
            except KeyError:
                pass

        return nodes

    def add_flow(self, session, node, flow_id, ipaddr):
        """
        Adds a flow. Overrides the add_flow method in FlowConfigBlaster.
        :param session:
        :param node:
        :param flow_id:
        :param ipaddr:
        :return:
        """
        self.flow['switch'] = "00:00:00:00:00:00:00:%s" % '{0:02x}'.format(node)
        self.flow['name'] = 'TestFlow-%d' % flow_id
        self.flow['cookie'] = str(flow_id)
        self.flow['dst-ip'] = "%s/32" % str(netaddr.IPAddress(ipaddr))

        flow_data = json.dumps(self.flow)
        # print flow_data
        # print flow_url

        r = session.post(self.url, data=flow_data, headers=self.putheaders, stream=False)
        return r.status_code

    def delete_flow(self, session, node, flow_id):
        """
        Deletes a flow. Overrides the delete_flow method in FlowConfigBlaster.
        :param session:
        :param node:
        :param flow_id:
        :return:
        """
        f = {'name': 'TestFlow-%d' % flow_id}
        flow_data = json.dumps(f)

        r = session.delete(self.url, data=flow_data, headers=self.getheaders)
        return r.status_code


if __name__ == "__main__":

    parser = argparse.ArgumentParser(description='Flow programming performance test for Floodlight: First adds and '
                                                 'then deletes flows using the Static Flow Entry Pusher REST API.')

    parser.add_argument('--host', default='127.0.0.1',
                        help='Host where the controller is running (default is 127.0.0.1)')
    parser.add_argument('--port', default='8080',
                        help='Port on which the controller\'s RESTCONF is listening (default is 8080)')
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
    parser.add_argument('--no-delete', dest='delete', action='store_false',
                        help='Do not perform the delete cycle.')
    parser.add_argument('--startflow', type=int, default=0,
                        help='The starting Flow ID; default=0')

    in_args = parser.parse_args()

    fct = FlowConfigBlasterFLE(in_args.host, in_args.port, in_args.cycles, in_args.threads, in_args.nodes,
                               in_args.flows, in_args.startflow)

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
