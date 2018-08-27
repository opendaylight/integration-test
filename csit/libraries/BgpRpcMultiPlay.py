"""
The purpose of this library is communicate with tools which run xmlrpc server.
At the moment it is going to be the with the exarpc.py (used with exabgp) and
with play.py for bgp functional testing.
exa_ methods apply to test/tools/exabgp_files/exarpc.py
play_ methods apply to test/tool/fastbgp/play.py  (only with --evpn used)
"""

import xmlrpclib

def initialize(peer_addr):
    """Setup destination point of the rpc server"""
    proxy = xmlrpclib.ServerProxy("http://{}:8000".format(peer_addr))
    return proxy

def play_send(proxy, hexstring):
    """Sends given hex data, already encoded bgp update message is expected."""
    return proxy.send(hexstring.rstrip())

def play_get(proxy, what='update'):
    """Gets the last received (update) mesage as hex string."""
    return proxy.get(what)

def play_clean(proxy, what='update'):
    """Cleans the message (update) on the server."""
    return proxy.clean(what)
