*** Settings ***
Documentation     Test suite for AD-SAL NSF
Suite Setup       Start Suite
Suite Teardown    Stop Suite
Library     SSHLibrary
Resource          ../../../libraries/Utils.robot

*** Variables ***
${start}=   sudo mn --controller=remote,ip=${CONTROLLER} --topo tree,2 

** Keywords ***
