#!/usr/bin/python
__author__ = "Jan Medved"
__copyright__ = "Copyright(c) 2014, Cisco Systems, Inc."
__license__ = "New-style BSD"
__email__ = "jmedved@cisco.com"

import argparse
import requests
import sys

getheaders = {'Accept': 'application/json'}


def cleanup_config_fl(host, port):
    global getheaders

    url = 'http://' + host + ":" + port + '/wm/staticflowentrypusher/clear/all/json'
    r = requests.get(url, headers=getheaders)
    return r.status_code


def cleanup_config_odl(host, port, auth):
    global getheaders

    url = 'http://' + host + ":" + port + '/restconf/config/opendaylight-inventory:nodes'

    if not auth:
        r = requests.delete(url, headers=getheaders)
    else:
        r = requests.delete(url, headers=getheaders, auth=('admin', 'admin'))

    return r.status_code


if __name__ == "__main__":

    parser = argparse.ArgumentParser(description='Cleans up the config space')
    parser.add_argument('--host', default='127.0.0.1', help='host where '
                        'odl controller is running (default is 127.0.0.1)')
    parser.add_argument('--port', default='8181', help='port on '
                        'which odl\'s RESTCONF is listening (default is 8181)')
    parser.add_argument('--auth', dest='auth', action='store_true', default=False,
                        help="Use authenticated access to REST "
                        "(username: 'admin', password: 'admin').")
    parser.add_argument('--controller', choices=['odl', 'floodlight'], default='odl',
                        help='Controller type (ODL or Floodlight); default odl (OpenDaylight)')

    in_args = parser.parse_args()

    if in_args.controller == 'odl':
        sts = cleanup_config_odl(in_args.host, in_args.port, in_args.auth)
        exp = 200
    elif in_args.controller == 'floodlight':
        sts = cleanup_config_fl(in_args.host, in_args.port)
        exp = 204
    else:
        print 'Unknown controller type'
        sys.exit(-1)

    if sts != exp:
        print 'Failed to delete nodes in the config space, code %d' % sts
    else:
        print 'Nodes in config space deleted.'
