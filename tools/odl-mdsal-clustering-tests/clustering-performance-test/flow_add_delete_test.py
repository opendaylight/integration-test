#!/usr/bin/python

__author__ = "Jan Medved"
__copyright__ = "Copyright(c) 2014, Cisco Systems, Inc."
__license__ = "New-style BSD"
__email__ = "jmedved@cisco.com"

import argparse
import time
from flow_config_blaster import FlowConfigBlaster, get_json_from_file
from inventory_crawler import InventoryCrawler
from config_cleanup import cleanup_config_odl


def wait_for_stats(crawler, exp_found, timeout, delay):
    """
    Waits for the ODL stats manager to catch up. Polls ODL inventory every
    <delay> seconds and compares the retrieved stats to the expected values. If
    stats collection has not finished within <timeout> seconds, the test is
    aborted.
    :param crawler: Inventory crawler object
    :param exp_found: Expected value for flows found in the network
    :param timeout: Max number of seconds to wait for stats collector to
                    collect all stats
    :param delay: poll interval for inventory
    :return: None
    """
    total_delay = 0
    print 'Waiting for stats to catch up:'
    while True:
        crawler.crawl_inventory()
        print '   %d, %d' % (crawler.reported_flows, crawler.found_flows)
        if crawler.found_flows == exp_found or total_delay > timeout:
            break
        total_delay += delay
        time.sleep(delay)

    if total_delay < timeout:
        print 'Stats collected in %d seconds.' % total_delay
    else:
        print 'Stats collection did not finish in %d seconds. Aborting...' % total_delay


if __name__ == "__main__":
    ############################################################################
    # This program executes an ODL performance test. The test is executed in
    # three steps:
    #
    # 1. The specified number of flows is added in the 'add cycle' (uses
    #    flow_config_blaster to blast flows)
    # 2. The network is polled for flow statistics from the network (using the
    #    inventory_crawler.py script) to make sure that all flows have been
    #    properly programmed into the network and the ODL statistics collector
    #    can properly read them
    # 3. The flows are deleted in the flow cycle. Deletion happens either in
    #    'bulk' (using the config_cleanup) script or one by one (using the
    #     flow_config_blaster 'delete' method)
    ############################################################################

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
    parser.add_argument('--fpr', type=int, default=1,
                        help='Flows-per-Request - number of flows (batch size) sent in each HTTP request; '
                             'default 1')
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
        flow_template = None

    ic = InventoryCrawler(in_args.host, in_args.port, 0, 'operational', in_args.auth, False)

    fct = FlowConfigBlaster(in_args.host, in_args.port, in_args.cycles, in_args.threads, in_args.fpr,
                            16, in_args.flows, in_args.startflow, in_args.auth)
    # Get the baseline stats. Required in Step 3 to validate if the delete
    # function gets the controller back to the baseline
    ic.crawl_inventory()
    reported = ic.reported_flows
    found = ic.found_flows

    print 'Baseline:'
    print '   Reported flows: %d' % reported
    print '   Found flows:    %d' % found

    # Run through <CYCLES> add cycles, where <THREADS> threads are started in
    # each cycle and <FLOWS> flows are added from each thread
    fct.add_blaster()

    print '\n*** Total flows added: %d' % fct.get_ok_flows()
    print '    HTTP[OK] results:  %d\n' % fct.get_ok_rqsts()

    # Wait for stats to catch up
    wait_for_stats(ic, found + fct.get_ok_flows(), in_args.timeout, in_args.delay)

    # Run through <CYCLES> delete cycles, where <THREADS> threads  are started
    # in each cycle and <FLOWS> flows previously added in an add cycle are
    # deleted in each thread
    if in_args.bulk_delete:
        print '\nDeleting all flows in bulk:'
        sts = cleanup_config_odl(in_args.host, in_args.port, in_args.auth)
        if sts != 200:
            print '   Failed to delete flows, code %d' % sts
        else:
            print '   All flows deleted.'
    else:
        print '\nDeleting flows one by one\n   ',
        fct.delete_blaster()
        print '\n*** Total flows deleted: %d' % fct.get_ok_flows()
        print '    HTTP[OK] results:    %d\n' % fct.get_ok_rqsts()

    # Wait for stats to catch up back to baseline
    wait_for_stats(ic, found, in_args.timeout, in_args.delay)
