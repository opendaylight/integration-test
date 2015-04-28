"""Custom LACP topology for LACP Module testing

1.Two hosts(H1,H2) two interface each  connected with Switch(S1)
2.Two hosts(H3,H4) one interface each  connected with Switch(S1)


                   - - - -
                   | H2   |
                   |      |
                   - - - -
                     |  |
                     |  |
                   - - - - -
- - -  eth1        |        |         - - -
| H1 |- - - - - - -| S1     |- - - - -| H3 |
|    |- - - - - - -|        |         |    |
- - -  eth2         - - - - -         - - -
                       |
                     - - -
                    |  H4 |
                     - - -

Execute Custom topology:
sudo mn  --custom LACP_custom1.py --switch ovsk,protocols=OpenFlow13 --topo=lacp

Note:
 1.remoteController IP will be replaced in LACP_custom1.py using sed command during the robot execution
 2.bonding.conf will be copied the mininet server under /etc/modprobe.d
 3.h1-bonding.sh h2-bonding.sh will be executed in respective h1,h2 host console
"""

from mininet.cli import CLI
from mininet.net import Mininet
from mininet.node import RemoteController
from mininet.topo import Topo
from mininet.link import Link


class LacpTopo(Topo):
    net = Mininet(controller=RemoteController)
    c0 = net.addController('c0', controller=RemoteController, ip='CONTROLLER')
    s1 = net.addSwitch('s1')
    h1 = net.addHost('h1', mac='00:00:00:00:00:11')
    h2 = net.addHost('h2', mac='00:00:00:00:00:22')
    h3 = net.addHost('h3', mac='00:00:00:00:00:33', ip='10.1.1.3')
    h4 = net.addHost('h4', mac='00:00:00:00:00:44', ip='10.1.1.4')

    Link(s1, h1)
    Link(s1, h1)
    Link(s1, h2)
    Link(s1, h2)
    Link(s1, h3)
    Link(s1, h4)
    net.build()
    s1.start([c0])
    s1.cmd('sudo ovs-vsctl set bridge s1 protocols=OpenFlow13')
    print h1.cmd('./h1-bond0.sh')
    print h2.cmd('./h2-bond0.sh')
    CLI(net)
    net.stop()

topos = {'lacp': (lambda: LacpTopo())}
