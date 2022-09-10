*** Settings ***
Documentation       Test suite for AD-SAL NSF

Library             SSHLibrary
Resource            ../../../libraries/VtnCoKeywords.robot

Suite Setup         Start Mininet
Suite Teardown      Delete All Sessions


*** Variables ***
${start}    sudo mn --controller=remote,ip=${ODL_SYSTEM_IP} --topo tree,2
