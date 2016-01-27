*** Settings ***
Documentation     Test suite for multiple sessions in an USC TLS channel
Suite Setup       Start Multiple_Sessions_TCP
Suite Teardown    Stop One_Agent_Multiple_Echo
Force Tags        Multiple Sessions TCP
Resource          ../../../../libraries/UscUtils.robot

*** Variables ***

*** Keywords ***
