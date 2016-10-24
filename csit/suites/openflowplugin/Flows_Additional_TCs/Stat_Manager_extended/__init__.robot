*** Settings ***
Documentation     Test suite for the OpenDaylight OpenFlow statistics manager
Suite Setup       Start Mininet
Suite Teardown    Stop Mininet
Library           SSHLibrary
Resource          ../../../../libraries/Utils.robot

*** Variables ***
${start}          sudo mn --controller=remote,ip=${ODL_SYSTEM_IP} --topo tree,1 --switch ovsk,protocols=OpenFlow13
