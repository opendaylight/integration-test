*** Settings ***
Documentation     Test suite for OVSDB TLS Connection Manager
Suite Setup       Init Suite
Suite Teardown    Cleanup Suite
Test Teardown     Cleanup Test
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OVSDB.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../variables/Variables.robot

*** Variables ***

*** Test Cases ***
Connect OVS to Controller with Valid Certificates
    Set Valid Certificates
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl del-manager
    Start Karaf
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl set-manager ssl:${ODL_SYSTEM_IP}:6640
    Wait Until Keyword Succeeds    30s    2s    Verify OVS Reports Connected
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl del-manager

Connect OVS to Controller with Expired Controller Certificate
    Set Certificates with Expired Controller Certificate
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl del-manager
    Start Karaf
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl set-manager ssl:${ODL_SYSTEM_IP}:6640
    Sleep    30    Wait for several ssl connection attempts failing
    Verify OVS Not Reports Connected
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl del-manager

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

Log Certificates in Keystore
    [Documentation]    Shows content of keystore
    ${output}    Run Command On Remote System    ${ODL_SYSTEM_IP}    ${JAVA_HOME}/bin/keytool -list -storepass opendaylight -keystore ${KEYSTORE_PATH}
    log    ${output}
    ${output}    Run Command On Remote System    ${ODL_SYSTEM_IP}    ${JAVA_HOME}/bin/keytool -list -storepass opendaylight -keystore ${TRUSTSTORE_PATH}
    log    ${output}

Generate Server CA Signed Certificate
    [Documentation]    Generates a server certificate and signs it with own root CA
    #Generates Root CA key and certificate (note this has to be self-signed)
    Log Certificates in Keystore
    Run    openssl genrsa -out ${USER_HOME}/rootCA.key 2048
    Run    openssl req -x509 -new -nodes -key ${USER_HOME}/rootCA.key -sha256 -days 1024 -out ${USER_HOME}/rootCA.pem -subj "/C=ES/ST=Madrid/L=Madrid/O=FakeCA/OU=FakeCA_ODL/CN=www.fakeca.com/emailAddress=unknown@fakeca.com"
    #Generate server CSR
    Run    openssl genrsa -out ${USER_HOME}/server.key 2048
    Run    openssl req -new -key ${USER_HOME}/server.key -out ${USER_HOME}/server.csr -subj "/C=ES/ST=Madrid/L=Madrid/O=OpenDayLight/OU=AAA/CN=${ODL_SYSTEM_IP}/emailAddress=unknown@unknown.com"
    #Sign CSR
    Run    openssl x509 -req -in ${USER_HOME}/server.csr -CA ${USER_HOME}/rootCA.pem -CAkey ${USER_HOME}/rootCA.key -CAcreateserial -out ${USER_HOME}/server.crt -days 500 -sha256
    # Convert to pkcs12 (including public and private key together)
    Run    openssl pkcs12 -export -in ${USER_HOME}/server.crt -inkey ${USER_HOME}/server.key -out ${USER_HOME}/server.p12 -name odl -passin pass:opendaylight -passout pass:opendaylight
    Copy File To Remote System    ${ODL_SYSTEM_IP}    ${USER_HOME}/server.p12    /tmp/.
    Run    rm -f ${USER_HOME}/rootCA.key
    Run    rm -f ${USER_HOME}/server.key
    Run    rm -f ${USER_HOME}/server.crt
    Run    rm -f ${USER_HOME}/server.csr
    Run    rm -f ${USER_HOME}/server.p12
    Run    rm -f ${USER_HOME}/rootCA.srl
    # Import Certifcate into keystore
    ${KEYSTORE_DIR}=    Split Path    ${KEYSTORE_PATH}
    Run Command On Remote System    ${ODL_SYSTEM_IP}    mkdir -p ${KEYSTORE_DIR[0]}
    Run Command On Remote System    ${ODL_SYSTEM_IP}    ${JAVA_HOME}/bin/keytool -importkeystore -deststorepass opendaylight -destkeypass opendaylight -destkeystore ${KEYSTORE_PATH} -srckeystore /tmp/server.p12 -srcstoretype PKCS12 -srcstorepass opendaylight -alias odl
    Log Certificates in Keystore

