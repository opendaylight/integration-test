*** Settings ***
Documentation     Test suite for NatApp
Suite Setup       NatApp_Utils.Start Suite
Suite Teardown    NatApp_Utils.Stop Suite
Library           SSHLibrary
Resource          ../../../libraries/NatApp_Utils.robot

*** Variables ***
${start}          sudo mn --mac --controller=remote,ip=${ODL_SYSTEM_IP},port=6653 --topo=single,10 --switch ovsk,protocols=OpenFlow13
