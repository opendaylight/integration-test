*** Settings ***
Documentation     A test suite with a single test for valid login.
...
...               This test has a workflow that is created using keywords in
...               the imported resource file.
Suite Teardown    Teardown
Library           SSHLibrary    timeout=10s
Library           RequestsLibrary
Resource          ${CURDIR}/../../libraries/NexusKeywords.robot
Resource          ${CURDIR}/../../libraries/ODLMicroKeywords.robot

*** Variables ***
${ODL_MICRO_VERSION}    1.0.0-SNAPSHOT
${BASE_URL}       https://nexus.opendaylight.org/content/repositories/opendaylight.snapshot/org/opendaylight/odlmicro/micro-netconf
${ORG_URL}        ${BASE_URL}/${ODL_MICRO_VERSION}/
${BUNDLE_URL}     ${BASE_URL}
${ODL_MICRO_WORKSPACE}    /tmp

*** Test Cases ***
Download and Run ODL Micro
    Download ODL Micro
    Run ODL Micro
    BuiltIn.Wait_until_keyword_succeeds    1 min    10 sec    Check Process Stats    NetconfMain
    BuiltIn.Wait_until_keyword_succeeds    1 min    5 sec    Check netstat    8181

*** Keywords ***
Teardown
    Kill process    NetconfMain
