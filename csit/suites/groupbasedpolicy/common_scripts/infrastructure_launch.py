#!/usr/bin/python

"""
Spin-up script for Opendaylight GBP and GBPSFC sample concept demonstrations.

This script has to be run from the environment on which OVS switches and Docker
containers are located. This script works together with infrastructure_config.py
configuration script where the entire topology for specific scenario is configured. This
file defines to which already existing switch docker containers have to be connected.
OVS switch have to be created on the same hosting environment as this script is executed
from. Local switch name should match one of the names specified in configuration file so that
docker containers are created and connected to it.

Updated: 22.10.2015

"""

import socket
import os
import sys
import ipaddr
from subprocess import call
from subprocess import check_output
from infrastructure_config import switches
from infrastructure_config import hosts
from infrastructure_config import defaultContainerImage


def add_controller(sw, ip):
    """Connects OVS switch to a controller. The switch is specified
        by it's name and the controller by it's IP address.

    Args:
        :param sw: name of a switch on which controller is set

        :param ip: IP address of controller

    NOTE:
        :Required controller should listen on TCP port 6653.
    """

    try:
        socket.inet_aton(ip)
    except socket.error:
        print "Error: %s is not a valid IPv4 address of controller!" % ip
        os.exit(2)

    call(['sudo', 'ovs-vsctl', 'set-controller', sw, 'tcp:%s:6653' % ip])


def add_manager(ip):
    """Sets OVSDB manager for OVS instance.

    Args:
        :param ip: IP address of specified manager

    NOTE:
        :Required manager should listen on TCP port 6640.
    """

    try:
        socket.inet_aton(ip)
    except socket.error:
        print "Error: %s is not a valid IPv4 address of manager!" % ip
        os.exit(2)

    cmd = ['sudo', 'ovs-vsctl', 'set-manager', 'tcp:%s:6640' % ip]
    call(cmd)


def add_switch(name, dpid=None):
    """Adds switch to OVS instance and sets it's DataPath ID
        if specified.

    Args:
        :param ip: name of new switch

        :param dpid: DataPath ID of new switch
    """

    call(['sudo', 'ovs-vsctl', 'add-br', name])  # Add bridge
    if dpid:
        if len(dpid) < 16:  # DPID must be 16-bytes in later versions of OVS
            filler = '0000000000000000'
            # prepending zeros to match 16-byt length, e.g. 123 -> 0000000000000123
            dpid = filler[:len(filler) - len(dpid)] + dpid
        elif len(dpid) > 16:
            print 'DPID: %s is too long' % dpid
            sys.exit(3)
        call(['sudo', 'ovs-vsctl', 'set', 'bridge', name,
              'other-config:datapath-id=%s' % dpid])


def set_of_version(sw, version='OpenFlow13,OpenFlow12,OpenFlow10'):
    """Sets OpenFlow protocol versions on OVS switch

    Args:
        :param sw: name of switch

        :param sw: OpenFlow versions to support on switch
    """

    call(['sudo', 'ovs-vsctl', 'set', 'bridge', sw, 'protocols={}'.format(version)])


def add_vxlan_tunnel(sw):
    """Adds VXLAN tunnel to OVS switch.

    Args:
        :param sw: name of switch

    NOTE:
        :Remote IP is read from flows.
    """
    ifaceName = '{}-vxlan-0'.format(sw)
    cmd = ['sudo', 'ovs-vsctl', 'add-port', sw, ifaceName,
           '--', 'set', 'Interface', ifaceName,
           'type=vxlan',
           'options:remote_ip=flow',
           'options:key=flow']
    call(cmd)


def add_gpe_tunnel(sw):
    """Adds GPE tunnel to OVS switch.

    Args:
        :param sw: name of switch

        :param dpid: DataPath ID of new switches

    NOTE:
        :Remote IP is read from flows.
    """

    ifaceName = '{}-vxlangpe-0'.format(sw)
    cmd = ['sudo', 'ovs-vsctl', 'add-port', sw, ifaceName,
           '--', 'set', 'Interface', ifaceName,
           'type=vxlan',
           'options:remote_ip=flow',
           'options:dst_port=6633',
           'options:nshc1=flow',
           'options:nshc2=flow',
           'options:nshc3=flow',
           'options:nshc4=flow',
           'options:nsp=flow',
           'options:nsi=flow',
           'options:key=flow']
    call(cmd)


def launch_container(host, containerImage):
    # TODO use Docker.py
    """Runs docker container in background.

    Args:
        :param host: container host name

        :param dpid: DataPath ID of new switch

    Returns:
        :returns string: container ID

    NOTE:
        :No networking set.

    """

    containerID = check_output(['docker',
                                'run',
                                '-d',
                                '--net=none',
                                '--name=%s' % host['name'],
                                '-h',
                                host['name'],
                                '-t',
                                '-i',
                                '--privileged=True',
                                containerImage,
                                '/bin/bash'])
    return containerID[:-1]  # Remove extraneous \n from output of above


