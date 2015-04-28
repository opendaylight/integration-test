*** Settings ***
Documentation     Test suite for OpenFlow Groups and Meters
Suite Setup       Start Suite
Suite Teardown    Stop Suite
Library           SSHLibrary
Resource          ../../../libraries/Utils.txt
Variables         ../../../variables/Variables.py

*** Variables ***
${start}          sudo mn --controller=remote,ip=${CONTROLLER} --topo tree,1 --switch user

*** Keywords ***
