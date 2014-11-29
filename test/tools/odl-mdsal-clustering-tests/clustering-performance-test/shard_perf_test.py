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
import sys
import requests


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


class ShardPerformanceTester(object):
    """
    The ShardPerformanceTester class facilitates performance testing of CDS shards. The test starts a number of
    threads, where each thread issues a specified number of resource retrieval requests to URLs specified at the
    beginning of a test. A ShardPerformanceTester object gets its connection parameters to the system-under-test
    and its test parameters when it is instantiated.  The set of URLs from where to retrieve resources is
    specified when a test is started. By passing in the appropriate URLs, the test can be used to test data
    retrieval performance of different shards or different resources at different granularities, etc.
    """
    headers = {'Accept': 'application/json'}

    def __init__(self, host, port, auth, threads, nrequests, plevel):
        """
        """
        self.host = host
        self.port = port
        self.auth = auth
        self.requests = nrequests
        self.threads = threads
        self.plevel = plevel

        self.print_lock = threading.Lock()
        self.cond = threading.Condition()
        self.threads_done = 0

        self.ok_requests = 0
        self.url_counters = []
        self.total_rate = 0


    def make_request(self, session, urls):
        """
        Makes a request for a resource at a random URL selected from a list of URLs passed as input parameter
        :param session: Session to system under test
        :param urls: List of resource URLs
        :return: Status code from the resource request call
        """
        url_index = randrange(0, len(urls))
        r_url = urls[url_index]
        self.url_counters[url_index].increment()

        if not self.auth:
            r = session.get(r_url, headers=self.headers, stream=False)
        else:
            r = session.get(r_url, headers=self.headers, stream=False, auth=('admin', 'admin'))
        return r.status_code


    def worker(self, tid, urls):
        """
        Worker thread function. Connects to system-under-test and makes 'self.requests' requests for
        resources to URLs randomly selected from 'urls'
        :param tid: Worker thread ID
        :param urls: List of resource URLs
        :return: None
        """
        res = {200: 0}

        s = requests.Session()

        with self.print_lock:
            print '    Thread %d: Performing %d requests' % (tid, self.requests)

        with Timer() as t:
            for r in range(self.requests):
                sts = self.make_request(s, urls)
                try:
                    res[sts] += 1
                except KeyError:
                    res[sts] = 1

        ok_rate = res[200] / t.secs
        total_rate = sum(res.values()) / t.secs

        with self.print_lock:
            print 'Thread %d done:' % tid
            print '    Time: %.2f,' % t.secs
            print '    Success rate:  %.2f, Total rate: %.2f' % (ok_rate, total_rate)
            print '    Per-thread stats: ',
            print res
            self.threads_done += 1
            self.total_rate += total_rate

        s.close()

        with self.cond:
            self.cond.notifyAll()


    def run_test(self, urls):
        """
        Runs the performance test. Starts 'self.threads' worker threads, waits for all of them to finish and
        prints results.
        :param urls: List of urls from which to request resources
        :return: None
        """

        threads = []
        self.total_rate = 0

        # Initialize url counters
        del self.url_counters[:]
        for i in range(len(urls)):
            self.url_counters.append(Counter(0))

        # Start all worker threads
        for i in range(self.threads):
            t = threading.Thread(target=self.worker, args=(i, urls))
            threads.append(t)
            t.start()

        # Wait for all threads to finish and measure the execution time
        with Timer() as t:
            while self.threads_done < self.threads:
                with self.cond:
                    self.cond.wait()

        # Print summary results. Each worker prints its owns results too.
        print '\nSummary Results:'
        print '    Requests/sec (total_sum): %.2f' % ((self.threads * self.requests) / t.secs)
        print '    Requests/sec (measured):  %.2f' % ((self.threads * self.requests) / t.secs)
        print '    Time: %.2f' % t.secs
        self.threads_done = 0

        if self.plevel > 0:
            print '    Per URL Counts: ',
            for i in range(len(urls)):
                print '%d' % self.url_counters[i].value,
            print '\n'


class TestUrlGenerator(object):
    """
    Base abstract class to generate test URLs for ShardPerformanceTester. First, an entire subtree representing
    a shard or a set of resources is retrieved, then a set of URLS to access small data stanzas is created. This
    class only defines the framework, the methods that create URL sets are defined in derived classes.
    """

    def __init__(self, host, port, auth):
        """
        Initialization
        :param host: Controller's IP address
        :param port: Controller's RESTCONF port
        :param auth: Indicates whether to use authentication with default user/password (admin/admin)
        :return: None
        """
        self.host = host
        self.port = port
        self.auth = auth
        self.resource_string = ''

    def url_generator(self, data):
        """
        Abstract  URL generator. Must be overridden in a derived class
        :param data: Bulk resource data (JSON) from which to generate the URLs
        :return: List of generated Resources
        """
        print "Abstract class '%s' should never be used standalone" % self.__class__.__name__
        return []

    def generate(self):
        """
        Drives the generation of test URLs. First, it gets a 'bulk' resource (e.g. the entire inventory
         or the entire topology) from the controller specified during int()  and then invokes a resource-specific
         URL generator to create a set of resource-specific URLs.
        """
        t_url = 'http://' + self.host + ":" + self.port + '/' + self.resource_string
        headers = {'Accept': 'application/json'}
        r_url = []

        if not self.auth:
            r = requests.get(t_url, headers=headers, stream=False)
        else:
            r = requests.get(t_url, headers=headers, stream=False, auth=('admin', 'admin'))

        if r.status_code != 200:
            print "Failed to get HTTP response from '%s', code %d" % (t_url, r.status_code)
        else:
            try:
                r_url = self.url_generator(json.loads(r.content))
            except:
                print "Failed to get json from '%s'. Please make sure you are connected to mininet." % r_url

        return r_url


