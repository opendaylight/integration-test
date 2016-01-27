*** Settings ***
Documentation     Test suite for callhome DTLS channel
Suite Setup       Start CALLHOME_UDP
Suite Teardown    Stop Agent_Echo
Force Tags        UDP_CALLHOME
Resource          ../../../../libraries/UscUtils.robot

*** Variables ***

*** Keywords ***
