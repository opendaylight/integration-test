#!/usr/bin/python

"""
The script is based on the flow_add_delete_test.py. The only difference is that
it doesn't wait till stats are collected, but it triggers inventory data as
long as specified and produces an output file it's name is given.
"""

import argparse
import time
from flow_config_blaster import FlowConfigBlaster, get_json_from_file
from inventory_crawler import InventoryCrawler
from config_cleanup import cleanup_config_odl


def get_time_delta(actualtime, basetime):
    return actualtime - basetime


def monitor_stats(crawler, monitortime, period):
    """
    Check incentory and yields collected data.
    """
    basetime = time.time()
    while True:
        lastcrawl = time.time()
        crawler.nodes = 0
        crawler.crawl_inventory()
        actualtime = time.time()
        yield (actualtime, crawler.nodes, crawler.reported_flows, crawler.found_flows)
        if actualtime > basetime + monitortime:
            break
        time.sleep(period-get_time_delta(actualtime, lastcrawl))


if __name__ == "__main__":
    ############################################################################
    # This program executes an ODL performance test. The task is executed in
    # four steps:
    #
    # 1. The specified number of flows is added in the 'add cycle' (uses
    #    flow_config_blaster to blast flows)
    # 2. The network is polled for flow statistics from the network (using the
    #    inventory_crawler.py script) to make sure that all flows have been
    #    properly programmed into the network and the ODL statistics collector
    #    can properly read them as long as specified
    # 3. The flows are deleted in the flow cycle. Deletion happens either in
    #    'bulk' (using the config_cleanup) script or one by one (using the
    #    flow_config_blaster 'delete' method)
    # 4. Same as 2. Monitoring and reporting the state of the inventory data
    #    for a specified period of time.
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
    parser.add_argument('--config_monitor', type=int, default=60,
                        help='Time to monotir inventory after flows are configured in seconds; default=60')
    parser.add_argument('--deconfig_monitor', type=int, default=60,
                        help='Time to monitor inventory after flows are de configured in seconds; default=60')
    parser.add_argument('--monitor_period', type=int, default=10,
                        help='Monitor period of triggering inventory crawler in seconds; default=10')
    parser.add_argument('--monitor_outfile', default=None, help='Output file(if specified)')

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
    print '   Reported nodes: %d' % reported
    print '   Found nodes:    %d' % found

    stats = []
    stats.append((time.time(), ic.nodes, ic.reported_flows, ic.found_flows))
    # Run through <CYCLES> add cycles, where <THREADS> threads are started in
    # each cycle and <FLOWS> flows are added from each thread
    fct.add_blaster()

    print '\n*** Total flows added: %d' % fct.get_ok_flows()
    print '    HTTP[OK] results:  %d\n' % fct.get_ok_rqsts()

    # monitor stats and save results in the list
    for stat_item in monitor_stats(ic, in_args.config_monitor, in_args.monitor_period):
        print stat_item
        stats.append(stat_item)

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

    # monitor stats and append to the list
    for stat_item in monitor_stats(ic, in_args.deconfig_monitor, in_args.monitor_period):
        print stat_item
        stats.append(stat_item)

    # if requested, write collected data into the file
    if in_args.monitor_outfile is not None:
        with open(in_args.monitor_outfile, 'wt') as fd:
            for e in stats:
                fd.write('{0} {1} {2} {3}\n'.format(e[0], e[1], e[2], e[3]))
