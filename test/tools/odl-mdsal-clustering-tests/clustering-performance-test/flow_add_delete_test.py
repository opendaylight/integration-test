#!/usr/bin/python

__author__ = "Jan Medved"
__copyright__ = "Copyright(c) 2014, Cisco Systems, Inc."
__license__ = "New-style BSD"
__email__ = "jmedved@cisco.com"

import argparse
import time
from flow_config_blaster import FlowConfigBlaster, get_json_from_file
from inventory_crawler import InventoryCrawler
from config_cleanup import cleanup_config


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
    parser.add_argument('--delay', type=int, default=2,
                        help='Time (seconds) to between inventory polls when waiting for stats to catch up; default=1')
    parser.add_argument('--timeout', type=int, default=100,
                        help='The maximum time (seconds) to wait between the add and delete cycles; default=100')
    parser.add_argument('--delete', dest='delete', action='store_true', default=True,
                        help='Delete all added flows one by one, benchmark delete '
                             'performance.')
    parser.add_argument('--bulk-delete', dest='bulk_delete', action='store_true', default=False,
                        help='Delete all flows in bulk; default=False')
    parser.add_argument('--auth', dest='auth', action='store_true',
                        help="Use authenticated access to REST (username: 'admin', password: 'admin'); default=False")
    parser.add_argument('--startflow', type=int, default=0,
                        help='The starting Flow ID; default=0')
    parser.add_argument('--file', default='',
                        help='File from which to read the JSON flow template; default: no file, use a built in '
                             'template.')

    in_args = parser.parse_args()

    # Initialize
    if in_args.file != '':
        flow_template = get_json_from_file(in_args.file)
    else:
        flow_template = JSON_FLOW_MOD1

    ic = InventoryCrawler(in_args.host, in_args.port, 0, 'operational', in_args.auth, False)

    fct = FlowConfigBlaster(in_args.host, in_args.port, in_args.cycles, in_args.threads, in_args.nodes,
                            in_args.flows, in_args.startflow, in_args.auth, flow_template)

    # Get baseline stats
    ic.crawl_inventory()
    reported = ic.reported_flows
    found = ic.found_flows

    print 'Baseline:'
    print '   Reported nodes: %d' % reported
    print '   Found nodes:    %d' % found

    # Run through <cycles>, where <threads> are started in each cycle and <flows> are added from each thread
    fct.add_blaster()

    print '\n*** Total flows added: %s' % fct.get_total_flows()
    print '    HTTP[OK] results:  %d\n' % fct.get_ok_flows()

    # Wait for stats to catch up
    total_delay = 0
    exp_found = found + fct.get_ok_flows()
    exp_reported = reported + fct.get_ok_flows()

    print 'Waiting for stats to catch up:'
    while True:
        ic.crawl_inventory()
        print '   %d, %d' % (ic.reported_flows, ic.found_flows)
        if ic.found_flows == exp_found or total_delay > in_args.timeout:
            break
        total_delay += in_args.delay
        time.sleep(in_args.delay)

    if total_delay < in_args.timeout:
        print 'Stats collected in %d seconds.' % total_delay
    else:
        print 'Stats collection did not finish in %d seconds. Aborting...' % total_delay

    # Run through <cycles>, where <threads> are started in each cycle and <flows> previously added in an add cycle are
    # deleted in each thread
    if in_args.bulk_delete:
        print '\nDeleting all flows in bulk:\n   ',
        cleanup_config(in_args.host, in_args.port, in_args.auth)
    else:
        print '\nDeleting flows one by one\n   ',
        fct.delete_blaster()

    # Wait for stats to catch up
    total_delay = 0

    print '\nWaiting for stats to catch up:'
    while True:
        ic.crawl_inventory()
        if ic.found_flows == found or total_delay > in_args.timeout:
            break
        total_delay += in_args.delay
        print '   %d, %d' % (ic.reported_flows, ic.found_flows)
        time.sleep(in_args.delay)

    if total_delay < in_args.timeout:
        print 'Stats collected in %d seconds.' % total_delay
    else:
        print 'Stats collection did not finish in %d seconds. Aborting...' % total_delay
