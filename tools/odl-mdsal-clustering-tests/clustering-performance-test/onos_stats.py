import requests
import json
import argparse
import sys
import netaddr
import threading
import Queue
import random
import copy
import time


flow_template = {
    "appId": 10,
    "priority": 40000,
    "timeout": 0,
    "isPermanent": True,
    "deviceId": "of:0000000000000001",
    "treatment": {
        "instructions": [
            {
                "type": "NOACTION"
            }
        ],
        "deferred": []
    },
    "selector": {
        "criteria": [
            {
                "type": "ETH_TYPE",
                "ethType": 2048
            },
            {
                "type": "IPV4_DST",
                "ip": "10.0.0.0/32"
            }
        ]
    }
}


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


def _prepare_post(cntl, method, flows, template=None):
    """Creates a POST http requests to configure a flow in configuration datastore.

    Args:
        :param cntl: controller's ip address or hostname

        :param method: determines http request method

        :param flows: list of flow details

        :param template: flow template to be to be filled

    Returns:
        :returns req: http request object
    """
    fl1 = flows[0]
    dev_id, ip = fl1
    url = 'http://' + cntl + ':' + '8181/onos/v1/flows/' + dev_id
    flow = copy.deepcopy(template)
    flow["deviceId"] = dev_id
    flow["selector"]["criteria"][1]["ip"] = '%s/32' % str(netaddr.IPAddress(ip))
    req_data = json.dumps(flow)
    req = requests.Request(method, url, headers={'Content-Type': 'application/json'},
                           data=req_data, auth=('onos', 'rocks'))
    return req


def _prepare_delete(cntl, method, flows, template=None):
    """Creates a DELETE http requests to configure a flow in configuration datastore.

    Args:
        :param cntl: controller's ip address or hostname

        :param method: determines http request method

        :param flows: list of flow details

        :param template: flow template to be to be filled

    Returns:
        :returns req: http request object
    """
    fl1 = flows[0]
    dev_id, flow_id = fl1
    url = 'http://' + cntl + ':' + '8181/onos/v1/flows/' + dev_id + '/' + flow_id
    req = requests.Request(method, url, auth=('onos', 'rocks'))
    return req


def _wt_request_sender(thread_id, preparefnc, inqueue=None, exitevent=None, controllers=[], restport='',
                       template=None, outqueue=None, method=None):
    """The funcion sends http requests.

    Runs in the working thread. It reads out flow details from the queue and sends apropriate http requests
    to the controller

    Args:
        :param thread_id: thread id

        :param preparefnc: function to preparesthe http request

        :param inqueue: input queue, flow details are comming from here

        :param exitevent: event to notify working thread that parent (task executor) stopped filling the input queue

        :param controllers: a list of controllers' ip addresses or hostnames

        :param restport: restconf port

        :param template: flow template used for creating flow content

        :param outqueue: queue where the results should be put

        :param method: method derermines the type of http request

    Returns:
        nothing, results must be put into the output queue
    """
    ses = requests.Session()
    cntl = controllers[0]
    counter = [0 for i in range(600)]
    loop = True

    while loop:
        try:
            flowlist = inqueue.get(timeout=1)
        except Queue.Empty:
            if exitevent.is_set() and inqueue.empty():
                loop = False
            continue
        req = preparefnc(cntl, method, flowlist, template=template)
        # prep = ses.prepare_request(req)
        prep = req.prepare()
        try:
            rsp = ses.send(prep, timeout=5)
        except requests.exceptions.Timeout:
            counter[99] += 1
            continue
        counter[rsp.status_code] += 1
    res = {}
    for i, v in enumerate(counter):
        if v > 0:
            res[i] = v
    outqueue.put(res)


def get_device_ids(controller='127.0.0.1', port=8181):
    """Returns a list of switch ids"""
    rsp = requests.get(url='http://{0}:{1}/onos/v1/devices'.format(controller, port), auth=('onos', 'rocks'))
    if rsp.status_code != 200:
        return []
    devices = json.loads(rsp.content)['devices']
    ids = [d['id'] for d in devices if 'of:' in d['id']]
    return ids