def connect_container_to_switch(sw, host, containerID):
    """Connects docker to OVS switch.

    Args:
        :param sw: name of switch

        :param host: host object to process.
            Here is an example of such as object
            {'name': 'h35_2',
             'mac': '00:00:00:00:35:02',
             'ip': '10.0.35.2/24',
             'switch': 'sw1'}
             Note: 'switch' - name of OVS switch to
                 which the host will be connected

        :param containerID: ID of docker container
    """

    hostIP = host['ip']
    mac = host['mac']
    nw = ipaddr.IPv4Network(hostIP)
    broadcast = "{}".format(nw.broadcast)
    router = "{}".format(nw.network + 1)
    ovswork_path = os.path.dirname(os.path.realpath(__file__)) + '/ovswork.sh'
    cmd = [ovswork_path,
           sw,
           containerID,
           hostIP,
           broadcast,
           router,
           mac,
           host['name']]
    if ('vlan') in host:
        cmd.append(host['vlan'])
    call(cmd)


def launch(switches, hosts, odl_ip='127.0.0.1'):
    """Connects hosts to switches. Arguments are
       tied to underlying configuration file. Processing runs
       for switch, that is present on local environment and
       for hosts configured to be connected to the switch.

    Args:
        :param switches: switches to connect to
            Example of switch object
            {'name': 'sw1',
             'dpid': '1'}

        :param hosts: hosts to connect
            Example of host object
            {'name': 'h35_2',
             'mac': '00:00:00:00:35:02',
             'ip': '10.0.35.2/24',
             'switch': 'sw1'}
             Note: 'switch' - name of OVS switch to
                 which the host will be connected

        :param odl_ip: IP address of ODL, acting as
            both - manager and controller.
            Default value is '127.0.0.1'
    """

    for sw in switches:
        add_manager(odl_ip)
        ports = 0
        first_host = True
        for host in hosts:
            if host['switch'] == sw['name']:
                if first_host:
                    add_switch(sw['name'], sw['dpid'])
                    set_of_version(sw['name'])
                    add_controller(sw['name'], odl_ip)
                    add_gpe_tunnel(sw['name'])
                    add_vxlan_tunnel(sw['name'])
                first_host = False
                containerImage = defaultContainerImage  # from Config
                if ('container_image') in host:  # from Config
                    containerImage = host['container_image']
                containerID = launch_container(host, containerImage)
                ports += 1
                connect_container_to_switch(
                    sw['name'], host, containerID)
                host['port-name'] = 'vethl-' + host['name']
                print "Created container: %s with IP: %s. Connect using docker attach %s," \
                    "disconnect with 'ctrl-p-q'." % (host['name'], host['ip'], host['name'])

if __name__ == "__main__":
    if len(sys.argv) < 2 or len(sys.argv) > 3:
        print "Please, specify IP of ODL and switch index in arguments."
        print "usage: ./infrastructure_launch.py ODL_IP SWITCH_INDEX"
        sys.exit(2)

    controller = sys.argv[1]
    try:
        socket.inet_aton(controller)
    except socket.error:
        print "Error: %s is not a valid IPv4 address!" % controller
        sys.exit(2)

    sw_index = int(sys.argv[2])
    print sw_index
    print switches[sw_index]
    if sw_index not in range(0, len(switches) + 1):
        print len(switches) + 1
        print "Error: %s is not a valid switch index!" % sw_index
        sys.exit(2)

    sw_type = switches[sw_index]['type']
    sw_name = switches[sw_index]['name']
    if sw_type == 'gbp':
        print "*****************************"
        print "Configuring %s as a GBP node." % sw_name
        print "*****************************"
        print
        launch([switches[sw_index]], hosts, controller)
        print "*****************************"
        print "OVS status:"
        print "-----------"
        print
        call(['sudo', 'ovs-vsctl', 'show'])
        print
        print "Docker containers:"
        print "------------------"
        call(['docker', 'ps'])
        print "*****************************"
    elif sw_type == 'sff':
        print "*****************************"
        print "Configuring %s as an SFF." % sw_name
        print "*****************************"
        call(['sudo', 'ovs-vsctl', 'set-manager', 'tcp:%s:6640' % controller])
        print
    elif sw_type == 'sf':
        print "*****************************"
        print "Configuring %s as an SF." % sw_name
        print "*****************************"
        call(['%s/sf-config.sh' % os.path.dirname(os.path.realpath(__file__)), '%s' % sw_name])
