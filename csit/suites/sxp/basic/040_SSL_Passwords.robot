*** Settings ***
Documentation     Test suite to test SSL security fuctionality
Suite Setup       Setup SXP Environment Local    6
Suite Teardown    Clean SXP Environment    6
Test Setup        Clean Nodes
Library           RequestsLibrary
Library           SSHLibrary
Library           ../../../libraries/Sxp.py
Resource          ../../../libraries/SxpLib.robot
Resource          ../../../libraries/WaitForFailure.robot
Resource          ../../../libraries/SSHKeywords.robot

*** Variables ***
${version}        version4
${password}       admin123
${ssl_stores}     /tmp

*** Test Cases ***
SSL ConectivityCase 1
    [Documentation]    Test of SSL security with two SXP-nodes both have each other in truststores
    [Tags]    SXP    SSL
    Add Connection    ${version}    speaker    127.0.0.2    64999    127.0.0.1    security_mode=TLS
    Add Connection    ${version}    listener    127.0.0.1    64999    127.0.0.2    security_mode=TLS
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    speaker    127.0.0.2
    ...    64999    127.0.0.1
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    listener    127.0.0.1
    ...    64999    127.0.0.2
    Clean Connections    127.0.0.1
    Clean Connections    127.0.0.2
    Add Connection    ${version}    listener    127.0.0.2    64999    127.0.0.1    security_mode=TLS
    Add Connection    ${version}    speaker    127.0.0.1    64999    127.0.0.2    security_mode=TLS
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    listener    127.0.0.2
    ...    64999    127.0.0.1
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    speaker    127.0.0.1
    ...    64999    127.0.0.2
    Clean Connections    127.0.0.1
    Clean Connections    127.0.0.2
    Add Connection    ${version}    both    127.0.0.2    64999    127.0.0.1    security_mode=TLS
    Add Connection    ${version}    both    127.0.0.1    64999    127.0.0.2    security_mode=TLS
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    both    127.0.0.2
    ...    64999    127.0.0.1
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    both    127.0.0.1
    ...    64999    127.0.0.2

SSL ConectivityCase 2
    [Documentation]    Test of SSL security with two SXP-nodes while node-1 does not contain node-3 in truststore
    [Tags]    SXP    SSL
    Add Connection    ${version}    speaker    127.0.0.3    64999    127.0.0.1    security_mode=TLS
    Add Connection    ${version}    listener    127.0.0.1    64999    127.0.0.3    security_mode=TLS
    Verify_Keyword_Never_Passes_Within_Timeout    15    1    Verify Connection    ${version}    speaker    127.0.0.3
    ...    64999    127.0.0.1
    Verify_Keyword_Never_Passes_Within_Timeout    15    1    Verify Connection    ${version}    listener    127.0.0.1
    ...    64999    127.0.0.3
    Clean Connections    127.0.0.1
    Clean Connections    127.0.0.3
    Add Connection    ${version}    listener    127.0.0.3    64999    127.0.0.1    security_mode=TLS
    Add Connection    ${version}    speaker    127.0.0.1    64999    127.0.0.3    security_mode=TLS
    Verify_Keyword_Never_Passes_Within_Timeout    15    1    Verify Connection    ${version}    listener    127.0.0.3
    ...    64999    127.0.0.1
    Verify_Keyword_Never_Passes_Within_Timeout    15    1    Verify Connection    ${version}    speaker    127.0.0.1
    ...    64999    127.0.0.3
    Clean Connections    127.0.0.1
    Clean Connections    127.0.0.3
    Add Connection    ${version}    both    127.0.0.3    64999    127.0.0.1    security_mode=TLS
    Add Connection    ${version}    both    127.0.0.1    64999    127.0.0.3    security_mode=TLS
    Verify_Keyword_Never_Passes_Within_Timeout    15    1    Verify Connection    ${version}    both    127.0.0.3
    ...    64999    127.0.0.1
    Verify_Keyword_Never_Passes_Within_Timeout    15    1    Verify Connection    ${version}    both    127.0.0.1
    ...    64999    127.0.0.3

