#!/usr/bin/python
__author__ = "Jan Medved"
__copyright__ = "Copyright(c) 2014, Cisco Systems, Inc."
__license__ = "New-style BSD"
__email__ = "jmedved@cisco.com"

import argparse
import requests


def cleanup_config(host, port, auth):
    CONFIGURL = 'restconf/config/opendaylight-inventory:nodes'
    getheaders = {'Accept': 'application/json'}

    url = 'http://' + host + ":" + port + '/' + CONFIGURL
    s = requests.Session()

    if not auth:
        r = s.delete(url, headers=getheaders)
    else:
        r = s.delete(url, headers=getheaders, auth=('admin', 'admin'))

    s.close()

    if r.status_code != 200:
        print 'Failed to delete nodes in the config space, code %d' % r.status_code
    else:
        print 'Nodes in config space deleted.'


if __name__ == "__main__":

    parser = argparse.ArgumentParser(description='Cleans up the config space')
    parser.add_argument('--host', default='127.0.0.1', help='host where '
                        'odl controller is running (default is 127.0.0.1)')
    parser.add_argument('--port', default='8181', help='port on '
                        'which odl\'s RESTCONF is listening (default is 8181)')
    parser.add_argument('--auth', dest='auth', action='store_true', default=False,
                        help="Use authenticated access to REST "
                        "(username: 'admin', password: 'admin').")

    in_args = parser.parse_args()
    cleanup_config(in_args.host, in_args.port, in_args.auth)
