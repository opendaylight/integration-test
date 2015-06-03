"""This library should work with ciotdm, both work for iotdm project."""
import ciotdm


def connect_to_iotdm(host, user, password, prot):
    """According to protocol, connect to iotdm."""
    return ciotdm.connect(host, base="InCSE1", auth=(
        user, password), protocol=prot)


def create_resource(connection, parent, restype, attribute=None, name=None):
    """Create resource without command."""
    restype = int(restype)
    response = connection.create(parent, restype, attribute, name=name)
    Check_Response(response, "create")
    return response


def create_resource_with_command(connection, parent, restype,
                                 command, attribute=None, name=None):
    """According to command in the header, create the resource."""
    restype = int(restype)
    response = connection.createWithCommand(parent, restype,
                                            command, attribute, name=name)
    Check_Response(response, "create")
    return response


def create_subscription(connection, parent, ip, port):
    """Create subscription."""
    uri = "http://%s:%d" % (ip, int(port))
    response = connection.create(parent, "subscription", {
        "notificationURI": uri,
        "notificationContentType": "wholeResource"})
    Check_Response(response, "create")
    return response


def retrieve_resource(connection, resid):
    """Retrieve resource according to resourceID."""
    response = connection.retrieve(resid)
    Check_Response(response, "retrieve")
    return response


def retrieve_resource_with_command(connection, resid, command):
    """According to command, retrieve source with the resourceID."""
    response = connection.retrieveWithCommand(resid, command)
    Check_Response(response, "retrieve")
    return response


def update_resource(connection, resid, restype, attr, nm=None):
    """According to resourceID, update resource."""
    response = connection.update(resid, restype, attr, nm)
    Check_Response(response, "update")
    return response


def update_resource_with_command(connection, resid,
                                 restype, command, attr, nm=None):
    """According to command, update resource with resourceID."""
    response = connection.updateWithCommand(resid, restype, command, attr, nm)
    Check_Response(response, "update")
    return response


def delete_resource(connection, resid):
    """According to resourceID, delete the resource."""
    response = connection.delete(resid)
    Check_Response(response, "delete")
    return response


def delete_resource_with_command(connection, resid, command):
    """According to command, delete the resource with resourceID."""
    response = connection.deleteWithCommand(resid, command)
    Check_Response(response, "delete")
    return response


def resid(response):
    """Return resource ID."""
    return ciotdm.resid(response)


def name(response):
    """Return resourceName."""
    resourceName = ciotdm.name(response)
    if resourceName is None:
        raise AssertionError('Cannot find this resource')
    return resourceName


def text(response):
    """Return whole resource in text."""
    return response.text


def lastModifiedTime(response):
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


def kill_the_tree(host, CSEID, username, password):
    """Delete the whole tree."""
    connection = ciotdm.connect(host, base=CSEID,
                                auth=(username, password), protocol="http")
    connection.kill()


def Check_Response(response, operation):
    """Check whether the connection is none."""
    if response is None:
        raise AssertionError('Cannot %s this resource') % (operation)
    elif hasattr(response, 'status_code'):
        if response.status_code < 200 or response.status_code > 299:
            raise AssertionError(
                'Cannot %s this resource [%d] : %s' %
                (operation, response.status_code, response.text))
