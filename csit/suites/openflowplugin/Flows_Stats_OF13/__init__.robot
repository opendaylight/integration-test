*** Settings ***
Documentation       Test suite for the OpenDaylight base edition with of13, aimed for statistics manager

Library             SSHLibrary
Resource            ../../../libraries/Utils.robot

Suite Setup         Start Mininet
Suite Teardown      Stop Mininet
