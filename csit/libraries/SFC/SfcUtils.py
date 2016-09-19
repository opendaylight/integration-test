import ipaddr

__author__ = "Jose Luis Franco Arza"
__copyright__ = "Copyright(c) 2016, Ericsson."
__license__ = "New-style BSD"
__email__ = "jose.luis.franco.arza@ericsson.com"


def get_network_from_cidr(cidr):
    '''
    Returns the subnetwork part from a given subnet in CIDR format,
    like 192.168.1.0/24. Returning 192.168.1.0.
    '''
    o = ipaddr.IPv4Network(cidr)
    return str(o.network)


def get_mask_from_cidr(cidr):
    '''
    Returns a subnet mask from a given subnet in CIDR format,
    like 192.168.1.0/24. Returning 255.255.255.0.
    '''
    o = ipaddr.IPv4Network(cidr)
    return str(o.netmask)


def get_ip_address_first_octets(ip, n_octets):
    '''
    Given an IP address, this function returns the number
    of octets determined as argument. If 4 are specified, then the output
    is the whole IP
    '''

    return ".".join(ip.split(".")[:int(n_octets)])
