"""
Python invocation of several parallel publish-notifications RPCs.
"""
from robot.api import logger
import Queue
import requests
import string
import threading


_globals = {}


def _send_http_request_thread_impl(rqueue, url, data, http_timeout):
    """Start either publish or write transactions rpc based on input.

    :param rqueue: result queue
    :type rqueue: Queue.Queue
    :param url: rpc url
    :type url: string
    :param data: http request content
    :type data: string
    :param http_timeout: http response timeout
    :type http_timeout: int
    """
    logger.info('rpc indoked with details: {}'.format(data))
    try:
        resp = requests.post(url=url, headers={'Content-Type': 'application/xml'},
                             data=data, auth=('admin', 'admin'), timeout=http_timeout)
    except Exception as exc:
        resp = exc
        logger.debug(exc)
    rqueue.put(resp)


def _initiate_rpcs(host_list, prefix_list, url_templ, data_templ, subst_dict):
    """Initiate rpc on given hosts.

    :param host_list: list of ip address of odl nodes
    :type host_list: list of strings
    :param id_prefix: list of node indexes which coresponds to the ip addresses
    :type id_prefix: string
    :param url_templ: url template
    :type url_templ: string.Template object
    :param data_templ: http request data
    :type data_templ: string.Template object
    :param subst_dict: dictionary with key value pairs to be used with template
    :type subst_dict: dict
    """
    resqueue = _globals.pop('result_queue', Queue.Queue())
    lthreads = _globals.pop('threads', [])
    for i, host in enumerate(host_list):
        subst_dict.update({'ID': '{}{}'.format(subst_dict['ID_PREFIX'], prefix_list[i])})
        url = url_templ.substitute({'HOST': host})
        data = data_templ.substitute(subst_dict)
        timeout = int(subst_dict['DURATION'])+60
        logger.info('url: {}, data: {}, timeout: {}'.format(url, data, timeout))
        t = threading.Thread(target=_send_http_request_thread_impl,
                             args=(resqueue, url, data, timeout))
        t.daemon = True
        t.start()
        lthreads.append(t)

    _globals.update({'threads': lthreads, 'result_queue': resqueue})


def start_write_transactions_on_nodes(host_list, prefix_list, id_prefix, duration, rate, chained_flag=False):
    """Invoke write-transactions rpc on given nodes.

    :param host_list: list of ip address of odl nodes
    :type host_list: list of strings
    :param id_prefix: list of node indexes which coresponds to the ip addresses
    :type id_prefix: string
    :param id_prefix: identifier prefix
    :type id_prefix: string
    :param duration: time in seconds
    :type duration: int
    :param rate: writing transactions rate in transactions per second
    :type rate: int
    :param chained_flag: specify chained vs. simple transactions
    :type chained_flag: bool
    """
    logger.info(
        "Input parameters: host_list:{}, prefix_list:{}, id_prefix:{}, duration:{}, rate:{}, chained_flag:{}".format(
            host_list, prefix_list, id_prefix, duration, rate, chained_flag))
    datat = string.Template('''<input xmlns="tag:opendaylight.org,2017:controller:yang:lowlevel:control">
  <id>$ID</id>
  <seconds>$DURATION</seconds>
  <transactions-per-second>$RATE</transactions-per-second>
  <chained-transactions>$CHAINED_FLAG</chained-transactions>
</input>''')
    subst_dict = {'ID_PREFIX': id_prefix, 'DURATION': duration, 'RATE': rate, 'CHAINED_FLAG': chained_flag}
    urlt = string.Template('''http://$HOST:8181/restconf/operations/odl-mdsal-lowlevel-control:write-transactions''')
    _initiate_rpcs(host_list, prefix_list, urlt, datat, subst_dict)


def start_produce_transactions_on_nodes(host_list, prefix_list, id_prefix,
                                        duration, rate, isolated_transactions_flag=True):
    """Invoke produce-transactions rpcs on given nodes.

    :param host_list: list of ip address of odl nodes
    :type host_list: list of strings
    :param id_prefix: list of node indexes which coresponds to the ip addresses
    :type id_prefix: string
    :param id_prefix: identifier prefix
    :type id_prefix: string
    :param duration: time in seconds
    :type duration: int
    :param rate: produce transactions rate in transactions per second
    :type rate: int
    :param isolated_transactions_flag: isolated transactions flag
    :type isolated_transactions_flag: bool
    """
    msg = "host_list:{}, prefix_list:{} ,id_prefix:{}, duration:{}, rate:{}, isolated_transactions:{}".format(
            host_list, prefix_list, id_prefix, duration, rate, isolated_transactions_flag)
    msg = "Input parameters: " + msg
    logger.info(msg)
    datat = string.Template('''<input xmlns="tag:opendaylight.org,2017:controller:yang:lowlevel:control">
  <id>$ID</id>
  <seconds>$DURATION</seconds>
  <transactions-per-second>$RATE</transactions-per-second>
  <isolated-transactions>$ISOLATED_TRANSACTIONS</isolated-transactions>
</input>''')
    subst_dict = {'ID_PREFIX': id_prefix, 'DURATION': duration, 'RATE': rate,
                  'ISOLATED_TRANSACTIONS': isolated_transactions_flag}
    urlt = string.Template('''http://$HOST:8181/restconf/operations/odl-mdsal-lowlevel-control:produce-transactions''')
    _initiate_rpcs(host_list, prefix_list, urlt, datat, subst_dict)


def wait_for_transactions():
    """Blocking call, waitig for responses from all threads."""
    lthreads = _globals.pop('threads')
    resqueue = _globals.pop('result_queue')

    for t in lthreads:
        t.join()

    results = []
    while not resqueue.empty():
        results.append(resqueue.get())
    logger.info(results)
    return results


def get_next_transactions_response():
    """Get http response from write-transactions rpc if available."""
    resqueue = _globals.get('result_queue')

    if not resqueue.empty():
        return resqueue.get()
    return None