SSL ConectivityCase 3
    [Documentation]    Test of SSL security with two SXP-nodes while both of nodes does not have each other in truststores
    [Tags]    SXP    SSL
    Add Connection    ${version}    speaker    127.0.0.4    64999    127.0.0.1    security_mode=TLS
    Add Connection    ${version}    listener    127.0.0.1    64999    127.0.0.4    security_mode=TLS
    Verify_Keyword_Never_Passes_Within_Timeout    15    1    Verify Connection    ${version}    speaker    127.0.0.4
    ...    64999    127.0.0.1
    Verify_Keyword_Never_Passes_Within_Timeout    15    1    Verify Connection    ${version}    listener    127.0.0.1
    ...    64999    127.0.0.4
    Clean Connections    127.0.0.1
    Clean Connections    127.0.0.4
    Add Connection    ${version}    listener    127.0.0.4    64999    127.0.0.1    security_mode=TLS
    Add Connection    ${version}    speaker    127.0.0.1    64999    127.0.0.4    security_mode=TLS
    Verify_Keyword_Never_Passes_Within_Timeout    15    1    Verify Connection    ${version}    listener    127.0.0.4
    ...    64999    127.0.0.1
    Verify_Keyword_Never_Passes_Within_Timeout    15    1    Verify Connection    ${version}    speaker    127.0.0.1
    ...    64999    127.0.0.4
    Clean Connections    127.0.0.1
    Clean Connections    127.0.0.4
    Add Connection    ${version}    both    127.0.0.4    64999    127.0.0.1    security_mode=TLS
    Add Connection    ${version}    both    127.0.0.1    64999    127.0.0.4    security_mode=TLS
    Verify_Keyword_Never_Passes_Within_Timeout    15    1    Verify Connection    ${version}    both    127.0.0.4
    ...    64999    127.0.0.1
    Verify_Keyword_Never_Passes_Within_Timeout    15    1    Verify Connection    ${version}    both    127.0.0.1
    ...    64999    127.0.0.4

SSL ConectivityCase 4
    [Documentation]    Test of SSL security in topology consisting of SXP-nodes that does not uses any security,
    ...    uses TCP-MD5 and SSL security. Each node conatains series of bindings that in the end should
    ...    be all propagated to node-5 in topology.
    [Tags]    SXP    SSL
    Add Connection    ${version}    listener    127.0.0.2    64999    127.0.0.1    security_mode=TLS
    Add Connection    ${version}    speaker    127.0.0.1    64999    127.0.0.2    security_mode=TLS
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    listener    127.0.0.2
    ...    64999    127.0.0.1
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    speaker    127.0.0.1
    ...    64999    127.0.0.2
    Add Connection    ${version}    listener    127.0.0.3    64999    127.0.0.1    paswd
    Add Connection    ${version}    speaker    127.0.0.1    64999    127.0.0.3    paswd
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    listener    127.0.0.3
    ...    64999    127.0.0.1
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    speaker    127.0.0.1
    ...    64999    127.0.0.3
    Add Connection    ${version}    listener    127.0.0.4    64999    127.0.0.1
    Add Connection    ${version}    speaker    127.0.0.1    64999    127.0.0.4
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    listener    127.0.0.4
    ...    64999    127.0.0.1
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    speaker    127.0.0.1
    ...    64999    127.0.0.4
    Add Connection    ${version}    speaker    127.0.0.5    64999    127.0.0.1    security_mode=TLS
    Add Connection    ${version}    listener    127.0.0.1    64999    127.0.0.5    security_mode=TLS
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    speaker    127.0.0.5
    ...    64999    127.0.0.1
    Wait Until Keyword Succeeds    15    1    Verify Connection    ${version}    listener    127.0.0.1
    ...    64999    127.0.0.5
    Wait Until Keyword Succeeds    15    1    Verify Topology Bindings    6