Generate Client CA Signed Certificate
    [Documentation]    Generates a client certificate and signs it with own root CA
    #Generates Root CA key and certificate (note this has to be self-signed)
    Log Certificates in Keystore
    Run    openssl genrsa -out ${USER_HOME}/rootCA_for_clients-key.pem 2048
    Run    openssl req -x509 -new -nodes -key ${USER_HOME}/rootCA_for_clients-key.pem -sha256 -days 365 -out ${USER_HOME}/rootCA_for_clients-cert.pem -subj "/C=ES/ST=Madrid/L=Madrid/O=FakeCA_ForClient/OU=FakeCA_ForClient/CN=www.fakecaforclients.com/emailAddress=unknown@fakecaforclients.com" 2>err.txt
    #Generate client CSR
    Run    openssl genrsa -out ${USER_HOME}/client_ca_signed-key.pem 2048
    Run    openssl req -new -key ${USER_HOME}/client_ca_signed-key.pem -out ${USER_HOME}/client_ca_signed.csr -subj "/C=ES/ST=Madrid/L=Madrid/O=OpenDayLight/OU=RestClient/CN=RestClient/emailAddress=unknown@unknownclient.com"
    #Sign CSR
    Run    openssl x509 -req -in ${USER_HOME}/client_ca_signed.csr -CA ${USER_HOME}/rootCA_for_clients-cert.pem -CAkey ${USER_HOME}/rootCA_for_clients-key.pem -CAcreateserial -out ${USER_HOME}/client_ca_signed-cert.pem -days 500 -sha256
    Copy File To Remote System    ${ODL_SYSTEM_IP}    ${USER_HOME}/rootCA_for_clients-cert.pem    /tmp/.
    Run    rm -f ${USER_HOME}/rootCA_for_clients-cert.pem
    Run    rm -f ${USER_HOME}/rootCA_for_clients-key.pem
    Run    rm -f ${USER_HOME}/client_ca_signed.csr
    Run    rm -f ${USER_HOME}/rootCA_for_clients-cert.srl
    # Import RootCA Certifcate into keystore
    ${KEYSTORE_DIR}=    Split Path    ${KEYSTORE_PATH}
    Run Command On Remote System    ${ODL_SYSTEM_IP}    mkdir -p ${KEYSTORE_DIR[0]}
    Run Command On Remote System    ${ODL_SYSTEM_IP}    ${JAVA_HOME}/bin/keytool -import -trustcacerts -file /tmp/rootCA_for_clients-cert.pem -keystore ${TRUSTSTORE_PATH} -storepass opendaylight -noprompt
    Run Command On Remote System    ${ODL_SYSTEM_IP}    rm -f /tmp/rootCA_for_clients-cert.pem
    Log Certificates in Keystore

Set Valid Certificates
    [Documentation]    Set ODL Keystores with trusted certificates and valid controller certificate and also set openvswitch ssl info with
    ...    private key, client certificate and cacert
    Generate Server CA Signed Certificate
    Generate Client CA Signed Certificate
    #Copy File To Remote System    ${ODL_SYSTEM_IP}    ${CURDIR}/certs/ctl.jks    ${KEYSTORE_PATH}
    #Copy File To Remote System    ${ODL_SYSTEM_IP}    ${CURDIR}/certs/truststore.jks    ${TRUSTSTORE_PATH}
    Copy File To Remote System    ${TOOLS_SYSTEM_IP}    ${USER_HOME}/client_ca_signed-key.pem    /tmp/sc-privkey.pem
    Copy File To Remote System    ${TOOLS_SYSTEM_IP}    ${USER_HOME}/client_ca_signed-cert.pem    /tmp/sc-cert.pem
    Copy File To Remote System    ${TOOLS_SYSTEM_IP}    ${USER_HOME}/rootCA.pem    /tmp/ca-chain.cert.pem
    Run    rm -f ${USER_HOME}/client_ca_signed-key.pem
    Run    rm -f ${USER_HOME}/client_ca_signed-cert.pem
    Run    rm -f ${USER_HOME}/rootCA.pem
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl set-ssl /tmp/sc-privkey.pem /tmp/sc-cert.pem /tmp/ca-chain.cert.pem

Set Certificates with Expired Controller Certificate
    [Documentation]    Set ODL Keystores with trusted certificates and expired controller certificate and also set openvswitch ssl info with
    ...    private key, client certificate and cacert
    Copy File To Remote System    ${ODL_SYSTEM_IP}    ${CURDIR}/certs/ctl_expired.jks    ${KEYSTORE_PATH}
    Copy File To Remote System    ${ODL_SYSTEM_IP}    ${CURDIR}/certs/truststore.jks    ${TRUSTSTORE_PATH}
    Copy File To Remote System    ${TOOLS_SYSTEM_IP}    ${CURDIR}/certs/sc-privkey.pem    /tmp/.
    Copy File To Remote System    ${TOOLS_SYSTEM_IP}    ${CURDIR}/certs/sc-cert.pem    /tmp/.
    Copy File To Remote System    ${TOOLS_SYSTEM_IP}    ${CURDIR}/certs/ca-chain.cert.pem    /tmp/.
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl set-ssl /tmp/sc-privkey.pem /tmp/sc-cert.pem /tmp/ca-chain.cert.pem

Unset Certificates
    [Documentation]    Remove ODL Keystores and Openvswitch certificates and unset openvsiwitch ssl info
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo ovs-vsctl del-ssl
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    rm -f /tmp/sc-privkey.pem
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    rm -f /tmp/sc-cert.pem
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    rm -f /tmp/ca-chain.cert.pem
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    rm -f /tmp/server.p12
    Run Command On Remote System    ${ODL_SYSTEM_IP}    rm -f ${KEYSTORE_PATH}
    Run Command On Remote System    ${ODL_SYSTEM_IP}    rm -f ${TRUSTSTORE_PATH}

Cleanup Test
    [Documentation]    Unsets OVSDB and AAA TLS configuration and restart Karaf system to reload
    Unset Certificates
    Stop Karaf

Init Suite
    [Documentation]    Sets OVSDB and AAA TLS configuration and restart Karaf system to reload
    Stop Karaf
    Enable TLS in OVSDB
    Enable TLS in AAA

Cleanup Suite
    [Documentation]    Unsets OVSDB and AAA TLS configuration and restart Karaf system to reload
    Disable TLS in OVSDB
    Disable TLS in AAA
    Start Karaf
