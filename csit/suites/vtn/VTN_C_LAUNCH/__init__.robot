*** Settings ***
Documentation       Test suite for VTNC Launch

Library             SSHLibrary
Resource            ../../../libraries/VtnCoKeywords.robot

Suite Setup         Start SuiteVtnCo
Suite Teardown      Stop SuiteVtnCo