class TopoUrlGenerator(TestUrlGenerator):
    """
    Class to generate test URLs from the topology shard.
    :return: List of generated Resources
    """
    def __init__(self, host, port, auth):
        TestUrlGenerator.__init__(self, host, port, auth)
        self.resource_string = 'restconf/operational/network-topology:network-topology/topology/flow:1'

    def url_generator(self, topo_data):
        url_list = []
        try:
            nodes = topo_data['topology'][0]['node']
            for node in nodes:
                tpoints = node['termination-point']
                for tpoint in tpoints:
                    t_url = 'http://' + self.host + ":" + self.port + \
                            '/restconf/operational/network-topology:network-topology/topology/flow:1/node/' + \
                            node['node-id'] + '/termination-point/' + tpoint['tp-id']
                    url_list.append(t_url)
            return url_list
        except KeyError:
            print 'Error parsing topology json'
            return []


class InvUrlGenerator(TestUrlGenerator):
    """
    Class to generate test URLs from the inventory shard.
    """

    def __init__(self, host, port, auth):
        TestUrlGenerator.__init__(self, host, port, auth)
        self.resource_string = 'restconf/operational/opendaylight-inventory:nodes'

    def url_generator(self, inv_data):
        url_list = []
        try:
            nodes = inv_data['nodes']['node']
            for node in nodes:
                nconns = node['node-connector']
                for nconn in nconns:
                    i_url = 'http://' + self.host + ":" + self.port + \
                            '/restconf/operational/opendaylight-inventory:nodes/node/' + \
                            node['id'] + '/node-connector/' + nconn['id'] + \
                            '/opendaylight-port-statistics:flow-capable-node-connector-statistics'
                    url_list.append(i_url)
            return url_list
        except KeyError:
            print 'Error parsing inventory json'
            return []


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Flow programming performance test: First adds and then deletes flows '
                                                 'into the config tree, as specified by optional parameters.')

    parser.add_argument('--host', default='127.0.0.1',
                        help='Host where odl controller is running (default is 127.0.0.1)')
    parser.add_argument('--port', default='8181',
                        help='Port on which odl\'s RESTCONF is listening (default is 8181)')
    parser.add_argument('--auth', dest='auth', action='store_true', default=False,
                        help="Use the ODL default username/password 'admin'/'admin' to authenticate access to REST; "
                             'default: no authentication')
    parser.add_argument('--threads', type=int, default=1,
                        help='Number of request worker threads to start in each cycle; default=1. ')
    parser.add_argument('--requests', type=int, default=100,
                        help='Number of requests each worker thread will send to the controller; default=100.')
    parser.add_argument('--resource', choices=['inv', 'topo', 'topo+inv', 'all'], default='both',
                        help='Which resource to test: inventory, topology, or both; default both')
    parser.add_argument('--plevel', type=int, default=0,
                        help='Print level: controls output verbosity. 0-lowest, 1-highest; default 0')
    in_args = parser.parse_args()

    topo_urls = []
    inv_urls = []

    # If required, get topology resource URLs
    if in_args.resource != 'inventory':
        tg = TopoUrlGenerator(in_args.host, in_args.port, in_args.auth)
        topo_urls += tg.generate()
        if len(topo_urls) == 0:
            print 'Failed to generate topology URLs'
            sys.exit(-1)

    # If required, get inventory resource URLs
    if in_args.resource != 'topology':
        ig = InvUrlGenerator(in_args.host, in_args.port, in_args.auth)
        inv_urls += ig.generate()
        if len(inv_urls) == 0:
            print 'Failed to generate inventory URLs'
            sys.exit(-1)

    if in_args.resource == 'topo+inv' or in_args.resource == 'all':
        # To have balanced test results, the number of URLs for topology and inventory must be the same
        if len(topo_urls) != len(inv_urls):
            print "The number of topology and inventory URLs don't match"
            sys.exit(-1)

    st = ShardPerformanceTester(in_args.host, in_args.port, in_args.auth, in_args.threads, in_args.requests,
                                in_args.plevel)

    if in_args.resource == 'all' or in_args.resource == 'topo':
        print '==================================='
        print 'Testing topology shard performance:'
        print '==================================='
        st.run_test(topo_urls)

    if in_args.resource == 'all' or in_args.resource == 'inv':
        print '===================================='
        print 'Testing inventory shard performance:'
        print '===================================='
        st.run_test(inv_urls)

    if in_args.resource == 'topo+inv' or in_args.resource == 'all':
        print '==============================================='
        print 'Testing combined shards (topo+inv) performance:'
        print '==============================================='
        st.run_test(topo_urls + inv_urls)




