"""
Python invocation of several parallel publish-notifications RPCs.
"""
from robot.api import logger
import time
import Queue
import requests
import string
import threading


_globals = {}


def _send_http_request_thread_impl(rqueue, index, url, data, http_timeout):
    """Start either publish or write transactions rpc based on input.

    :param rqueue: result queue
    :type rqueue: Queue.Queue
    :param index: cluster member index
    :type index: int
    :param url: rpc url
    :type url: string
    :param data: http request content
    :type data: string
    :param http_timeout: http response timeout
    :type http_timeout: int
    """
    logger.info('rpc invoked with details: {}'.format(data))
    try:
        resp = requests.post(url=url, headers={'Content-Type': 'application/xml'},
                             data=data, auth=('admin', 'admin'), timeout=http_timeout)
    except Exception as exc:
        resp = exc
        logger.debug(exc)
    rqueue.put(("member-" + str(index), time.ctime(), resp))


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
        timeout = int(subst_dict['DURATION'])+260
        logger.info('url: {}, data: {}, timeout: {}'.format(url, data, timeout))
        t = threading.Thread(target=_send_http_request_thread_impl,
                             args=(resqueue, i, url, data, timeout))
        t.daemon = True
        t.start()
        lthreads.append(t)

    _globals.update({'threads': lthreads, 'result_queue': resqueue})


def start_write_transactions_on_nodes(host_list, prefix_list, id_prefix, duration, rate, chained_flag=False,
                                      reset_globals=True):
    """Invoke write-transactions rpc on given nodes.

    :param host_list: list of ip address of odl nodes
    :type host_list: list of strings
    :param prefix_list: list of node indexes which coresponds to the ip addresses
    :type prefix_list: list
    :param id_prefix: identifier prefix
    :type id_prefix: string
    :param duration: time in seconds
    :type duration: int
    :param rate: writing transactions rate in transactions per second
    :type rate: int
    :param chained_flag: specify chained vs. simple transactions
    :type chained_flag: bool
    :param reset_globals: reset global variable dict
    :type reset_globals: bool
    """
    if reset_globals:
        _globals.clear()

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
                                        duration, rate, isolated_transactions_flag=False, reset_globals=True):
    """Invoke produce-transactions rpcs on given nodes.

    :param host_list: list of ip address of odl nodes
    :type host_list: list of strings
    :param prefix_list: list of node indexes which coresponds to the ip addresses
    :type prefix_list: list
    :param id_prefix: identifier prefix
    :type id_prefix: string
    :param duration: time in seconds
    :type duration: int
    :param rate: produce transactions rate in transactions per second
    :type rate: int
    :param isolated_transactions_flag: isolated transactions flag
    :type isolated_transactions_flag: bool
    :param reset_globals: reset global variable dict
    :type reset_globals: bool
    """
    if reset_globals:
        _globals.clear()

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
    """Blocking call, waitig for responses from all threads.

    :return: list of triples; triple consists of member name, response time and response object
    :rtype: list[(str, int, requests.Response)]
    """
    lthreads = _globals.pop('threads')
    resqueue = _globals.pop('result_queue')

    for t in lthreads:
        t.join()

    results = []
    while not resqueue.empty():
        results.append(resqueue.get())
    for rsp in results:
        if isinstance(rsp[2], requests.Response):
            logger.info(rsp[2].text)
        else:
            logger.info(rsp[2])
    return results


def get_next_transactions_response():
    """Get http response from write-transactions rpc if available.

    :return: None or a triple consisting of member name, response time and response object"""
    resqueue = _globals.get('result_queue')

    if not resqueue.empty():
        rsp = resqueue.get()
        if isinstance(rsp[2], requests.Response):
            logger.info(rsp[2].text)
        else:
            logger.info(rsp[2])
        return rsp
    return None
