"""Custom topology example

Three directly connected switches plus a host for each switch:

   host --- switch --- switch --- switch --- host

Adding the 'topos' dict with a key/value pair to generate our newly defined
topology enables one to pass in '--topo=mytopo' from the command line.
"""

from mininet.topo import Topo


class PathpolicyTopo(Topo):
    """Simple topology example."""

    def __init__(self):

        # Initialize topology
        Topo.__init__(self)

        # Add hosts and switches
        leftHost = self.addHost('h1')
        rightHost = self.addHost('h2')
        leftSwitch = self.addSwitch('s1')
        middleSwitch = self.addSwitch('s2')
        middleSwitch2 = self.addSwitch('s4')
        rightSwitch = self.addSwitch('s3')

        # Add links
        self.addLink(leftHost, leftSwitch)
        self.addLink(leftSwitch, middleSwitch)
        self.addLink(leftSwitch, middleSwitch2)
        self.addLink(middleSwitch, rightSwitch)
        self.addLink(middleSwitch2, rightSwitch)
        self.addLink(rightSwitch, rightHost)


topos = {'pathpolicytopo': (lambda: PathpolicyTopo())}
