*** Settings ***
Documentation     A test suite with a single test for valid login.
...
...               This test has a workflow that is created using keywords in
...               the imported resource file.
# Suite Teardown    Teardown
Library           SSHLibrary    timeout=10s
Library           RequestsLibrary
Resource          ${CURDIR}/../../libraries/NexusKeywords.robot
Resource          ${CURDIR}/../../libraries/NetconfKeywords.robot
Resource          ${CURDIR}/../../libraries/ODLMicroKeywords.robot

*** Variables ***
${ODL_MICRO_VERSION}    1.0.0-SNAPSHOT
${BASE_URL}       https://nexus.opendaylight.org/content/repositories/opendaylight.snapshot/org/opendaylight/odlmicro/micro-netconf
${ORG_URL}        ${BASE_URL}/${ODL_MICRO_VERSION}/
${BUNDLE_URL}     ${BASE_URL}
${ODL_MICRO_WORKSPACE}    /tmp
${NEXUS_NETCONF_URL}     https://nexus.opendaylight.org/content/repositories/opendaylight.snapshot/org/opendaylight/netconf/netconf-testtool/1.9.0-SNAPSHOT/netconf-testtool-1.9.0-20200917.190739-337-executable.jar
${NETCONF_FILENAME}        netconf-testtool-1.9.0-20200917.190739-337-executable.jar
${directory_with_template_folders}    ${CURDIR}/../../../variables/netconf/CRUD
${device_name}    netconf-test-device
${device_type}    full-uri-device
${USE_NETCONF_CONNECTOR}    ${False}
${RESTCONF_PASSWORD}    ${PWD}    # from Variables.robot
${RESTCONF_REUSE}    True
${RESTCONF_SCOPE}    ${EMPTY}
${RESTCONF_USER}    ${USER}    # from Variables.robot
${TOOLS_SYSTEM_PROMPT}    ${ODL_SYSTEM_PROMPT}

*** Test Cases ***
Download and Run ODL Micro
    [Tags]    exclude
    Download ODL Micro
    Run ODL Micro
    BuiltIn.Wait_until_keyword_succeeds    1 min    10 sec    Check Process Stats    NetconfMain
    BuiltIn.Wait_until_keyword_succeeds    1 min    5 sec    Check netstat    8181

Download and Run Netconf Testtool
    Download Netconf Testtool
    Run Netconf Testtool

*** Keywords ***
Teardown
    Kill process    NetconfMain
