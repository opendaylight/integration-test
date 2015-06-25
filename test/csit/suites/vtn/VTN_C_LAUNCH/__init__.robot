*** Settings ***
Documentation     Test suite for VTNC Launch
Suite Setup       Start SuiteVtnCo
Suite Teardown    Stop SuiteVtnCo
Library           SSHLibrary
Resource          ../../../libraries/VtnCoKeywords.txt
