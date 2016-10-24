*** Settings ***
Documentation     Test suite for OpenFlow Groups and Meters
Suite Setup       Start Mininet
Suite Teardown    Stop Mininet
Library           SSHLibrary
Resource          ../../../libraries/Utils.robot
Variables         ../../../variables/Variables.py

*** Variables ***
${start}          sudo mn --controller=remote,ip=${ODL_SYSTEM_IP} --topo tree,1 --switch user

*** Keywords ***
