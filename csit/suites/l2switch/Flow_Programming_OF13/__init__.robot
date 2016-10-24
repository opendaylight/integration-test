*** Settings ***
Documentation     Test suite for L2switch's Flow Programming using mininet OF13
Suite Setup       Start Mininet
Suite Teardown    Stop Mininet
Library           SSHLibrary
Resource          ../../../libraries/Utils.robot

*** Variables ***
${start}          sudo mn --controller=remote,ip=${ODL_SYSTEM_IP} --topo=tree,2 --switch ovsk,protocols=OpenFlow13
