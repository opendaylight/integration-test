*** Settings ***
Suite Setup       Start Mininet
Suite Teardown    Stop Mininet
Library           SSHLibrary
Resource          ../../../libraries/Utils.robot

*** Variables ***
${start}          sudo mn --controller=remote,ip=${ODL_SYSTEM_IP} --topo tree,3 --switch ovsk
