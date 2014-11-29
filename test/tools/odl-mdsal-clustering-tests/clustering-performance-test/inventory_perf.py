__author__ = "Jan Medved"
__copyright__ = "Copyright(c) 2014, Cisco Systems, Inc."
__license__ = "New-style BSD"
__email__ = "jmedved@cisco.com"

import argparse
import requests
import time
import threading

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

# Initialize the totals over all threads
total_requests = Counter(0)
total_req_rate = Counter(0.0)

total_mbytes = Counter(0.0)
total_mb_rate = Counter(0.0)

putheaders = {'content-type': 'application/json'}
getheaders = {'Accept': 'application/json'}

INVENTORY_URL = 'http://localhost:8080/restconf/operational/opendaylight-inventory:nodes'
N1T0_URL = 'http://localhost:8080/restconf/operational/opendaylight-inventory:nodes/node/openflow:1/table/0'

num_threads = 1

print_lock = threading.Lock()


def get_inventory(tnum, url, hdrs, rnum, cond):
    """

    :param tnum:
    :param url:
    :param hdrs:
    :param rnum:
    :param cond:
    :return:
    """
    total_len = float(0)
    results = {}

    with print_lock:
        print 'Thread %d: Getting %s' % (tnum, url)

    s = requests.Session()
    with Timer() as t:
        for i in range(rnum):
            r = s.get(url, headers=hdrs, stream=False )
            total_len += len(r.content)

            try:
                results[r.status_code] += 1
            except(KeyError):
                results[r.status_code] = 1

    total = sum(results.values())
    rate = total/t.secs
    total_requests.increment(total)
    total_req_rate.increment(rate)

    mbytes = total_len / (1024*1024)
    mrate = mbytes/t.secs
    total_mbytes.increment(mbytes)
    total_mb_rate.increment(mrate)

    with print_lock:
        print '\nThread %d: ' % tnum
        print '    Elapsed time: %.2f,' % t.secs
        print '    Requests: %d, Requests/sec: %.2f' % (total, rate)
        print '    Volume: %.2f MB, Rate: %.2f MByte/s' % (mbytes, mrate)
        print '    Results: ',
        print results

    with cond:
        cond.notifyAll()


if __name__ == "__main__":

    parser = argparse.ArgumentParser(description='Restconf test program')
    parser.add_argument('--odlhost', default='127.0.0.1', help='host where '
                        'odl controller is running (default is 127.0.0.1)')
    parser.add_argument('--odlport', default='8080', help='port on '
                        'which odl\'s RESTCONF is listening (default is 8080)')
    parser.add_argument('--requests', type=int, default=10, help='number of '
                        'requests to send')
    parser.add_argument('--url', default='restconf/operational/opendaylight-inventory:nodes',
                        help='Url to send.')
    parser.add_argument('--nthreads', type=int, default=1,
                        help='Number of request worker threads, default=1')
    in_args = parser.parse_args()

    url = 'http://' + in_args.odlhost + ":" + in_args.odlport + '/' + in_args.url

    threads = []
    nthreads = int(in_args.nthreads)
    cond = threading.Condition()

    for i in range(nthreads):
        t = threading.Thread(target=get_inventory,
                             args=(i,url, getheaders, int(in_args.requests), cond))
        threads.append(t)
        t.start()

    finished = 0
    while finished < nthreads:
        with cond:
            cond.wait()
            finished = finished + 1

    print '\nAggregate requests: %d, Aggregate requests/sec: %.2f' % (total_requests.value,
                                                                    total_req_rate.value)
    print 'Aggregate Volume: %.2f MB, Aggregate Rate: %.2f MByte/s' % (total_mbytes.value,
                                                                       total_mb_rate.value)

#    get_inventory(url, getheaders, int(in_args.requests))

#    get_inventory(N1T0_URL, getheaders, 100)
