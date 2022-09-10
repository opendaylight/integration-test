*** Settings ***
Documentation       Test suite for callhome DTLS channel

Resource            ../../../../libraries/UscUtils.robot

Suite Setup         Start CALLHOME_UDP
Suite Teardown      Stop Agent_Echo

Force Tags          udp_callhome
