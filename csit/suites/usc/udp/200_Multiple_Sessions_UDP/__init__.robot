*** Settings ***
Documentation     Test suite for multiple sessions in an USC DTLS channel
Suite Setup       Start Multiple_Sessions_UDP
Suite Teardown    Stop One_Agent_Multiple_Echo
Force Tags        Multiple_Sessions_UDP
Resource          ../../../../libraries/UscUtils.robot

*** Variables ***

*** Keywords ***
