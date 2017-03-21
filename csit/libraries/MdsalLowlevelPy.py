"""
Python invocation of several parallel publish-notifications RPCs.
"""
import Queue
import requests
import string
import threading

_globals = {}

def publish_notifications(host, grprefix, duration, rate, nrpairs=1):
    """Invoke publish notification rpcs and verify the response.

    :param host: ip address of odl node
    :type host: string
    :param grprefix: prefix identifier for publisher/listener pair
    :type grprefix: string
    :param duration: publishing notification duration in seconds
    :type duration: int
    :param rate: events rate per second
    :type rate: int
    :param nrpairs: number of publisher/listener pairs, id suffix is counted from it
    :type nrpairs: int
    """
    def _publ_notifications(rqueue, url, grid, duration, rate):
        dtmpl = string.Template('''<input xmlns="tag:opendaylight.org,2017:controller:yang:lowlevel:control">
  <id>$ID</id>
  <seconds>$DURATION</seconds>
  <notifications-per-second>$RATE</notifications-per-second>
</input>''')
        data = dtmpl.substitute({'ID': grid, 'DURATION': duration, 'RATE': rate})
        try:
            resp = requests.post(url=url, headers={'Content-Type': 'application/xml'},
                                 data=data, auth=('admin', 'admin'), timeout=int(duration)+60)
        except Exception as exc:
            resp = exc
        rqueue.put(resp)

    resqueue = Queue.Queue()
    lthreads = []
    url = 'http://{}:8181/restconf/operations/odl-mdsal-lowlevel-control:publish-notifications'.format(host)
    for i in range(nrpairs):
        t = threading.Thread(target=_publ_notifications,
                             args=(resqueue, url, '{}{}'.format(grprefix, i+1), duration, rate))
        t.daemon = True
        t.start()
        lthreads.append(t)

    for t in lthreads:
        t.join()

    for i in range(nrpairs):
        resp = resqueue.get()
        assert resp.status_code == 200

def initiate_write_transactions_on_nodes(host_list, grid, duration, rate, chained_flag=True):
    """Invoke publish notification rpcs and verify the response.

    :param host_list: list of ip address of odl nodes
    :type host_list: list of strings
    :param grid: identifier
    :type grid: string
    :param duration: time in seconds
    :type duration: int
    :param rate: publishing notification duration in seconds
    :type rate: int
    :param chained_flag: events rate per second
    :type chained: bool
    """
    def _write_transactions(rqueue, url, grid, duration, rate, chained_flag):
        dtmpl = string.Template('''<input xmlns="tag:opendaylight.org,2017:controller:yang:lowlevel:control">
  <id>$ID</id>
  <seconds>$DURATION</seconds>
  <transactions-per-second>$RATE</transactions-per-second>
  <chained-transactions>$CHAINED_FLAG</chained-transactions>
</input>''')
        data = dtmpl.substitute({'ID': grid, 'DURATION': duration, 'RATE': rate, 'CHAINED_FLAG': chained_flag})
        try:
            resp = requests.post(url=url, headers={'Content-Type': 'application/xml'},
                                 data=data, auth=('admin', 'admin'), timeout=int(duration)+60)
        except Exception as exc:
            resp = exc
        rqueue.put(resp)

    resqueue = Queue.Queue()
    lthreads = []
    for host in range(hosts):
        url = 'http://{}:8181/restconf/operations/odl-mdsal-lowlevel-control:write-transactions'.format(host)
        t = threading.Thread(target=_publ_notifications, args=(resqueue, url, grid, duration, rate, chained_flag))
        t.daemon = True
        t.start()
        lthreads.append(t)

    _globals.update({'threads': lthreads, 'hosts': hosts, 'result_queue': resqueue})


def wait_for_write_transactions():
    lthreads = _globals.pop('threads')
    hosts = _globals.pop('hosts')
    resqueue = _globals.pop('result_queue')

    for t in lthreads:
        t.join()

    results = []
    for host in hosts:
        results.append(resqueue.get())
    return results

