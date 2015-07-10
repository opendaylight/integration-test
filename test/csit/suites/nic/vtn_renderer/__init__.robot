*** Settings ***
Documentation     Test suite for NIC VTN Renderer(OF13)
Suite Setup       Start NIC VTN Renderer Suite
Suite Teardown    Stop NIC VTN Renderer Suite
Library           SSHLibrary
Resource          ../../../libraries/NicKeywords.robot
