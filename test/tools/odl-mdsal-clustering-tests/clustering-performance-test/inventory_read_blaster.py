#!/usr/bin/python

__author__ = "Gary Wu"
__email__ = "gary.wu1@huawei.com"


import requests
import argparse
import time
import threading
import functools
import operator
import collections

from Queue import Queue

GET_HEADERS = {'Accept': 'application/json'}

INVENTORY_URL = 'http://%s:%d/restconf/%s/opendaylight-inventory:nodes'


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


def read(hosts, port, auth, datastore, print_lock, cycles, results_queue):
    """
    Make RESTconf request to read the flow configuration from the specified data store.

    Args:

        :param hosts: A comma-separated list of hosts to read from.

        :param port: The port number to read from.

        :param auth: The username and password pair to use for basic authentication, or None
            if no authentication is required.

        :param datastore: The datastore (operational/config) to read flows from.

        :param print_lock: The thread lock to allow only one thread to output at a time.

        :param cycles: The number of reads that this thread will perform.

        :param results_queue: Used to store the HTTP status results of this method call.
    """
    s = requests.Session()
    stats = {}
    for i in range(cycles):
        host = hosts[i % len(hosts)]
        url = INVENTORY_URL % (host, port, datastore)
        r = s.get(url, headers=GET_HEADERS, stream=False, auth=auth)
        # If dict has no such entry, default to 0
        stats[r.status_code] = stats.get(r.status_code, 0) + 1

    with print_lock:
        print '   ', threading.current_thread().name, 'results:', stats

    results_queue.put(stats)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Inventory read performance test: Repeatedly read openflow node data '
                                     'from config datastore.  Note that the data needs to be created in the datastore '
                                     'first using flow_config_blaster.py --no-delete.')

    parser.add_argument('--host', default='127.0.0.1',
                        help='Host where odl controller is running (default is 127.0.0.1).  '
                             'Specify a comma-separated list of hosts to perform round-robin load-balancing.')
    parser.add_argument('--port', default='8181', type=int,
                        help='Port on which odl\'s RESTCONF is listening (default is 8181)')
    parser.add_argument('--datastore', choices=['operational', 'config'],
                        default='operational', help='Which data store to crawl; default operational')
    parser.add_argument('--cycles', type=int, default=100,
                        help='Number of repeated reads; default 100. ')
    parser.add_argument('--threads', type=int, default=1,
                        help='Number of request worker threads to start in each cycle; default=1. '
                             'Each thread will add/delete <FLOWS> flows.')
    parser.add_argument('--auth', dest='auth', action='store_true', default=False,
                        help="Use the ODL default username/password 'admin'/'admin' to authenticate access to REST; "
                             'default: no authentication')

    args = parser.parse_args()

    hosts = args.host.split(",")
    port = args.port
    auth = ("admin", "admin") if args.auth else None

    # Use a lock to ensure that output from multiple threads don't interrupt/overlap each other
    print_lock = threading.Lock()
    results = Queue()

    with Timer() as t:
        threads = []
        for i in range(args.threads):
            thread = threading.Thread(target=read, args=(hosts, port, auth, args.datastore, print_lock, args.cycles,
                                                         results))
            threads.append(thread)
            thread.start()

        # Wait for all threads to finish and measure the execution time
        for thread in threads:
            thread.join()

    # Aggregate the results
    stats = functools.reduce(operator.add, map(collections.Counter, results.queue))

    print '\n*** Test summary:'
    print '    Elapsed time:    %.2fs' % t.secs
    print '    HTTP[OK] results:  %d\n' % stats[200]
