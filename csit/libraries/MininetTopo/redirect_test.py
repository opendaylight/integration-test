#!/usr/bin/python

from mininet.topo import Topo


class MyTopo2(Topo):
    "Simple topology example."

    def __init__(self):
        "Create custom topo."

        # Initialize topology
        Topo.__init__(self)

        # Add hosts and switches
        Switch1 = self.addSwitch('s1')
        Switch2 = self.addSwitch('s2')
        Switch3 = self.addSwitch('s3')
        Switch4 = self.addSwitch('s4')
        Host11 = self.addHost('h1')
        Host12 = self.addHost('h2')
        Host21 = self.addHost('h3')
        Host22 = self.addHost('h4')
        Host23 = self.addHost('h5')
        Service1 = self.addHost('srvc1')

        # Add links
        self.addLink(Host11, Switch1)
        self.addLink(Host12, Switch1)
        self.addLink(Host21, Switch2)
        self.addLink(Host22, Switch2)
        self.addLink(Host23, Switch2)
        self.addLink(Switch1, Switch2)
        self.addLink(Switch2, Switch4)
        self.addLink(Switch4, Switch3)
        self.addLink(Switch3, Switch1)
        self.addLink(Switch3, Service1)
        self.addLink(Switch4, Service1)


topos = {'mytopo2': (lambda: MyTopo2())}
