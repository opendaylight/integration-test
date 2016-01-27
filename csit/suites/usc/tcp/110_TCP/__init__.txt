*** Settings ***
Documentation     Test suite for an USC TLS channel
Suite Setup       Start TCP
Suite Teardown    Stop Agent_Echo
Resource          ../../../../libraries/UscUtils.robot

*** Variables ***

*** Keywords ***
