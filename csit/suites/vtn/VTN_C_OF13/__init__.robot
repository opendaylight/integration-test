*** Settings ***
Documentation       Test suite for AD-SAL NSF mininet OF13

Library             SSHLibrary
Resource            ../../../libraries/VtnCoKeywords.robot

Suite Setup         Start Mininet
Suite Teardown      Stop Mininet


*** Variables ***
${start}    sudo mn --controller=remote,ip=${ODL_SYSTEM_IP} --topo tree,2 --switch ovsk,protocols=OpenFlow13
