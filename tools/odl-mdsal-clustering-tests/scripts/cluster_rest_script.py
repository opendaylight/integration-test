"""
The purpose of this script is the ability to perform crud operations over
the car-people data model.
"""
import threading
import Queue
import requests
import json
import copy
import argparse
import logging


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

_template_add_people_rpc = {
    "input": [
        {
            "people:id": "to be replaced",
            "people:gender": "male",
            "people:age": "99",
            "people:address": "to be replaced",
            "people:contactNo": "to be replaced"
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


def _build_url(odl_ip, port, uri):
    """Compose URL from generic IP, port and URI fragment.

    Args:
        :param odl_ip: controller's ip address or hostname

        :param port: controller's restconf port

        :param uri: URI without /restconf/ to complete URL

    Returns:
        :returns url: full restconf url corresponding to params
    """

    url = "http://" + odl_ip + ":" + port + "/restconf/" + uri
    return url


def _build_post(odl_ip, port, uri, python_data, auth):
    """Create a POST http request with generic on URI and data.

    Args:
        :param odl_ip: controller's ip address or hostname

        :param port: controller's restconf port

        :param uri: URI without /restconf/ to complete URL

        :param python_data: python object to serialize into textual data

        :param auth: authentication credentials

    Returns:
        :returns http request object
    """

    url = _build_url(odl_ip, port, uri)
    text_data = json.dumps(python_data)
    header = {"Content-Type": "application/json"}
    req = requests.Request("POST", url, headers=header, data=text_data, auth=auth)
    return req


def _prepare_add_car(odl_ip, port, item_list, auth):
    """Creates a POST http requests to configure a car item in configuration datastore.

    Args:
        :param odl_ip: controller's ip address or hostname

        :param port: controller's restconf port

        :param item_list: controller item's list contains a list of ids of the cars

        :param auth: authentication credentials

    Returns:
        :returns req: http request object
    """

    container = {"car-entry": []}
    for item in item_list:
        entry = copy.deepcopy(_template_add_car["car-entry"][0])
        entry["id"] = item
        entry["model"] = "model" + str(item)
        container["car-entry"].append(entry)
    req = _build_post(odl_ip, port, "config/car:cars", container, auth)
    return req


def _prepare_add_people_rpc(odl_ip, port, item_list, auth):
    """Creates a POST http requests to configure people in configuration datastore.

    Args:
        :param odl_ip: controller's ip address or hostname

        :param port: controller's restconf port

        :param item_list: controller item's list contains a list of ids of the people

        :param auth: authentication credentials

    Returns:
        :returns req: http request object
    """

    container = {"input": {}}
    item = item_list[0]
    entry = container["input"]
    entry["people:id"] = str(item)
    entry["people:address"] = "address" + str(item)
    entry["people:contactNo"] = str(item)
    container["input"] = entry
    req = _build_post(odl_ip, port, "operations/people:add-person", container, auth)
    return req


def _prepare_add_car_people_rpc(odl_ip, port, item_list, auth):
    """Creates a POST http requests to purchase cars using an rpc.

    Args:
        :param odl_ip: controller's ip address or hostname

        :param port: controller's restconf port

        :param item_list: controller item's list contains a list of ids of the people
        only the first item is considered

        :param auth: authentication credentials

    Returns:
        :returns req: http request object
    """

    container = {"input": {}}
    item = item_list[0]
    entry = container["input"]
    entry["car-purchase:person"] = "/people:people/people:person[people:id='" + str(item) + "']"
    entry["car-purchase:person-id"] = str(item)
    entry["car-purchase:car-id"] = str(item)
    container["input"] = entry
    req = _build_post(odl_ip, port, "operations/car-purchase:buy-car", container, auth)
    return req


def _request_sender(thread_id, preparing_function, auth, in_queue=None,
                    exit_event=None, odl_ip="127.0.0.1", port="8181", out_queue=None):
    """The funcion sends http requests.

    Runs in the working thread. It reads out flow details from the queue and
    sends apropriate http requests to the controller

    Args:
        :param thread_id: thread id

        :param preparing_function: function to prepare the http request

        :param in_queue: input queue, flow details are comming from here

        :param exit_event: event to notify working thread that the parent
                           (task executor) stopped filling the input queue

        :param odl_ip: ip address of ODL; default="127.0.0.1"

        :param port: restconf port; default="8181"

        :param out_queue: queue where the results should be put

    Returns:
        None (results is put into the output queue)
    """

    ses = requests.Session()
    counter = [0 for i in range(600)]

    while True:
        try:
            item_list = in_queue.get(timeout=1)
        except Queue.Empty:
            if exit_event.is_set() and in_queue.empty():
                break
            continue
        req = preparing_function(odl_ip, port, item_list, auth)
        prep = req.prepare()
        try:
            rsp = ses.send(prep, timeout=60)
        except requests.exceptions.Timeout:
            counter[99] += 1
            logger.error("No response from %s", odl_ip)
            continue
        logger.debug("%s %s", rsp.request, rsp.request.url)
        logger.debug("Headers %s:", rsp.request.headers)
        logger.debug("Body: %s", rsp.request.body)
        logger.debug("Response: %s", rsp.text)
        logger.debug("%s %s", rsp, rsp.reason)
        counter[rsp.status_code] += 1
    responses = {}
    for response_code, count in enumerate(counter):
        if count > 0:
            responses[response_code] = count
    out_queue.put(responses)
    logger.info("Response code(s) got per number of requests: %s", responses)


def _task_executor(preparing_function, odl_ip="127.0.0.1", port="8181",
                   thread_count=1, item_count=1, items_per_request=1,
                   auth=('admin', 'admin')):
    """The main function which drives sending of http requests.

    Creates 2 queues and requested number of "working threads".
    One queue is filled with flow details and working
    threads read them out and send http requests.
    The other queue is for sending results from working threads back.
    After the threads' join, it produces a summary result.

    Args:
        :param preparing_function: function to prepare http request object

        :param odl_ip: ip address of ODL or comma separated addesses; default="127.0.0.1"

        :param port: restconf port; default="8181"

        :param thread_count: number of threads used to send http requests; default=1

        :param items_per_request: items per request, number of items sent in one http request

        :param item_countpr: number of items to be sent in total

        :param auth: authentication credentials

    Returns:
        :returns dict: dictionary of http response counts like
                       {"http_status_code1: "count1", etc.}
    """

    # geting hosts
    hosts = odl_ip.split(',')
    nrhosts = len(hosts)

    items = [i + 1 for i in range(item_count)]
    item_groups = []
    for i in range(0, item_count, items_per_request):
        item_groups.append(items[i:i + items_per_request])

    # fill the queue with details needed for one http requests
    send_queue = Queue.Queue()
    for item_list in item_groups:
        send_queue.put(item_list)

    # create an empty result queue
    result_queue = Queue.Queue()
    # create exit event
    exit_event = threading.Event()

    # start threads to read details from queues and to send http requests
    threads = []
    for i in range(int(thread_count)):
        thr = threading.Thread(target=_request_sender,
                               args=(i, preparing_function, auth),
                               kwargs={"in_queue": send_queue, "exit_event": exit_event,
                                       "odl_ip": hosts[i % nrhosts], "port": port,
                                       "out_queue": result_queue})
        threads.append(thr)
        thr.start()

    exit_event.set()

    result = {}
    # wait for reqults and sum them up
    for t in threads:
        t.join()
        # read partial resutls from sender thread
        part_result = result_queue.get()
        for k, v in part_result.iteritems():
            if k not in result:
                result[k] = v
            else:
                result[k] += v
    return result


def _build_delete(odl_ip, port, uri):
    """Send DELETE to generic URI, assert status code is 200.

    Args:
        :param odl_ip: ip address of ODL

        :param port: restconf port

        :param uri: URI without /restconf/ to complete URL

    Returns:
        None

    Note:
         Raise AssertionError if response status code != 200
    """

    url = _build_url(odl_ip, port, uri)
    rsp = requests.delete(url, auth=auth)
    logger.debug("%s %s", rsp.request, rsp.request.url)
    logger.debug("Headers %s:", rsp.request.headers)
    logger.debug("Body: %s", rsp.request.body)
    logger.debug("Response: %s", rsp.text)
    logger.info("%s %s", rsp, rsp.reason)
    assert rsp.status_code == 200, rsp.text


def delete_car(odl_ip, port, thread_count, item_count, auth, items_per_request):
    """Delete cars container from config datastore, assert success.

    Args:
        :param odl_ip: ip address of ODL

        :param port: restconf port

        :param thread_count: ignored; only 1 thread needed

        :param item_count: ignored; whole container is deleted

        :param auth: authentication credentials

        :param items_per_request: ignored; only 1 request needed

    Returns:
        None
    """

    logger.info("Delete all cars from %s:%s", odl_ip, port)
    _build_delete(odl_ip, port, "config/car:cars")


def delete_people(odl_ip, port, thread_count, item_count, auth, items_per_request):
    """Delete people container from config datastore.

    Args:
        :param odl_ip: ip address of ODL

        :param port: restconf port

        :param thread_count: ignored; only 1 thread needed

        :param item_count: ignored; whole container is deleted

        :param auth: authentication credentials

        :param items_per_request: ignored; only 1 request needed

    Returns:
        None
    """

    logger.info("Delete all people from %s:%s", odl_ip, port)
    _build_delete(odl_ip, port, "config/people:people")


def delete_car_people(odl_ip, port, thread_count, item_count, auth, items_per_request):
    """Delete car-people container from config datastore.

    Args:
        :param odl_ip: ip address of ODL

        :param port: restconf port

        :param thread_count: ignored; only 1 thread needed

        :param item_count: ignored; whole container is deleted

        :param auth: authentication credentials

        :param items_per_request: ignored; only 1 request needed

    Returns:
        None
    """

    logger.info("Delete all purchases from %s:%s", odl_ip, port)
    _build_delete(odl_ip, port, "config/car-people:car-people")


def _build_get(odl_ip, port, uri):
    """Send GET to generic URI.

    Args:
        :param odl_ip: ip address of ODL

        :param port: restconf port

        :param uri: URI without /restconf/ to complete URL

    Returns:
        None

    Note:
         Raise AssertionError if response status code != 200
    """

    url = _build_url(odl_ip, port, uri)
    rsp = requests.get(url, auth=auth)
    logger.debug("%s %s", rsp.request, rsp.request.url)
    logger.debug("Headers %s:", rsp.request.headers)
    logger.debug("Body: %s", rsp.request.body)
    logger.debug("Response: %s", rsp.text)
    logger.info("%s %s", rsp, rsp.reason)
    assert rsp.status_code == 200, rsp.text


def get_car(odl_ip, port, thread_count, item_count, auth, items_per_request):
    """Reads car entries from config datastore.

    TODO: some needed logic to be added handle http response in the future,
          e.g. count items in response's content

    Args:
        :param odl_ip: ip address of ODL

        :param port: restconf port

        :param thread_count: ignored; only 1 thread needed

        :param item_count: ignored; whole container is deleted

        :param auth: authentication credentials

        :param items_per_request: ignored; only 1 request needed

    Returns:
        None
    """

    logger.info("Get all cars from %s:%s", odl_ip, port)
    _build_get(odl_ip, port, "config/car:cars")


def get_people(odl_ip, port, thread_count, item_count, auth, items_per_request):
    """Reads people entries from config datastore.

    TODO: some needed logic to be added handle http response in the future,
          e.g. count items in response's content

    Args:
        :param odl_ip: ip address of ODL

        :param port: restconf port

        :param thread_count: ignored; only 1 thread needed

        :param item_count: ignored; whole container is deleted

        :param auth: authentication credentials

        :param items_per_request: ignored; only 1 request needed

    Returns:
        None
    """

    logger.info("Get all people from %s:%s", odl_ip, port)
    _build_get(odl_ip, port, "config/people:people")


def get_car_people(odl_ip, port, thread_count, item_count, auth, items_per_request):
    """Reads car-people entries from config datastore.

    TODO: some needed logic to be added handle http response in the future,
          e.g. count items in response's content

    Args:
        :param odl_ip: ip address of ODL

        :param port: restconf port

        :param thread_count: ignored; only 1 thread needed

        :param item_count: ignored; whole container is deleted

        :param auth: authentication credentials

        :param items_per_request: ignored; only 1 request needed

    Returns:
        None
    """

    logger.info("Get all purchases from %s:%s", odl_ip, port)
    _build_get(odl_ip, port, "config/car-people:car-people")


def add_car(odl_ip, port, thread_count, item_count, auth, items_per_request):
    """Configure car entries to the config datastore.

    Args:
        :param odl_ip: ip address of ODL

        :param port: restconf port

        :param thread_count: number of threads used to send http requests; default=1

        :param item_count: number of items to be configured

        :param auth: authentication credentials

        :param items_per_request: items per request, not used here,
                                  just to keep the same api

    Returns:
        None
    """

    logger.info("Add %s car(s) to %s:%s (%s per request)",
                item_count, odl_ip, port, items_per_request)
    res = _task_executor(_prepare_add_car, odl_ip=odl_ip, port=port,
                         thread_count=thread_count, item_count=item_count,
                         items_per_request=items_per_request, auth=auth)
    if res.keys() != [204]:
        logger.error("Not all cars were configured: " + repr(res))
        raise Exception("Not all cars were configured: " + repr(res))


def add_people_rpc(odl_ip, port, thread_count, item_count, auth, items_per_request):
    """Configure people entries to the config datastore.

    Args:
        :param odl_ip: ip address of ODL; default="127.0.0.1"

        :param port: restconf port; default="8181"

        :param thread_count: number of threads used to send http requests; default=1

        :param item_count: number of items to be condigured

        :param auth: authentication credentials

        :param items_per_request: items per request, not used here,
                                  just to keep the same api

    Returns:
        None
    """

    logger.info("Add %s people to %s:%s (%s per request)",
                item_count, odl_ip, port, items_per_request)
    if items_per_request != 1:
        logger.error("Only 1 item per request is supported, " +
                     "you specified: {0}".format(item_count))
        raise NotImplementedError("Only 1 item per request is supported, " +
                                  "you specified: {0}".format(item_count))
    res = _task_executor(_prepare_add_people_rpc, odl_ip=odl_ip, port=port,
                         thread_count=thread_count, item_count=item_count,
                         items_per_request=items_per_request, auth=auth)
    if res.keys() != [200]:
        logger.error("Not all people were configured: " + repr(res))
        raise Exception("Not all people were configured: " + repr(res))


def add_car_people_rpc(odl_ip, port, thread_count, item_count, auth,
                       items_per_request):
    """Configure car-people entries to the config datastore one by one using rpc

    Args:
        :param odl_ip: ip address of ODL; default="127.0.0.1"

        :param port: restconf port; default="8181"

        :param thread_count: number of threads used to send http requests; default=1

        :param item_count: number of items to be condigured

        :param auth: authentication credentials

        :param items_per_request: items per request, not used here,
                                  just to keep the same api

    Returns:
        None
    """

    logger.info("Add %s purchase(s) to %s:%s (%s per request)",
                item_count, odl_ip, port, items_per_request)
    if items_per_request != 1:
        logger.error("Only 1 item per request is supported, " +
                     "you specified: {0}".format(item_count))
        raise NotImplementedError("Only 1 item per request is supported, " +
                                  "you specified: {0}".format(item_count))

    res = _task_executor(_prepare_add_car_people_rpc, odl_ip=odl_ip, port=port,
                         thread_count=thread_count, item_count=item_count,
                         items_per_request=items_per_request, auth=auth)
    if res.keys() != [200]:
        logger.error("Not all rpc calls passed: " + repr(res))
        raise Exception("Not all rpc calls passed: " + repr(res))


_actions = ["add", "get", "delete", "add-rpc"]
_items = ["car", "people", "car-people"]

_handler_matrix = {
    "add": {"car": add_car},
    "get": {"car": get_car, "people": get_people, "car-people": get_car_people},
    "delete": {"car": delete_car, "people": delete_people, "car-people": delete_car_people},
    "add-rpc": {"car-people": add_car_people_rpc, "people": add_people_rpc},
}


if __name__ == "__main__":
    """
    This program executes requested action based in given parameters

    It provides "car", "people" and "car-people" crud operations.
    """

    parser = argparse.ArgumentParser(description="Cluster datastore"
                                                 "performance test script")
    parser.add_argument("--host", default="127.0.0.1",
                        help="Host where odl controller is running."
                             "Or comma separated list of hosts."
                             "(default is 127.0.0.1)")
    parser.add_argument("--port", default="8181",
                        help="Port on which odl's RESTCONF is listening"
                             "(default is 8181)")
    parser.add_argument("--threads", type=int, default=1,
                        help="Number of request worker threads to start in"
                             "each cycle (default=1)")
    parser.add_argument("action", choices=_actions, metavar="action",
                        help="Action to be performed.")
    parser.add_argument("--itemtype", choices=_items, default="car",
                        help="Flows-per-Request - number of flows (batch size)"
                             "sent in each HTTP request (default 1)")
    parser.add_argument("--itemcount", type=int, help="Items per request",
                        default=1)
    parser.add_argument("--user", help="Restconf user name", default="admin")
    parser.add_argument("--password", help="Restconf password", default="admin")
    parser.add_argument("--ipr", type=int, help="Items per request", default=1)
    parser.add_argument("--debug", dest="loglevel", action="store_const",
                        const=logging.DEBUG, default=logging.INFO,
                        help="Set log level to debug (default is error)")

    args = parser.parse_args()

    logger = logging.getLogger("logger")
    log_formatter = logging.Formatter('%(asctime)s %(levelname)s: %(message)s')
    console_handler = logging.StreamHandler()
    file_handler = logging.FileHandler('cluster_rest_script.log', mode="w")
    console_handler.setFormatter(log_formatter)
    file_handler.setFormatter(log_formatter)
    logger.addHandler(console_handler)
    logger.addHandler(file_handler)
    logger.setLevel(args.loglevel)

    auth = (args.user, args.password)

    if (args.action not in _handler_matrix or
            args.itemtype not in _handler_matrix[args.action]):
            msg = "Unsupported combination of action: " + str(args.action)
            msg += " and item: " + str(args.itemtype)
            logger.error(msg)
            raise NotImplementedError(msg)

    # TODO: need to filter out situations when we cannot use more items
    # in one rest request (rpc or delete?)
    # this should be done inside handler functions

    handler_function = _handler_matrix[args.action][args.itemtype]
    handler_function(args.host, args.port, args.threads,
                     args.itemcount, auth, args.ipr)
