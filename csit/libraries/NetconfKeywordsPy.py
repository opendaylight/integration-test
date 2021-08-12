"""
   Utility library for configuring NETCONF topology node to connect to network elements.
"""

from logging import debug, info
from requests import get, patch
from time import sleep
from uuid import uuid4

def configure_device_range(
    restconf_url,
    device_name_prefix,
    device_ipaddress,
    device_port,
    device_count,
    first_device_id=0,
):
    """Generate device_count names in format "$device_name_prefix-$i" and configure them into NETCONF topology at specified RESTCONF URL.
    For example:

       configure_device_range("http://127.0.0.1:8181/rests", "example", "127.0.0.1", 1730, 5)

    would configure devices "example-0" through "example-4" to connect to 127.0.0.0:1730.

       configure_device_range("http://127.0.0.1:8181/rests", "example", "127.0.0.1", 1720, 5, 5)

    would configure devices "example-5" through "example-9" to connect to 127.0.0.0:1720.

    This method assumes RFC8040 with RFC7952 encoding and support for RFC8072 (YANG patch). Payload it generates looks roughly like this:
    {
       "ietf-yang-patch:yang-patch" : {
          "patch-id" : "test"
          "edit" : [
             {
                "edit-id" : "test-edit",
                "operation" : "replace",
                "target" : "/node=test-node",
                "value" : {
                   "node" : [
                      {
                         "node-id" : "test-node"
                         "netconf-node-topology:host" : "127.0.0.1",
                         "netconf-node-topology:port" : 17830,
                         "netconf-node-topology:username" : "admin",
                         "netconf-node-topology:password" : "topsecret",
                         "netconf-node-topology:keepalive-delay" : 0,
                      }
                   ]
                }
             }
          ],
       }
    }
    """

    info("Configure %s devices starting from %s (at %s:%s)",
            device_count, first_device_id, device_ipaddress, device_port)

    device_names = []
    edits = []

    for i in range(first_device_id, first_device_id + device_count):
        name = "{}-{}".format(device_name_prefix, i)
        device_names.append(name)
        edits.append("""
            {
              "edit-id" : "node-%s",
              "operation" : "replace",
              "target" : "/node=%s",
              "value" : {
                "node" : [
                  {
                    "node-id" : "%s",
                    "netconf-node-topology:host" : "%s",
                    "netconf-node-topology:port" : %s,
                    "netconf-node-topology:username" : "admin",
                    "netconf-node-topology:password" : "topsecret",
                    "netconf-node-topology:tcp-only" : false,
                    "netconf-node-topology:keepalive-delay" : 0
                  }
                ]
              }
            }
        """ % (name, name, name, device_ipaddress, device_port))

    data = """
    {
      "ietf-yang-patch:yang-patch" : {
        "patch-id" : "csit-%s",
        "edit" : [
    """ % str(uuid4())


    # TODO: I bet there is a fancier way to write this
    it = iter(edits)
    cur = next(it)
    while True:
        data = data + cur
        nxt = next(it, None)
        if nxt == None:
            break
        data += ", "
        cur = nxt

    data += """]
      }
    }"""

    #print(data)

    resp = patch(
        url=restconf_url + """/data/network-topology:network-topology/topology=topology-netconf""",
        headers={
            "Content-Type": "application/yang-patch+json",
            "Accept": "application/yang-data+json",
        },
        data=data,
        # FIXME: do not hard-code credentials here
        auth=("admin", "admin"),
    )

    resp.raise_for_status()
    status = resp.json()
    # FIXME: validate response
    #  {
    #    "ietf-yang-patch:yang-patch-status" : {
    #      "patch-id" : "add-songs-patch-2",
    #      "ok" : [null]
    #    }
    #  }

    #  {
    #    "ietf-yang-patch:yang-patch-status" : {
    #      "patch-id" : "add-songs-patch",
    #      "edit-status" : {
    #        "edit" : [
    #          {
    #            "edit-id" : "edit1",
    #            "errors" : {
    #              "error" : [
    #                {
    #                  "error-type": "application",
    #                  "error-tag": "data-exists",
    #                  "error-path": "/example-jukebox:jukebox/library\
    #                     /artist[name='Foo Fighters']\
    #                     /album[name='Wasting Light']\
    #                     /song[name='Bridge Burning']",
    #                  "error-message":
    #                    "Data already exists; cannot be created"
    #                }
    #              ]
    #            }
    #          }
    #        ]
    #      }
    #    }
    #  }

    return device_names


def await_devices_connected(restconf_url, device_names, deadline):
    info("Awaiting connection of %s", device_names)

    connected = set()

    while True:
        resp = get(
            url=restconf_url
            + """/network-topology:topology[name="netconf"]/nodes/...""",
            headers={"Accept": "application/yang-data+json"},
            # FIXME: do not hard-code credentials here
            auth=("admin", "admin"),
        )

        # FIXME: also check for 409 might be okay?
        resp.raise_for_status()

        for node in resp.json():
            # FIXME: traverse JSON tree, noticing any up -> down transitions (and fail on them)
            pass

        if connected.size() != device_names.size():
            break

        # FIXME: actually notice the deadline
        sleep(1)

#def main():
#    configure_device_range(
#            "http://127.0.0.1:8181/rests",
#            "scale-device",
#            "127.0.0.1",
#            17830,
#            10)
#
#if __name__ == "__main__":
#    main()
#
