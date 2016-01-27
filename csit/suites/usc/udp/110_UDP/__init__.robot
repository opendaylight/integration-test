*** Settings ***
Documentation     Test suite for an USC DTLS channel
Suite Setup       Start UDP
Suite Teardown    Stop Agent_Echo
Force Tags        110_UDP
Resource          ../../../../libraries/UscUtils.robot

*** Variables ***

*** Keywords ***
