'''
The purpose of this script is the ability to perform crud operations over the car-people
data model. Credentials 'admin':'admin' are used/hardcoded.
'''
import threading
import Queue
import requests
import json
import copy
import argparse


_template_add_car = {
    "car-entry": [
        {
            "id": "to be replaced",
            "category": "my_category",
            "model": "to be replaced",
            "manufacturer": "my_manufacturer",
            "year": "2015"
        }
    ]
}

_template_add_people = {
    "person": [
        {
            "id": "to be replaced",
            "gender": "male",
            "age": "99",
            "address": "to be replaced",
            "contactNo": "to be replaced"
        }
    ]
}

_template_add_cp_rpc = {
    "input": {
        "car-purchase:person": "to be replaced",
        "car-purchase:person-id": "to be replaced",
        "car-purchase:car-id": "to be replaced"
    }
}


_templates = {
    'add-car': _template_add_car,
    'add-people': _template_add_people,
    'add-car-people-rpc': _template_add_cp_rpc
}


def _prepare_add_car(cntl, port, ilist):
    """Creates a POST http requests to configure a car item in configuration datastore.

    Args:
        :param cntl: controller's ip address or hostname

        :param port: controller's restconf port

        :param ilist: controller item's list contains a list of ids of the cars

    Returns:
        :returns req: http request object
    """
    template = _templates['add-car']
    url = 'http://' + cntl + ':' + port + '/restconf/config/car:cars'
    carlist = copy.deepcopy(template)
    carlist["car-entry"] = []
    for idx in ilist:
        caritem = copy.deepcopy(template["car-entry"][0])
        caritem['id'] = idx
        caritem['model'] = 'model' + str(idx)
        carlist["car-entry"].append(caritem)
    req_data = json.dumps(carlist)
    req = requests.Request('POST', url, headers={'Content-Type': 'application/json'}, data=req_data,
                           auth=('admin', 'admin'))
    return req


def _prepare_add_people(cntl, port, ilist):
    """Creates a POST http requests to configure people in configuration datastore.

    Args:
        :param cntl: controller's ip address or hostname

        :param port: controller's restconf port

        :param ilist: controller item's list contains a list of ids of the people

    Returns:
        :returns req: http request object
    """
    template = _templates['add-people']
    url = 'http://' + cntl + ':' + port + '/restconf/config/people:people'
    peoplelist = copy.deepcopy(template)
    peoplelist["person"] = []
    for idx in ilist:
        person = copy.deepcopy(template["person"][0])
        person['id'] = idx
        person['address'] = 'address' + str(idx)
        person['contactNo'] = str(idx)
        peoplelist["person"].append(person)
    req_data = json.dumps(peoplelist)
    req = requests.Request('POST', url, headers={'Content-Type': 'application/json'}, data=req_data,
                           auth=('admin', 'admin'))
    return req


def _prepare_add_car_people_rpc(cntl, port, ilist):
    """Creates a POST http requests to purchase cars using an rpc.

    Args:
        :param cntl: controller's ip address or hostname

        :param port: controller's restconf port

        :param ilist: controller item's list contains a list of ids of the people

    Returns:
        :returns req: http request object
    """
    template = _templates['add-car-people-rpc']
    url = 'http://' + cntl + ':' + port + '/restconf/operations/car-purchase:buy-car'
    idx = ilist[0]
    purchitem = copy.deepcopy(template)
    purchitem['input']['car-purchase:person'] = "/people:people/people:person[people:id='{0}']".format(idx)
    purchitem['input']['car-purchase:person-id'] = str(idx)
    purchitem['input']['car-purchase:car-id'] = str(idx)
    req_data = json.dumps(purchitem)
    req = requests.Request('POST', url, headers={'Content-Type': 'application/json'}, data=req_data,
                           auth=('admin', 'admin'))
    return req


