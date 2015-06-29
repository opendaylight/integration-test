"""Topology description for configuring vpnservice for hosts on 2 switches

     MININET                  MININET1
   -------------    gre     -------------
   | h1-----s1 |------------| s2------h3|
   |        |  |            | |         |
   |        |  |            | |         |
   |        h2 |            | h4        |
   -------------            -------------
1)The topology consits of switch s1 in one VM connected to hosts h1,h2.Switch s2 in another VM connected to hosts h3,h4.
2)GRE tunnel is configured between s1 and s2 using ovs-vsctl commands.
3)h1 and h3 will be configured for vpn instance testVpn1 and h2,h4 for testVpn2.
"""

from mininet.topo import Topo


class Switch1(Topo):
    """Single switch s1 connected to n=2 hosts."""
    def __init__(self):
        Topo.__init__(self)
        switch = self.addSwitch('s1')
        n = 2
        for h in range(n):
            host = self.addHost('h%s' % (h + 1), mac="00:00:00:00:00:0"+str(h+1), ip="10.0.0."+str(h+1))
            self.addLink(host, switch)


class Switch2(Topo):
    """Single switch s2 connected to n=2 hosts."""
    def __init__(self):
        Topo.__init__(self)
        switch = self.addSwitch('s2')
        n = 2
        for h in range(n):
            host = self.addHost('h%s' % (h + 3), mac="00:00:00:00:00:0"+str(h+3), ip="10.0.0."+str(h+3))
            self.addLink(host, switch)

topos = {'Switch1': (lambda: Switch1()),
         'Switch2': (lambda: Switch2())}
