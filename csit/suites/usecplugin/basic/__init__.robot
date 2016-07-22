*** Settings ***
Documentation     Flow test suite for the OpenDaylight karaf-compatible feature set
Suite Setup       Start Suite
Suite Teardown    Stop Suite
Resource          ../../../libraries/UtilsUsec.robot
Resource          ../../../libraries/KarafKeywords.robot
Variables         ../../../variables/Variables.py

*** Variables ***

*** Keywords ***