def _wt_request_sender(thread_id, preparefnc, auth, inqueue=None, exitevent=None, controllers=[], restport='',
                       outqueue=None):
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

        :param outqueue: queue where the results should be put

    Returns:
        nothing, results must be put into the output queue
    """
    ses = requests.Session()
    cntl = controllers[0]
    counter = [0 for i in range(600)]
    loop = True

    while loop:
        try:
            idxlist = inqueue.get(timeout=1)
        except Queue.Empty:
            if exitevent.is_set() and inqueue.empty():
                loop = False
            continue
        req = preparefnc(cntl, restport, idxlist)
        # prep = ses.prepare_request(req)
        prep = req.prepare()
        try:
            rsp = ses.send(prep, timeout=60)
        except requests.exceptions.Timeout:
            counter[99] += 1
            continue
        counter[rsp.status_code] += 1
    res = {}
    for i, v in enumerate(counter):
        if v > 0:
            res[i] = v
    outqueue.put(res)


def _task_executor(preparefnc, controllers=['127.0.0.1'], restport='8181', nrthreads=1, icount=1, ipr=1, auth=True):
    """The main function which drives sending of http requests.

    Creates 2 queues and requested number of 'working threads'.  One queue is filled with flow details and working
    threads read them out and send http requests. The other queue is for sending results from working threads back.
    After the threads' join, it produces a summary result.

    Args:
        :param preparefnc: function to prepare http request object

        :param controllers: a list of controllers host names or ip addresses (default=['127.0.0.1'])

        :param restport: restconf port (default='8181')

        :param nrthreads: number of threads used to send http requests (default=1)

        :param ipr: items per request, number of items sent in one http request

        :param icountpr: number of items to be sent in total

        :param auth: authentication flag

    Returns:
        :returns dict: dictionary of http response counts like {'http_status_code1: 'count1', etc.}
    """

    idxs = [i+1 for i in range(icount)]
    idxgroups = []
    for i in range(0, icount, ipr):
        idxgroups.append(idxs[i:i+ipr])

    # lets fill the queue with details needed for one http requests
    sendqueue = Queue.Queue()
    for ilist in idxgroups:
        sendqueue.put(ilist)

    # result_gueue
    resultqueue = Queue.Queue()
    # creaet exit event
    exitevent = threading.Event()

    # lets start threads which will read details from queues and send http requests
    threads = []
    for i in range(int(nrthreads)):
        thr = threading.Thread(target=_wt_request_sender, args=(i, preparefnc, auth),
                               kwargs={"inqueue": sendqueue, "exitevent": exitevent,
                                       "controllers": controllers, "restport": restport,
                                       "outqueue": resultqueue})
        threads.append(thr)
        thr.start()

    exitevent.set()

    result = {}
    # waitng for reqults and sum them up
    for t in threads:
        t.join()
        # reading partial resutls from sender thread
        part_result = resultqueue.get()
        for k, v in part_result.iteritems():
            if k not in result:
                result[k] = v
            else:
                result[k] += v
    return result


def delete_car(hosts, port, threads, icount, auth, ipr):
    """Delete cars from config datastore.

    Args:
        :param hosts: a list of controllers host names or ip addresses (default=['127.0.0.1'])

        :param port: restconf port (default='8181')

        :param nrthreads: ignored; number of threads used to send http requests (default=1)

        :param icount: ignored; number of items to be deleted

        :param ignored; auth: authentication flag (to be used in the future for auth choices)

        :param ipr: ignored; items per request, not used here, just to keep the same api

    Returns:
        nothing
    """
    url = 'http://' + hosts[0] + ':' + port + '/restconf/config/car:cars'
    rsp = requests.delete(url, auth=('admin', 'admin'))
    assert rsp.status_code == 200


def delete_people(hosts, port, threads, icount, auth, ipr):
    """Delete people from config datastore.

    Args:
        :param hosts: a list of controllers host names or ip addresses (default=['127.0.0.1'])

        :param port: restconf port (default='8181')

        :param nrthreads: ignored; number of threads used to send http requests (default=1)

        :param icount: ignored; number of items to be deleted

        :param ignored; auth: authentication flag (to be used in the future for auth choices)

        :param ipr: ignored; items per request, not used here, just to keep the same api

    Returns:
        nothing
    """
    url = 'http://' + hosts[0] + ':' + port + '/restconf/config/people:people'
    rsp = requests.delete(url, auth=('admin', 'admin'))
    assert rsp.status_code == 200


def delete_car_people(hosts, port, threads, icount, auth, ipr):
    """Delete car-people entries from config datastore.

    Args:
        :param hosts: a list of controllers host names or ip addresses (default=['127.0.0.1'])

        :param port: restconf port (default='8181')

        :param nrthreads: ignored; number of threads used to send http requests (default=1)

        :param icount: ignored; number of items to be deleted

        :param ignored; auth: authentication flag (to be used in the future for auth choices)

        :param ipr: ignored; items per request, not used here, just to keep the same api

    Returns:
        nothing
    """
    url = 'http://' + hosts[0] + ':' + port + '/restconf/config/car-people:car-people'
    rsp = requests.delete(url, auth=('admin', 'admin'))
    assert rsp.status_code == 200


def get_car_people(hosts, port, threads, icount, auth, ipr):
    """Reads car-people entries from config datastore.
    TODO: some needed logic to be added handle http response in the future, e.g. count items in response's content

    Args:
        :param hosts: a list of controllers host names or ip addresses (default=['127.0.0.1'])

        :param port: restconf port (default='8181')

        :param nrthreads: ignored; number of threads used to send http requests (default=1)

        :param icount: ignored; number of items

        :param ignored; auth: authentication flag (to be used in the future for auth choices)

        :param ipr: ignored; items per request, not used here, just to keep the same api

    Returns:
        nothing
    """
    url = 'http://' + hosts[0] + ':' + port + '/restconf/config/car-people:car-people'
    rsp = requests.get(url, params={'Content-Type': 'application/json'}, auth=('admin', 'admin'))
    assert rsp.status_code == 200


def get_people(hosts, port, threads, icount, auth, ipr):
    """Reads people entries from config datastore.
    TODO: some needed logic to be added handle http response in the future, e.g. count items in response's content

    Args:
        :param hosts: a list of controllers host names or ip addresses (default=['127.0.0.1'])

        :param port: restconf port (default='8181')

        :param nrthreads: ignored; number of threads used to send http requests (default=1)

        :param icount: ignored; number of items

        :param ignored; auth: authentication flag (to be used in the future for auth choices)

        :param ipr: ignored; items per request, not used here, just to keep the same api

    Returns:
        nothing
    """
    url = 'http://' + hosts[0] + ':' + port + '/restconf/config/people:people'
    rsp = requests.get(url, params={'Content-Type': 'application/json'}, auth=('admin', 'admin'))
    assert rsp.status_code == 200


def get_car(hosts, port, threads, icount, auth, ipr):
    """Reads car entries from config datastore.
    TODO: some needed logic to be added handle http response in the future, e.g. count items in response's content

    Args:
        :param hosts: a list of controllers host names or ip addresses (default=['127.0.0.1'])

        :param port: restconf port (default='8181')

        :param nrthreads: ignored; number of threads used to send http requests (default=1)

        :param icount: ignored; number of items

        :param ignored; auth: authentication flag (to be used in the future for auth choices)

        :param ipr: ignored; items per request, not used here, just to keep the same api

    Returns:
        nothing
    """
    url = 'http://' + hosts[0] + ':' + port + '/restconf/config/car:cars'
    rsp = requests.get(url, params={'Content-Type': 'application/json'}, auth=('admin', 'admin'))
    assert rsp.status_code == 200


def add_car(hosts, port, threads, icount, auth, ipr):
    """Configure car entries to the config datastore.

    Args:
        :param hosts: a list of controllers host names or ip addresses (default=['127.0.0.1'])

        :param port: restconf port (default='8181')

        :param nrthreads: number of threads used to send http requests (default=1)

        :param icount: number of items to be condigured

        :param ignored; auth: authentication flag (to be used in the future for auth choices)

        :param ipr: items per request, not used here, just to keep the same api

    Returns:
        nothing
    """
    res = _task_executor(_prepare_add_car, controllers=hosts, restport=port, nrthreads=threads, icount=icount,
                         ipr=ipr, auth=auth)
    if res.keys() != [204]:
        raise Exception('Not all cars were configured, {0}'.format(res))


def add_people(hosts, port, threads, icount, auth, ipr):
    """Configure people entries to the config datastore.

    Args:
        :param hosts: a list of controllers host names or ip addresses (default=['127.0.0.1'])

        :param port: restconf port (default='8181')

        :param nrthreads: number of threads used to send http requests (default=1)

        :param icount: number of items to be condigured

        :param ignored; auth: authentication flag (to be used in the future for auth choices)

        :param ipr: items per request, not used here, just to keep the same api

    Returns:
        nothing
    """
    res = _task_executor(_prepare_add_people, controllers=hosts, restport=port, nrthreads=threads, icount=icount,
                         ipr=ipr, auth=auth)
    if res.keys() != [204]:
        raise Exception('Not all people were configured, {0}'.format(res))


def add_car_people_rpc(hosts, port, threads, icount, auth, ipr):
    """Configure car-people entries to the config datastore one by one using rpc

    Args:
        :param hosts: a list of controllers host names or ip addresses (default=['127.0.0.1'])

        :param port: restconf port (default='8181')

        :param nrthreads: number of threads used to send http requests (default=1)

        :param icount: number of items to be condigured

        :param ignored; auth: authentication flag (to be used in the future for auth choices)

        :param ipr: items per request, not used here, just to keep the same api

    Returns:
        nothing
    """
    if ipr != 1:
        raise NotImplementedError('Only 1 item per request is supported, you specified: {0}'.format(icount))

    res = _task_executor(_prepare_add_car_people_rpc, controllers=hosts, restport=port, nrthreads=threads,
                         icount=icount, ipr=ipr, auth=auth)
    if res.keys() != [204]:
        raise Exception('Not all rpc calls passed, {0}'.format(res))


_actions = ['add', 'get', 'delete', 'add-rpc']
_items = ['car', 'people', 'car-people']

_handler_matrix = {
    'add': {'car': add_car, 'people': add_people},
    'get': {'car': get_car, 'people': get_people, 'car-people': get_car_people},
    'delete': {'car': delete_car, 'people': delete_people, },
    'add-rpc': {'car-people': add_car_people_rpc},
}


if __name__ == "__main__":
    """
    This program executes requested action based in given parameters

    It provides 'car', 'people' and 'car-people' crud operations.
    """

    parser = argparse.ArgumentParser(description='Cluster datastore performance test script')

    parser.add_argument('--host', default='127.0.0.1',
                        help='Host where odl controller is running (default is 127.0.0.1)')
    parser.add_argument('--port', default='8181',
                        help='Port on which odl\'s RESTCONF is listening (default is 8181)')
    parser.add_argument('--threads', type=int, default=1,
                        help='Number of request worker threads to start in each cycle; default=1.')
    parser.add_argument('action', choices=_actions, metavar='action', help='Action to be performed.')
    parser.add_argument('--itemtype', choices=_items, default='car',
                        help='Flows-per-Request - number of flows (batch size) sent in each HTTP request; '
                             'default 1')
    parser.add_argument('--itemcount', type=int, help="Items per request", default=1)
    parser.add_argument('--auth', dest='auth', action='store_true',
                        help="Ignored flag; to be used in the future; now credentials 'admin':'admin' are used")
    parser.add_argument('--ipr', type=int, help="Items per request", default=1)

    in_args = parser.parse_args()
    # print in_args.__dict__

    if in_args.action not in _handler_matrix or in_args.itemtype not in _handler_matrix[in_args.action]:
        raise NotImplementedError('Unsupported combination of action: {0} and item: {1}'.format(in_args.action,
                                                                                                in_args.itemtype))

    # TODO: need to filter out situations when we cannot use more items in one rest request (rpc or delete?)
    # this should be done inside handler functions

    hanfunc = _handler_matrix[in_args.action][in_args.itemtype]
    hanfunc([in_args.host], in_args.port, in_args.threads, in_args.itemcount, in_args.auth, in_args.ipr)
