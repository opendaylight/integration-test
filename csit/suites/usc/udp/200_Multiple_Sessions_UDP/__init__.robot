*** Settings ***
Documentation       Test suite for multiple sessions in an USC DTLS channel

Resource            ../../../../libraries/UscUtils.robot

Suite Setup         Start Multiple_Sessions_UDP
Suite Teardown      Stop One_Agent_Multiple_Echo

Force Tags          multiple_sessions_udp
