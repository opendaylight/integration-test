*** Settings ***
Documentation       Test suite for an USC TLS channel

Resource            ../../../../libraries/UscUtils.robot

Suite Setup         Start TCP
Suite Teardown      Stop Agent_Echo
