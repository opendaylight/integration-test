*** Settings ***
Documentation     Test suite for NIC OF Renderer
Suite Setup       Start NIC OF Renderer Suite
Suite Teardown    Stop NIC OF Renderer Suite
Library           SSHLibrary
Resource          ../../../libraries/NicKeywords.robot

*** Variables ***
${start}          sudo mn --mac --controller=remote,ip=${ODL_SYSTEM_IP} --topo linear,8
