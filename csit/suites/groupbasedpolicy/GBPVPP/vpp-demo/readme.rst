VPP-DEMO for GBP
================
This demo requires Vagrant (tested on 1.8.5 version) and VirtualBox (tested on 5.1.2 version)
To setup the environment just navigate to groupbasedpolicy\demos\vpp-demo and execute following command::

    vagrant up

Vagrant then creates 3VMs (controller, compute0 and compute1). After vagrant finishes you can stop the VMs with
"vagrant halt" command and bring them up again with "vagrant up" command. If distribution-karaf-0.5.0-Boron.tar.gz is
available in vpp-demo folder vagrant setup will use this one. If it is not it will download ODL to controller node.

DEMO setup
----------
(repeat this everytime you want to reset the demo)
To reset state of VMs run the following command on all VMs. It resolves on which node it is running and
configures IPs to vpp::

    /vagrant/reload-nodes.sh

To enter VMs use "vagrant ssh" command::

    vagrant ssh controller
    vagrant ssh compute0
    vagrant ssh compute1

On controller the script will start ODL in debug mode.

You need to install following features in ODL (logs are optional)::

    feature:install odl-vbd-ui odl-groupbasedpolicy-ui odl-groupbasedpolicy-neutron-vpp-mapper odl-restconf

    log:set ERROR org.opendaylight.netconf
    log:set TRACE org.opendaylight.groupbasedpolicy.renderer.vpp
    log:set TRACE org.opendaylight.groupbasedpolicy.neutron.vpp.mapper
    log:set TRACE org.opendaylight.vbd.impl
    log:set ERROR org.opendaylight.netconf
    log:tail

You can now import vpp-demo collection (local-demo-postman.json) to postman and start demo by following these steps::

    1. You need to register VPP nodes in postman collection:
       a. Register VPP controller
       b. Register VPP compute0
       c. Register VPP compute1
    2. After nodes are connected (you can check in "VPP renderer operational") yo can feed data to ODL:
       use "neutron data - initial" from collection
    3. This will take some time, then you should be able to add tap ports to namespaces and ping between them

As the last thing you need to assign Tap ports which were created by the above configuration to according namespaces.

On controller::

    sudo ip netns add vpp-controller
    sudo ip link set dev qr-6a616da7-d1 up netns vpp-controller
    sudo ip link set dev tapc6076003-2b up netns vpp-controller
    sudo ip netns exec vpp-controller ip addr add 10.11.12.1/24 dev qr-6a616da7-d1
    sudo ip netns exec vpp-controller ip addr add 10.11.12.2/24 dev tapc6076003-2b

    sudo ip netns exec vpp-controller ping 10.11.12.3 -c 5
    sudo ip netns exec vpp-controller ping 10.11.12.4 -c 5
    sudo ip netns exec vpp-controller ping 10.11.12.5 -c 5
    sudo ip netns exec vpp-controller ping 10.11.12.6 -c 5

On compute0::

    sudo ip netns add vpp-compute0
    sudo ip link set dev tap8def6a66-7d up netns vpp-compute0
    sudo ip link set dev tapa9607d99-0a up netns vpp-compute0
    sudo ip netns exec vpp-compute0 ip addr add 10.11.12.4/24 dev tap8def6a66-7d
    sudo ip netns exec vpp-compute0 ip addr add 10.11.12.3/24 dev tapa9607d99-0a

    sudo ip netns exec vpp-compute0 ping 10.11.12.1 -c 5
    sudo ip netns exec vpp-compute0 ping 10.11.12.2 -c 5
    sudo ip netns exec vpp-compute0 ping 10.11.12.5 -c 5
    sudo ip netns exec vpp-compute0 ping 10.11.12.6 -c 5

On compute1::

    sudo ip netns add vpp-compute1
    sudo ip link set dev tap7415f153-2a up netns vpp-compute1
    sudo ip link set dev tapfa943a17-ac up netns vpp-compute1
    sudo ip netns exec vpp-compute1 ip addr add 10.11.12.5/24 dev tap7415f153-2a
    sudo ip netns exec vpp-compute1 ip addr add 10.11.12.6/24 dev tapfa943a17-ac

    sudo ip netns exec vpp-compute1 ping 10.11.12.1 -c 5
    sudo ip netns exec vpp-compute1 ping 10.11.12.2 -c 5
    sudo ip netns exec vpp-compute1 ping 10.11.12.3 -c 5
    sudo ip netns exec vpp-compute1 ping 10.11.12.4 -c 5
