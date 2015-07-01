"""
Custom Topology to test extended Vxlan Tunnel Functionality created via OVSDB SouthBound plugin.
usage: mn --controller=remote,ip=<> --switch=ovsk,protocols=OpenFlow13 --custom <> --topo host1

"""

from mininet.topo import Topo


def add_hosts(self, switch, hosts, start_host_suffix):
    """Add and connect specified number of hosts to the the switch

    Args:
        :param switch: A string that describes the switch name to which the hosts are to be connected
            example 's1 s2 s3 ...'

        :param hosts: A integer that describes the number of hosts to be added to the switch

        :param start_host_suffix: A integer that describes the starting suffix of the host from which

    Returns:
        :returns Nothing
    """
    host_suffix = start_host_suffix
    for _ in range(hosts):
        host = self.addHost("h%s" % host_suffix, ip="10.0.0.%s" % host_suffix)
        self.addLink(switch, host)
        host_suffix += 1


class HostTopo(Topo):
    """Class to create a switch and host with suffix

    Args:
        :param host_suffix: specified else default is 1. For example: if equals to 3 (s3,h3)
        :param hosts_per_switch: Number of hosts be connected to the switch. Default is 1.
    """
    def __init__(self, host_suffix=1, hosts_per_switch=1, **opts):
        Topo.__init__(self, **opts)
        switch = self.addSwitch('s%s' % host_suffix)
        add_hosts(self, switch, hosts_per_switch, host_suffix)


topos = {'host': HostTopo}
