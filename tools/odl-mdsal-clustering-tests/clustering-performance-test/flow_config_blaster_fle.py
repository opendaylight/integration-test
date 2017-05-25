#!/usr/bin/python
from flow_config_blaster import FlowConfigBlaster
import argparse
import time
import json
import copy
import requests


__author__ = "Jan Medved"
__copyright__ = "Copyright(c) 2014, Cisco Systems, Inc."
__license__ = "New-style BSD"
__email__ = "jmedved@cisco.com"


class FlowConfigBlasterFLE(FlowConfigBlaster):
    """
    FlowConfigBlaster, Floodlight Edition; Uses the Floodlight Static Flow Entry Pusher REST API to inject flows.
    """
    flow = {
        'switch': "00:00:00:00:00:00:00:01",
        "name": "flow-mod",
        "cookie": "0",
        "priority": "32768",
        "eth_type": "2048",
        "ipv4_dst": "10.0.0.1/32",
        "active": "true",
        "actions": "output=flood"
    }

    def __init__(self, host, port, ncycles, nthreads, nnodes, nflows, startflow):
        FlowConfigBlaster.__init__(self, host, port, ncycles, nthreads, 1, nnodes, nflows, startflow, False)

    def create_floodlight_url(self, host):
        return 'http://' + host + ":" + self.port + '/wm/staticflowpusher/json'

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

    def post_flows(self, session, node, flow_list, flow_count):
        """
        Performs a RESTCONF post of flows passed in the 'flow_list' parameters
        :param session: 'requests' session on which to perform the POST
        :param node: The ID of the openflow node to which to post the flows
        :param flow_list: List of flows (in dictionary form) to POST
        :param flow_count: Number of flows in flow_list (must be 1)
        :return: status code from the POST operation
        """
        flow = copy.deepcopy(self.flow)
        flow['switch'] = "00:00:00:00:00:00:00:%s" % '{0:02x}'.format(node)
        flow['name'] = flow_list[0]['flow-name']
        flow['table'] = flow_list[0]['table_id']
        flow['cookie'] = flow_list[0]['cookie']
        # flow['cookie_mask'] = flow_list[0]['cookie_mask']
        flow['idle_timeout'] = flow_list[0]['idle-timeout']
        flow['hard_timeout'] = flow_list[0]['hard-timeout']
        flow['ipv4_dst'] = flow_list[0]['match']['ipv4-destination']

        flow_data = json.dumps(flow)

        hosts = self.host.split(",")
        host = hosts[flow_count % len(hosts)]
        flow_url = self.create_floodlight_url(host)

        r = session.post(flow_url, data=flow_data, headers=self.putheaders, stream=False)
        return r.status_code

    def delete_flow(self, session, node, flow_id, flow_count):
        """
        Deletes a single flow from the ODL config data store using RESTCONF
        :param session: 'requests' session on which to perform the POST
        :param node: Id of the openflow node from which to delete the flow
        :param flow_id: ID of the to-be-deleted flow
        :param flow_count: Flow counter for round-robin of delete operations
        :return: status code from the DELETE operation
        """

        hosts = self.host.split(",")
        host = hosts[flow_count % len(hosts)]
        flow_url = self.create_floodlight_url(host)
        flow_data = json.dumps({'name': self.create_flow_name(flow_id)})

        r = session.delete(flow_url, data=flow_data, headers=self.getheaders)
        return r.status_code

    def clear_all_flows(self):
        clear_url = 'http://' + self.host + ":" + self.port + '/wm/staticflowpusher/clear/all/json'
        r = requests.get(clear_url)
        if r.status_code == 200:
            print "All flows cleared before the test"
        else:
            print "Failed to clear flows from the controller, your results may vary"


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

    fct.clear_all_flows()

    # Run through <cycles>, where <threads> are started in each cycle and <flows> are added from each thread
    fct.add_blaster()

    print '\n*** Total flows added: %s' % fct.get_ok_flows()
    print '    HTTP[OK] results:  %d\n' % fct.get_ok_rqsts()

    if in_args.delay > 0:
        print '*** Waiting for %d seconds before the delete cycle ***\n' % in_args.delay
        time.sleep(in_args.delay)

    # Run through <cycles>, where <threads> are started in each cycle and <flows> previously added in an add cycle are
    # deleted in each thread
    if in_args.delete:
        fct.delete_blaster()
        print '\n*** Total flows deleted: %s' % fct.get_ok_flows()
        print '    HTTP[OK] results:    %d\n' % fct.get_ok_rqsts()
