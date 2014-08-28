__author__ = "Jan Medved"
__copyright__ = "Copyright(c) 2014, Cisco Systems, Inc."
__license__ = "New-style BSD"
__email__ = "jmedved@cisco.com"


import json
import argparse
import requests

CONFIGURL = 'restconf/config/opendaylight-inventory:nodes'
getheaders = {'Accept': 'application/json'}


if __name__ == "__main__":

    parser = argparse.ArgumentParser(description='Cleans up the config space')
    parser.add_argument('--odlhost', default='127.0.0.1', help='host where '
                        'odl controller is running (default is 127.0.0.1)')
    parser.add_argument('--odlport', default='8080', help='port on '
                        'which odl\'s RESTCONF is listening (default is 8080)')

    in_args = parser.parse_args()

    url = 'http://' + in_args.odlhost + ":" + in_args.odlport + '/' + CONFIGURL
    s = requests.Session()
    r = s.delete(url, headers=getheaders)

    if r.status_code != 200:
        print 'Failed to delete nodes in the config space, code %d' % r.status_code
    else:
        print 'Nodes in config space deleted.'
