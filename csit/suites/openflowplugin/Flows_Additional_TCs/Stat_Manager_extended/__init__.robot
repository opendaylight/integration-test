*** Settings ***
Documentation       Test suite for the OpenDaylight OpenFlow statistics manager

Library             SSHLibrary
Resource            ../../../../libraries/Utils.robot

Suite Setup         Start Mininet
Suite Teardown      Stop Mininet


*** Variables ***
${start}    sudo mn --controller=remote,ip=${ODL_SYSTEM_IP} --topo tree,1 --switch ovsk,protocols=OpenFlow13
