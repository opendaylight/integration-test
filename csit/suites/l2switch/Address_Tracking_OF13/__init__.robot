*** Settings ***
Documentation       Test suite for L2switch's Address Tracking using mininet OF13

Library             SSHLibrary
Resource            ../../../libraries/Utils.robot

Suite Setup         Start Mininet
Suite Teardown      Stop Mininet


*** Variables ***
${start}    sudo mn --controller=remote,ip=${ODL_SYSTEM_IP} --topo=linear,3 --switch ovsk,protocols=OpenFlow13
