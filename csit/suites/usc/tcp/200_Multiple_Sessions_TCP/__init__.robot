*** Settings ***
Documentation       Test suite for multiple sessions in an USC TLS channel

Resource            ../../../../libraries/UscUtils.robot

Suite Setup         Start Multiple_Sessions_TCP
Suite Teardown      Stop One_Agent_Multiple_Echo

Force Tags          multiple sessions tcp
