import iotdm

application = iotdm.application
container = iotdm.container
contentInstance = iotdm.contentInstance


def connect_to_iotdm(host, user, pw, p):
    return iotdm.connect(host, base="InCSE1", auth=(user, pw), protocol=p)


def create_resource(connection, parent, restype, a=None):
    restype = int(restype)
    if a is None:
        x = connection.create(parent, restype)
    else:
        x = connection.create(parent, restype, attr=a)
    if x is None:
        raise AssertionError('Cannot create this resource')
    elif hasattr(x, 'status_code'):
        if x.status_code < 200 or x.status_code > 299:
            raise AssertionError(
                'Cannot create this resource [%d] : %s' %
                (x.status_code, x.text))
    return x

# this might not be necessary now that the library functions can take dicts


def create_subscription(connection, parent, ip, port):
    uri = "http://%s:%d" % (ip, int(port))
    x = connection.create(parent, "subscription", {
        "notificationURI": uri,
        "notificationContentType": "wholeResource"})
    if x is None:
        raise AssertionError('Cannot create this subscription')
    elif hasattr(x, 'status_code'):
        if x.status_code < 200 or x.status_code > 299:
            raise AssertionError('Cannot create subscription [%d] : %s' %
                                 (x.status_code, x.text))
    return x


def retrieve_resource(connection, resid):
    x = connection.retrieve(resid)
    if x is None:
        raise AssertionError('Cannot retrieve this resource')
    elif hasattr(x, 'status_code'):
        if x.status_code < 200 or x.status_code > 299:
            raise AssertionError('Cannot retrieve this resource [%d] : %s' %
                                 (x.status_code, x.text))
    return x


def update_resource(connection, resid, attr):
    x = connection.update(resid, attr)
    if x is None:
        raise AssertionError('Cannot update this resource')
    elif hasattr(x, 'status_code'):
        if x.status_code < 200 or x.status_code > 299:
            raise AssertionError('Cannot update this resource [%d] : %s' %
                                 (x.status_code, x.text))
    return x


def delete_resource(connection, resid):
    x = connection.delete(resid)
    if x is None:
        raise AssertionError('Cannot delete this resource')
    elif hasattr(x, 'status_code'):
        if x.status_code < 200 or x.status_code > 299:
            raise AssertionError('Cannot delete this resource [%d] : %s' %
                                 (x.status_code, x.text))
    return x


def text(x):
    return x.text


def status_code(x):
    return x.status_code


def json(x):
    return x.json()


def elapsed(x):
    return x.elapsed.total_seconds()
