*** Settings ***
Documentation     Test suite for AD-SAL NSF
Suite Setup       Start Suite
Suite Teardown    Delete All Sessions
Library           SSHLibrary
Resource          ../../../libraries/VtnCoKeywords.robot

*** Variables ***
${start}          sudo mn --controller=remote,ip=${ODL_SYSTEM_IP} --topo tree,2

*** Keywords ***
