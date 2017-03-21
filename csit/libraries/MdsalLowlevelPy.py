"""
Python invocation of several parallel publish-notifications RPCs.
"""
from robot.api import logger
import Queue
import requests
import string
import threading


_globals = {}


def start_write_transactions_on_nodes(host_list, id_prefix, duration, rate, chained_flag=True):
    """Invoke publish notification rpcs and verify the response.

    :param host_list: list of ip address of odl nodes
    :type host_list: list of strings
    :param id_prefix: identifier prefix
    :type id_prefix: string
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
        logger.info('write-transactions rpc indoked with details: {}'.format(data))
        try:
            resp = requests.post(url=url, headers={'Content-Type': 'application/xml'},
                                 data=data, auth=('admin', 'admin'), timeout=int(duration)+60)
        except Exception as exc:
            resp = exc
            logger.debug(exc)
        rqueue.put(resp)

    logger.info("Input parameters: host_list:{}, id_prefix:{}, duration:{}, rate:{}, chained_flag:{}".format(
        host_list, id_prefix, duration, rate, chained_flag))
    resqueue = _globals.pop('result_queue', Queue.Queue())
    lthreads = _globals.pop('threads', [])
    for i, host in enumerate(host_list):
        url = 'http://{}:8181/restconf/operations/odl-mdsal-lowlevel-control:write-transactions'.format(host)
        t = threading.Thread(target=_write_transactions,
                             args=(resqueue, url, '{}{}'.format(id_prefix, i), duration, rate, chained_flag))
        t.daemon = True
        t.start()
        lthreads.append(t)

    _globals.update({'threads': lthreads, 'result_queue': resqueue})


def wait_for_write_transactions():
    """Blocking call, waitig for responses from all threads"""
    lthreads = _globals.pop('threads')
    resqueue = _globals.pop('result_queue')

    for t in lthreads:
        t.join()

    results = []
    while not resqueue.empty():
        results.append(resqueue.get())
    logger.info(results)
    return results


def get_next_write_transactions_response():
    resqueue = _globals.get('result_queue')

    if not resqueue.empty():
        return resqueue.get()
    return None


def finish_write_transactions():
    lthreads = _globals.pop('threads')
    resqueue = _globals.pop('result_queue')

    for t in lthreads:
        t.join()

    results = []
    while not resqueue.empty():
        results.append(resqueue.get())
    return results