*** Keywords ***
Setup SXP Environment Local
    [Arguments]    ${node_range}
    [Documentation]    Create session to Controller, copy keystores to ODL machines and setup topology for testing
    Setup SXP Session
    Open_Connection_To_ODL_System
    : FOR    ${node}    IN RANGE    1    ${node_range}
    \    SSHKeywords.Execute_Command_Should_Pass    ${JAVA_HOME}/bin/keytool -genkeypair -alias odl-sxp-${node} -keyalg RSA -storepass ${password} -keypass ${password} -dname "CN=www.opendaylight.org, OU=csit, O=ODL, L=N/A, S=N/A, C=N/A" -keystore csit-keystore-${node}
    \    SSHKeywords.Execute_Command_Should_Pass    ${JAVA_HOME}/bin/keytool -exportcert -keystore csit-keystore-${node} -alias odl-sxp-${node} -storepass ${password} -file odl-sxp-${node}.cer
    # Node-1 TRUSTS Node-2, Node-5
    SSHKeywords.Execute_Command_Should_Pass    ${JAVA_HOME}/bin/keytool -importcert -keystore csit-truststore-1 -alias odl-sxp-2 -storepass ${password} -keypass ${password} -file odl-sxp-2.cer -noprompt
    SSHKeywords.Execute_Command_Should_Pass    ${JAVA_HOME}/bin/keytool -importcert -keystore csit-truststore-1 -alias odl-sxp-5 -storepass ${password} -keypass ${password} -file odl-sxp-5.cer -noprompt
    # Node-2 TRUSTS Node-1
    SSHKeywords.Execute_Command_Should_Pass    ${JAVA_HOME}/bin/keytool -importcert -keystore csit-truststore-2 -alias odl-sxp-2 -storepass ${password} -keypass ${password} -file odl-sxp-1.cer -noprompt
    # Node-3 TRUSTS Node-1
    SSHKeywords.Execute_Command_Should_Pass    ${JAVA_HOME}/bin/keytool -importcert -keystore csit-truststore-3 -alias odl-sxp-2 -storepass ${password} -keypass ${password} -file odl-sxp-1.cer -noprompt
    # Node-5 TRUSTS Node-1
    SSHKeywords.Execute_Command_Should_Pass    ${JAVA_HOME}/bin/keytool -importcert -keystore csit-truststore-5 -alias odl-sxp-2 -storepass ${password} -keypass ${password} -file odl-sxp-1.cer -noprompt
    SSHKeywords.Execute_Command_Should_Pass    cp csit-keystore-4 csit-truststore-4
    SSHKeywords.Execute_Command_Should_Pass    rm odl-sxp-*.cer
    SSHKeywords.Execute_Command_Should_Pass    mv ./csit-keystore-* ${ssl_stores}
    SSHKeywords.Execute_Command_Should_Pass    mv ./csit-truststore-* ${ssl_stores}
    SSHLibrary.Close Connection
    : FOR    ${node}    IN RANGE    1    ${node_range}
    \    ${SSL}    Create Dictionary    truststore=${ssl_stores}/csit-truststore-${node}    keystore=${ssl_stores}/csit-keystore-${node}    password=${password}
    \    Add Node    127.0.0.${node}    ${EMPTY}    ssl_stores=${SSL}
    \    Add Binding    ${node}00    1.1.1.${node}/32    127.0.0.${node}
    \    Add Binding    ${node}00    2.2.2.${node}/32    127.0.0.${node}

Verify Topology Bindings
    [Arguments]    ${node_range}
    [Documentation]    Create session to Controller
    ${resp}    Get Bindings    127.0.0.5
    : FOR    ${node}    IN RANGE    1    ${node_range}
    \    Should Contain Binding    ${resp}    ${node}00    2.2.2.${node}/32

Clean Nodes
    [Documentation]    Cleanup of resources alocated by test suite
    Clean Connections    127.0.0.1
    Clean Connections    127.0.0.2
    Clean Connections    127.0.0.3
    Clean Connections    127.0.0.4
    Clean Connections    127.0.0.5
