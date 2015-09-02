"""
Library for the robot based system test tool of the OpenDaylight project.
Authors: Baohua Yang@IBM, Denghui Huang@IBM
Updated: 2013-11-18
"""
from mininet.net import Mininet

class MininetHandler(object):
    '''
    MininetHandler class will provide all operations about Mininet, such as config controller_ip, start or stop net.
    '''
    def __init__(self,controller_ip='127.0.0.1'):
        self.controller_ip = controller_ip
        self.net=None

    def set_controller_ip(self,controller_ip):
        self.controller_ip = controller_ip

    def config_net(self):
        net = Mininet(switch=OVSKernelSwitch,controller=RemoteController)

        print '*** Adding controller'
        net.addController('c0',ip=self.controller_ip)

        print '*** Adding hosts'
        h1 = net.addHost( 'h1', mac='00:00:00:00:00:01')
        h2 = net.addHost( 'h2', mac='00:00:00:00:00:02')
        h3 = net.addHost( 'h3', mac='00:00:00:00:00:03')
        h4 = net.addHost( 'h4', mac='00:00:00:00:00:04')

        print '*** Adding switch'
        s1 = net.addSwitch( 's1' )
        s2 = net.addSwitch( 's2' )
        s3 = net.addSwitch( 's3' )

        print '*** Creating links'
        net.addLink(h1,s2)
        net.addLink(h2,s2)
        net.addLink(h3,s3)
        net.addLink(h4,s3)
        net.addLink(s1,s2)
        net.addLink(s1,s3)

        self.net = net

    def start_net(self):
        self.net.start()

    def stop_net(self):
        self.net.stop()
