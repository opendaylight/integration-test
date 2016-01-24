*** Settings ***
Documentation     Test suite for L2switch's Address Tracking using mininet OF13
Suite Setup       Start Suite
Suite Teardown    Stop Suite
Library           SSHLibrary
Resource          ../../../libraries/Utils.robot

*** Variables ***
${start}          sudo mn --controller=remote,ip=${ODL_SYSTEM_IP} --topo=linear,3 --switch ovsk,protocols=OpenFlow13 --mac
