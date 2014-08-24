#!/usr/bin/python

# usage: sudo mn --controller=remote,ip=<controller_ip> --switch=ovsk,protocols=OpenFlow13 --custom <path to createtopo.py> --topo loop ...

from mininet.topo import Topo
from mininet.net import Mininet
from mininet.node import RemoteController
from mininet.cli import CLI

class LoopTopo(Topo):
        def __init__(self, switches = 3, hosts_per = 1, **opts):
            Topo.__init__(self, **opts)
            sws = []
            hnum = 0
            for i in range(switches):
                sw = self.addSwitch('s%s' % (i+ 1))

                for _ in range(hosts_per):
                    hnum += 1
                    host = self.addHost('h%s' % hnum)
                    self.addLink(sw, host)

                for rhs in sws:
                    self.addLink(sw, rhs)

                sws.append(sw)

topos = { 'loop': LoopTopo }
