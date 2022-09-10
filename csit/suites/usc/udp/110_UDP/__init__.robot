*** Settings ***
Documentation       Test suite for an USC DTLS channel

Resource            ../../../../libraries/UscUtils.robot

Suite Setup         Start UDP
Suite Teardown      Stop Agent_Echo

Force Tags          110_udp