def get_flow_ids(controller='127.0.0.1', port=8181):
    """Returns a list of flow ids"""
    rsp = requests.get(url='http://{0}:{1}/onos/v1/flows'.format(controller, port), auth=('onos', 'rocks'))
    if rsp.status_code != 200:
        return []
    flows = json.loads(rsp.content)['flows']
    ids = [f['id'] for f in flows]
    return ids


def get_flow_simple_stats(controller='127.0.0.1', port=8181):
    """Returns a list of flow ids"""
    rsp = requests.get(url='http://{0}:{1}/onos/v1/flows'.format(controller, port), auth=('onos', 'rocks'))
    if rsp.status_code != 200:
        return []
    flows = json.loads(rsp.content)['flows']
    res = {}
    for f in flows:
        if f['state'] not in res:
            res[f['state']] = 1
        else:
            res[f['state']] += 1
    return res


def get_flow_device_pairs(controller='127.0.0.1', port=8181, flow_details=[]):
    """Pairing flows from controller with deteils we used ofr creation"""
    rsp = requests.get(url='http://{0}:{1}/onos/v1/flows'.format(controller, port), auth=('onos', 'rocks'))
    if rsp.status_code != 200:
        return
    flows = json.loads(rsp.content)['flows']
    # print "Flows", flows
    # print "Details", flow_details
    for dev_id, ip in flow_details:
        # print "looking for details", dev_id, ip
        for f in flows:
            # lets identify if it is our flow
            if f["treatment"]["instructions"][0]["type"] != "DROP":
                # print "NOT DROP"
                continue
            if f["deviceId"] == dev_id:
                if "ip" in f["selector"]["criteria"][0]:
                    item_idx = 0
                elif "ip" in f["selector"]["criteria"][1]:
                    item_idx = 1
                else:
                    continue
                # print "Comparing", '%s/32' % str(netaddr.IPAddress(ip))
                if f["selector"]["criteria"][item_idx]["ip"] == '%s/32' % str(netaddr.IPAddress(ip)):
                    # print dev_id, ip, f
                    yield dev_id, f["id"]
                    break


def get_flow_to_remove(controller='127.0.0.1', port=8181):
    """Pairing flows from controller with deteils we used ofr creation"""
    rsp = requests.get(url='http://{0}:{1}/onos/v1/flows'.format(controller, port), auth=('onos', 'rocks'))
    if rsp.status_code != 200:
        return
    flows = json.loads(rsp.content)['flows']
    # print "Flows", flows
    # print "Details", flow_details

    for f in flows:
        # lets identify if it is our flow
        if f["treatment"]["instructions"][0]["type"] != "NOACTION":
            # print "NOT DROP"
            continue
        if "ip" in f["selector"]["criteria"][0]:
            item_idx = 0
        elif "ip" in f["selector"]["criteria"][1]:
            item_idx = 1
        else:
            continue
            # print "Comparing", '%s/32' % str(netaddr.IPAddress(ip))
        ipstr = f["selector"]["criteria"][item_idx]["ip"]
        if '10.' in ipstr and '/32' in ipstr:
            # print dev_id, ip, f
            yield (f["deviceId"], f["id"])


def main(*argv):

    parser = argparse.ArgumentParser(description='Flow programming performance test: First adds and then deletes flows '
                                                 'into the config tree, as specified by optional parameters.')

    parser.add_argument('--host', default='127.0.0.1',
                        help='Host where onos controller is running (default is 127.0.0.1)')
    parser.add_argument('--port', default='8181',
                        help='Port on which onos\'s RESTCONF is listening (default is 8181)')

    in_args = parser.parse_args(*argv)
    print in_args

    # get device ids
    base_dev_ids = get_device_ids(controller=in_args.host)
    base_flow_ids = get_flow_ids(controller=in_args.host)
    # ip
    ip_addr = Counter(int(netaddr.IPAddress('10.0.0.1')))
    # prepare func
    preparefnc = _prepare_post

    print "BASELINE:"
    print "    devices:", len(base_dev_ids)
    print "    flows  :", len(base_flow_ids)

    # lets print some stats
    print "\n\nSome stats monitoring ...."
    print get_flow_simple_stats(controller=in_args.host)

if __name__ == "__main__":
    main(sys.argv[1:])
