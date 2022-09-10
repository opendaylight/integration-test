*** Settings ***
Documentation       Test suite for MD-SAL NSF

Library             SSHLibrary
Resource            ../../../libraries/Utils.robot

Suite Setup         Start Mininet
Suite Teardown      Stop Mininet


*** Variables ***
${start}    sudo mn --controller=remote,ip=${ODL_SYSTEM_IP} --topo tree,2 --switch ovsk,protocols=OpenFlow13
