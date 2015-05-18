#!/usr/bin/python

from mininet.net import Mininet
from mininet.node import OVSKernelSwitch, RemoteController
from mininet.cli import CLI
import multiprocessing
import time
import argparse


d = 11
c = 0
b = 0
a = 1


def get_next_ip():
    global a, b, c, d
    rip = "{0}.{1}.{2}.{3}".format(d, c, b, a)
    a += 1
    if a == 255:
        a = 1
        b += 1
    if b == 255:
        b = 0
        c += 1
    if c == 255:
        c = 0
        d += 1
    return rip

# switchid and hostid
hid = 0
sid = 0


def get_next_hid():
    global hid
    hid += 1
    return hid


def get_next_sid():
    global sid
    sid += 1
    return sid


def get_switch(net, hosts):
    sname = 's{0}'.format(get_next_sid())
    s = net.addSwitch(sname)
    for i in range(hosts):
        hname = 'h{0}'.format(get_next_hid())
        hip = get_next_ip()
        h = net.addHost(hname, ip=hip)
        s.linkTo(h)
        print "switch {0}: host {1}-{2} added".format(sname, hname, hip)
    return s


def get_net(switches, hostpswtich, controllers=['10.25.2.9']):

    net = Mininet(controller=RemoteController, switch=OVSKernelSwitch)

    cs = []
    for i, cip in enumerate(controllers):
        c = net.addController('c{0}'.format(i), controller=RemoteController, ip=cip, port=6633)
        cs.append(c)
        print "contrller {0} created".format(c)

    ss = []
    for i in range(switches):
        s = get_switch(net, hostpswtich)

    net.build()
    for c in cs:
        c.start()

    for s in ss:
        s.start(cs)

    return net


class MininetworkProcess(multiprocessing.Process):
    """Base class.
    Do NOT use this class directly.
    """
    def __init__(self, swithes, hps, controllers=['10.25.2.9']):
        super(MininetworkProcess, self).__init__()
        self._event = multiprocessing.Event()
        self._net = get_net(swithes, hps, controllers=controllers)

    def run(self):
        self._net.start()
        self._net.staticArp()
        while self._event.is_set() is False:
            time.sleep(1)
        self._net.stop()


if __name__ == '__main__':
    # setLogLevel( 'info' )
    parser = argparse.ArgumentParser(description='Starts switches with specified controllers')
    parser.add_argument('--controllers', default='10.25.2.9',
                        help='Comma separated list of cluster members (default ="10.25.2.9,10.25.2.10,10.25.2.11")')
    args = parser.parse_args()

    net = get_net(3, 1, controllers=args.controllers.split(','))

    net.start()
    net.staticArp()
    CLI(net)
    net.stop()
