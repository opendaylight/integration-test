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
from subprocess import call


class DynamicMininet(cmd.Cmd):
    """Cli wrapper over Mininet network instance tool.

    - when starting this CLI the 'mininet> ' cli appears, but no switches are active
    - topology is very simple, just as many single switches without any hosts nor links

    How to use it:
    - one possible scenario is for measuring max connected switches
       1) start cli
       2) start mininet using command 'start <controller> <num>'
       3) add another switches using 'add_switch' or 'add_switches <num>'
       4) stop mininet usinf 'exit'
    - another scenario is connect one single switch to multiple controllers or clustered controller
      for feature testing
       1) start cli
       2) start mininet with specified controllers using command 'start_with_cluster <cntl>[,<cntl>[...]]>'
       3) stop mininet using 'exit'
    Note: Do not mix scanarios
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
            self._topo.addSwitch('s{0}'.format(self._lid))
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

    def do_start_with_cluster(self, line):
        """Starts mininet network with initial number of switches

        Args:
            :param controller_ips: list of controller ip addresses or host names
                                   e.g.  1.1.1.1,2.2.2.2,3.3.3.3 (no spaces)
        """
        if self._running:
            print 'Mininet topology is already active'
            return
        cntls = line.split(',')

        self._topo = mininet.topo.SingleSwitchTopo()
        switch = mininet.util.customConstructor({'ovsk': OVSKernelSwitch}, 'ovsk,protocols=OpenFlow13')
        self._net = mininet.net.Mininet(switch=switch)

        controllers = []
        for i, cntl_ip in enumerate(cntls):
            cnt = self._net.addController('c{0}'.format(i), controller=RemoteController, ip=cntl_ip, port=6633)
            controllers.append(cnt)
            print "contrller {0} created".format(cnt)

        self._net.buildFromTopo(topo=self._topo)
        self._net.start()
        self._running = True

    def help_start_with_cluster(self):
        """Provide help message for start_with_cluster command"""
        print 'Starts mininet with one switch'
        print 'Usage: start <controller_ips>'
        print '\tcontroller_ips - comma separated list of controllers ip or host names'

    def do_start_switches_with_cluster(self, line):
        """Starts mininet network with initial number of switches

        Args:
            :param swnr: number of switchers in topology
            :param controller_ips: list of controller ip addresses or host names
                                   e.g.  1.1.1.1,2.2.2.2,3.3.3.3 (no spaces)
        """
        if self._running:
            print 'Mininet topology is already active'
            return
        num, contls = line.split()
        cntls = contls.split(',')

        self._topo = mininet.topo.LinearTopo(int(num))
        switch = mininet.util.customConstructor({'ovsk': OVSKernelSwitch}, 'ovsk,protocols=OpenFlow13')
        self._net = mininet.net.Mininet(switch=switch)

        controllers = []
        for i, cntl_ip in enumerate(cntls):
            cnt = self._net.addController('c{0}'.format(i), controller=RemoteController, ip=cntl_ip, port=6633)
            controllers.append(cnt)
            print "contrller {0} created".format(cnt)

        self._net.buildFromTopo(topo=self._topo)
        self._net.start()
        self._running = True

    def help_start_switches_with_cluster(self):
        """Provide help message for start_with_cluster command"""
        print 'Starts mininet with one switch'
        print 'Usage: start <swnr> <controller_ips>'
        print '\tswnt - number of switches in topology'
        print '\tcontroller_ips - comma separated list of controllers ip or host names'

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

    def help_exit(self):
        """Provide help message for exit command"""
        print 'Exit mininet cli'
        print 'Usage: exit'

    def do_sh(self, line):
        """Run an external shell command
        Args:
            :param line: text/command to be executed
        """
        call(line, shell=True)

    def help_sh(self, line):
        """Provide help message for sh command"""
        print 'Executes given commandAdds one sinle switch to the running topology'
        print 'Usage: sh <line>'
        print '\tline - command to be executed(e.g. ps -e'

    def emptyline(self):
        pass


if __name__ == '__main__':
    dynamic_mininet_cli = DynamicMininet()
    dynamic_mininet_cli.cmdloop()
