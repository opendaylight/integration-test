*** Settings ***
Documentation     Test suite for OVSDB TLS Connection Manager
Suite Setup       Init Suite
Suite Teardown    Cleanup Suite
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../variables/Variables.robot

*** Variables ***

*** Test Cases ***
Connecting an OVS instance to the controller
    Set Valid Certificates
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl del-manager
    Start Karaf
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl set-manager ssl:${ODL_SYSTEM_IP}:6640
    Wait Until Keyword Succeeds    30s    2s    Verify OVS Reports Connected
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl del-manager
    Unset Valid Certificates

*** Keywords ***
Enable TLS in OVSDB
    [Documentation]    Add new secure configuration in custom.properties
    Run Command On Remote System    ${ODL_SYSTEM_IP}    sudo sed -i 's/.*use-ssl.*/use-ssl = true/' ${OVSDB_TLS_CONFIG}

Disable TLS in OVSDB
    [Documentation]    Remove TLS configuration in custom.properties
    Run Command On Remote System    ${ODL_SYSTEM_IP}    sudo sed -i 's/.*use-ssl.*/use-ssl = false/' ${OVSDB_TLS_CONFIG}

Enable TLS in AAA
    [Documentation]    Add new secure configuration in custom.properties
    Run Command On Remote System    ${ODL_SYSTEM_IP}    sudo sed -i 's/<use-config>false<\\/use-config>/<use-config>true<\\/use-config>/' ${AAA_TLS_CONFIG}
    Run Command On Remote System    ${ODL_SYSTEM_IP}    sudo sed -i 's/<use-mdsal>true<\\/use-mdsal>/<use-mdsal>false<\\/use-mdsal>/' ${AAA_TLS_CONFIG}
    Run Command On Remote System    ${ODL_SYSTEM_IP}    sudo sed -i 's/<store-password>.*/<store-password>opendaylight<\\/store-password>/' ${AAA_TLS_CONFIG}

Disable TLS in AAA
    [Documentation]    Remove TLS configuration in custom.properties
    Run Command On Remote System    ${ODL_SYSTEM_IP}    sudo sed -i 's/<use-config>false<\\/use-config>/<use-config>true<\\/use-config>/' ${AAA_TLS_CONFIG}
    Run Command On Remote System    ${ODL_SYSTEM_IP}    sudo sed -i 's/<use-mdsal>false<\\/use-mdsal>/<use-mdsal>true<\\/use-mdsal>/' ${AAA_TLS_CONFIG}

Set Valid Certificates
    [Documentation]    Set ODL Keystores with trusted and server certificates and also set openvswitch ssl info with
    ...    private key, client certificate and cacert
    Copy File To Remote System    ${ODL_SYSTEM_IP}    ${CURDIR}/certs/ctl.jks    ${KEYSTORE_PATH}
    Copy File To Remote System    ${ODL_SYSTEM_IP}    ${CURDIR}/certs/truststore.jks    ${TRUSTSTORE_PATH}
    Copy File To Remote System    ${TOOLS_SYSTEM_IP}    ${CURDIR}/certs/sc-privkey.pem    /tmp/.
    Copy File To Remote System    ${TOOLS_SYSTEM_IP}    ${CURDIR}/certs/sc-cert.pem    /tmp/.
    Copy File To Remote System    ${TOOLS_SYSTEM_IP}    ${CURDIR}/certs/ca-chain.cert.pem    /tmp/.
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl set-ssl /tmp/sc-privkey.pem /tmp/sc-cert.pem /tmp/ca-chain.cert.pem

Unset Valid Certificates
    [Documentation]    Remove ODL Keystores and Openvswitch certificates and unset openvsiwitch ssl info
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl del-ssl
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    rm -rf /tmp/sc-privkey.pem
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    rm -rf /tmp/sc-cert.pem
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    rm -rf /tmp/ca-chain.cert.pem
    Run Command On Remote System    ${ODL_SYSTEM_IP}    rm -rf ${KEYSTORE_PATH}
    Run Command On Remote System    ${ODL_SYSTEM_IP}    rm -rf ${TRUSTSTORE_PATH}

Init Suite
    [Documentation]    Sets OVSDB and AAA TLS configuration and restart Karaf system to reload
    Stop Karaf
    Enable TLS in OVSDB
    Enable TLS in AAA

Cleanup Suite
    [Documentation]    Unsets OVSDB and AAA TLS configuration and restart Karaf system to reload
    #Stop Karaf
    Disable TLS in OVSDB
    Disable TLS in AAA
    #Start Karaf
