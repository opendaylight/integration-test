*** Settings ***
Suite Setup       Start Connections
Library           SSHLibrary    120 seconds
Resource          ../GBPClusteringKeywords.robot

*** Test Cases ***
Verify Setup
    [Documentation]    Verify that all stuff is configured properly
    Verify VPP Setup
