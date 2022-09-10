*** Settings ***
Documentation       Test suite for callhome TLS channel

Resource            ../../../../libraries/UscUtils.robot

Suite Setup         Start CALLHOME_TCP
Suite Teardown      Stop Agent_Echo
