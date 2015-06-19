"""
New CLI for mininet which should dynamically add and delete switches from network"
"""

import cmd
# import json
# import logging

import mininet.node
import mininet.topo
import mininet.net
import mininet.util
from mininet.node import RemoteController
from mininet.node import OVSKernelSwitch


class DynamicMininet(cmd.Cmd):
    """Cli wrapper over Mininet network instance tool.

    - when starting this CLI the 'mininet> ' cli appears, but no switches are active
    - topology is very simple, just as many single switches without any hosts nor links
    - how to use it:
       1) start cli
       2) start mininet using command 'start <controller> <num>'
       3) add another switches using 'add_switch' or 'add_switches <num>'
       4) stop mininet usinf 'exit'
    """

    prompt = 'mininet> '

    def __init__(self):
        cmd.Cmd.__init__(self)
        self._running = False
        self._net = None
        self._topo = None
        # last used switch id
        self._lid = 0

    def do_start(self, line):
        """Starts mininet network with initial number of switches

        Args:
            :param controller_ip: controller's ip address or host name
            :param num: initial number of switches in the topology
        """
        if self._running:
            print 'Mininet topology is already active'
            return
        cntl, numsw = line.split()
        self._topo = mininet.topo.Topo()
        for _ in range(int(numsw)):
            self._lid += 1
            self._topo.addSwitch('s{}'.format(self._lid))
        controller = mininet.util.customConstructor({'remote': RemoteController}, 'remote,ip={0}'.format(cntl))
        switch = mininet.util.customConstructor({'ovsk': OVSKernelSwitch}, 'ovsk,protocols=OpenFlow13')
        self._net = mininet.net.Mininet(topo=self._topo, switch=switch, controller=controller)
        self._net.start()
        self._running = True

    def help_start(self):
        """Provide help message for start command"""
        print 'Starts mininet'
        print 'Usage: start <controller_ip> <num>'
        print '\tcontroller_ip - controllers ip or host name'
        print '\tnum           - number of switches at start'

    def do_add_switch(self, line):
        """Adds one switch to the network
        Args:
            no args (any given agrs are ignored)
        """
        if not self._running:
            raise RuntimeError('Network not running, use command "start" first')
        self._lid += 1
        sname = 's{0}'.format(self._lid)
        self._topo.addSwitch(sname)
        self._net.addSwitch(sname, **self._topo.nodeInfo(sname))
        s = self._net.get(sname)
        c = self._net.get('c0')
        s.start([c])

    def help_add_switch(self):
        """Provide help message for add_switch command"""
        print 'Adds one sinle switch to the running topology'
        print 'Usage: add_switch'

    def do_add_switches(self, line):
        """Adds switches to the network
        Args:
            :param  num: number of switches to be added to the running topology
        """
        for i in range(int(line)):
            self.do_add_switch("")

    def help_add_switches(self):
        """Provide help message for add_switch command"""
        print 'Adds one sinle switch to the running topology'
        print 'Usage: add_switches <num>'
        print '\tnum - number of switches tp be added'

    def do_exit(self, line):
        """Stops mininet"""
        if self._running:
            self._net.stop()
            self._running = False
        return True

    def help_exit(self, line):
        """Provide help message for exit command"""
        print 'Exit mininet cli'
        print 'Usage: exit'

    def emptyline(self):
        pass


if __name__ == '__main__':
    dynamic_mininet_cli = DynamicMininet()
    dynamic_mininet_cli.cmdloop()
