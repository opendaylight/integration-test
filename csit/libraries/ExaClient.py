'''
The purpose of this library is communicate with exabgp using rpcs.
The server part is implemented in test/csit/scripts/bgp_rem_rpc.py.
'''

import xmlrpclib

class ExaClient(object):

    def __init__(self, exa_addr):
        self.proxy = xmlrpclib.ServerProxy("http://{}:8000".format(exa_addr))

    def announce(self, full_exabgp_cmd):
        data = self.proxy.execute(full_exabgp_cmd)
        return

    def _get_counter(self, msg_type):
        cnt = self.proxy.get_counter(msg_type)
        return cnt

    def get_received_open_count(self):
        return self._get_counter('open')

    def get_received_keepalive_count(self):
        return self._get_counter('keepalive')

    def get_received_update_count(self):
        return self._get_counter('update')

    def get_received_route_refresh_count(self):
        return self._get_counter('route_refresh')



