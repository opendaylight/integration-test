*** Settings ***
Documentation     Test suite for NIC OF Renderer
Suite Setup       Start NIC OF Renderer Suite
Suite Teardown    Stop NIC OF Renderer Suite
Library           SSHLibrary
Resource          ../../../libraries/NicKeywords.robot
