"""This library should work with ciotdm, both work for iotdm project."""
import ciotdm


def connect_to_iotdm(host, user, password, prot):
    """According to protocol, connect to iotdm."""
    return ciotdm.connect(host, base="InCSE1", auth=(
        user, password), protocol=prot)


def modify_headers_origin(connection, new_origin):
    """Replace the headers origin with the neworigin to test ACP."""
    connection.modify_headers_origin(new_origin)


def create_resource(connection, parent, restype, attribute=None):
    """Create resource without command."""
    connection.create(parent, restype, attribute)
    check_response(connection.response, "create")
    return connection.response


def create_resource_with_command(connection, parent, restype,
                                 command, attribute=None):
    """According to command in the header, create the resource."""
    connection.create_with_command(parent, restype,
                                   command, attribute)
    check_response(connection.response, "create")
    return connection.response


def create_subscription(connection, parent, ip, port):
    """Create subscription."""
    uri = "http://%s:%d" % (ip, int(port))
    connection.create(parent, "subscription", {
        "notificationURI": uri,
        "notificationContentType": "wholeResource"})
    check_response(connection.response, "create")
    return connection.response


def retrieve_resource(connection, resid):
    """Retrieve resource according to resourceID."""
    connection.retrieve(resid)
    check_response(connection.response, "retrieve")
    return connection.response


def retrieve_resource_with_command(connection, resid, command):
    """According to command, retrieve source with the resourceID."""
    connection.retrieve_with_command(resid, command)
    check_response(connection.response, "retrieve")
    return connection.response


def update_resource(connection, resid, restype, attr):
    """According to resourceID, update resource."""
    connection.update(resid, restype, attr)
    check_response(connection.response, "update")
    return connection.response


def update_resource_with_command(connection, resid,
                                 restype, command, attr):
    """According to command, update resource with resourceID."""
    connection.update_with_command(resid, restype, command, attr)
    check_response(connection.response, "update")
    return connection.response


def delete_resource(connection, resid):
    """According to resourceID, delete the resource."""
    connection.delete(resid)
    check_response(connection.response, "delete")
    return connection.response


def delete_resource_with_command(connection, resid, command):
    """According to command, delete the resource with resourceID."""
    connection.delete_with_command(resid, command)
    check_response(connection.response, "delete")
    return connection.response


def resid(response):
    """Return resource ID."""
    return ciotdm.resid(response)


def name(response):
    """Return resourceName."""
    resource_name = ciotdm.name(response)
    if resource_name is None:
        raise AssertionError('Cannot find this resource')
    return resource_name


def text(response):
    """Return whole resource in text."""
    return response.text


def last_modified_time(response):
    """Return resource lastModifiedTime."""
    return ciotdm.lastModifiedTime(response)


def status_code(response):
    """Return resource status_code."""
    return response.status_code


def json(response):
    """Return resource in json format."""
    return response.json()


def elapsed(response):
    """Return resource elapsed."""
    return response.elapsed.total_seconds()


def location(response):
    """Return response content-location."""
    return response.headers['Content-Location']


def kill_the_tree(host, cseid, username, password):
    """Delete the whole tree."""
    connection = ciotdm.connect(host, base=cseid,
                                auth=(username, password), protocol="http")
    connection.kill()


def check_response(response, operation):
    """Check whether the connection is none."""
    if response is None:
        raise AssertionError('Cannot %s this resource') % (operation)
    elif hasattr(response, 'status_code'):
        if response.status_code < 200 or response.status_code > 299:
            raise AssertionError(
                'Cannot %s this resource [%d] : %s' %
                (operation, response.status_code, response.text))
