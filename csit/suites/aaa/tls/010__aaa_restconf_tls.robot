*** Settings ***
Documentation     Test suite for Securing RESTCONF communication.
Suite Setup       Init Suite
Suite Teardown    Cleanup Suite
Library           OperatingSystem
Library           RequestsLibrary
Library           PycURLLibrary
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/KarafKeywords.robot

*** Variables ***
${RESTCONF_MONITORING_URI}    /restconf/operational/ietf-restconf-monitoring:restconf-state
${RESTCONF_MONITORING_URL}    https://${ODL_SYSTEM_IP}:${SECURE_RESTCONF_PORT}${RESTCONF_MONITORING_URI}
${KEYSTORE_RELATIVE_PATH}     configuration/ssl/.keystore
${KEYSTORE_PATH}              /tmp/${BUNDLEFOLDER}/configuration/ssl/.keystore
${CUSTOMPROP}                 /tmp/${BUNDLEFOLDER}/etc/custom.properties

*** Test Cases ***
Basic Unsecure Restconf Request
    [Documentation]    Tests a basic HTTP request, just to ensure that system is working fine with normal, unsecure reqs
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    ${resp}    RequestsLibrary.Get Request    session    ${RESTCONF_MONITORING_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Delete All Sessions

TLS on Restconf without Server Cert
    [Documentation]    Tests an HTTPS request towards secure port with ODL secure config deactivated
    Set Url    ${RESTCONF_MONITORING_URL}
    Add Header    "Content-Type:application/json"
    Add Header    Authorization:Basic YWRtaW46YWRtaW4=
    Request Method    GET
    Run Keyword And Expect Error    error: (7, 'Failed to connect to 127.0.0.1 port 8443: Connection refused')    Perform
    Log Response

Activate TLS and Generate Server Certificate
    [Documentation]    Generates a server certificate, self-signed and activates ODL secure configuration.
    Generate Server Self-Signed Certificate
    Enable TLS in ODL

TLS on Restconf with Server Cert (Self-signed) (insecure)
    [Documentation]    Tests HTTPS request. Server certificate is self-signed, thus communication is insecure
    Set Url    ${RESTCONF_MONITORING_URL}
    Add Header    "Content-Type:application/json"
    Add Header    Authorization:Basic YWRtaW46YWRtaW4=
    Request Method    GET
    Perform
    Log Response
    Response Status Should Contain    200
    ${resp}    Response
    Should Contain    ${resp}    "restconf-state":{"capabilities":{"capability":["urn:ietf:params:restconf:capability:depth

Activate Client Authentication and Generate Client Certificate
    [Documentation]    Generates a client certificate and imports it into ODL truststore.
    ...    Changes ODL config to require client authentication
    Generate Client Self-Signed Certificate
    Enable Client TLS Authentication in ODL

TLS on Restconf with Server & Client Certs (Self-signed)
    [Documentation]    Test HTTPS request with ODL TLS config and client authentication by using certificate
    Set Url    ${RESTCONF_MONITORING_URL}
    Add Header    "Content-Type:application/json"
    Add Header    Authorization:Basic YWRtaW46YWRtaW4=
    Client Certificate File    clientcert.pem
	Private Key File	clientkey.pem
	Request Method    GET
    Perform
    Log Response
    Response Status Should Contain    200
    ${resp}    Response
    Should Contain    ${resp}    "restconf-state":{"capabilities":{"capability":["urn:ietf:params:restconf:capability:depth

#Future Test Cases
#TLS on Restconf with Server & Client Certs (CA signed)
#Restconf HTTPS/TLS Jolokia with server and client certificates CA signed

*** Keywords ***
Restart Karaf
    [Documentation]    Restarts karaf and waits 60 seconds (this needs to be improved with a polling log system)
    Issue_Command_On_Karaf_Console    shutdown -r -f
    Sleep    60s

Restart Jetty
    [Documentation]    Restarts jetty bundle (to reload certificates or key/truststore information)
    Safe_Issue_Command_On_Karaf_Console    bundle:restart -f $(bundle:id "OPS4J Pax Web - Jetty")

Log Certificates in Keystore
    [Documentation]    Shows content of keystore
    ${output}    Run    keytool -list -storepass 123456 -keystore ${KEYSTORE_PATH}
    log    ${output}

Clean Up Certificates In Server
    [Documentation]    Cleans keystore content (only for private keys and trusted certificates)
    Log Certificates in Keystore
    ${cmd}=    catenate    keytool -list -keystore ${KEYSTORE_PATH} -storepass 123456|
    ...    egrep -e "(trustedCertEntry|PrivateKeyEntry)"|cut -d"," -f1|
    ...    xargs -I[] keytool -delete -alias [] -keystore ${KEYSTORE_PATH} -storepass 123456
    Run    ${cmd}
    Log Certificates in Keystore

Generate Server Self-Signed Certificate
    [Documentation]    Generates a self-signed certificate, stores it into keystore and restarts jetty to load changes
    Log Certificates in Keystore
    #Generate with openssl
    ${cmd}=    catenate    openssl req -x509 -newkey rsa:4096 -passout pass:myPass -keyout serverkey.pem
    ...    -out servercert.pem -days 365
    ...    -subj "/C=ES/ST=Madrid/L=Madrid/O=OpenDayLight/OU=AAA/CN=OpenDayLight/emailAddress=unknown@unknown.com"
    Run    ${cmd}
    #Convert to pkcs12 (including public and private key together)
    ${cmd}=    catenate    openssl pkcs12 -export -in servercert.pem -inkey serverkey.pem -out server.p12
    ...    -name odl -passin pass:myPass -passout pass:myPass
    Run    ${cmd}
    #Import Certifcate into keystore
    ${cmd}=    catenate    keytool -importkeystore -deststorepass 123456 -destkeypass myPass
    ...    -destkeystore ${KEYSTORE_PATH} -srckeystore server.p12 -srcstoretype PKCS12 -srcstorepass myPass -alias odl
    Run    ${cmd}
    Log Certificates in Keystore
    Restart Jetty

Generate Client Self-Signed Certificate
    [Documentation]    Generates a client self-signed certificate, stores it into the keystore (as trusted cert) and
    ...    restarts jettty to load changes
    Log Certificates in Keystore
    #Generate with openssl
    # Note -nodes is used to avoid passphrase in private key. Also -passout pass:myPass is skipped. This is due to a
    # limitation in pycurl library that does not support key pem files with passphrase in automatic mode (it asks for it)
    ${cmd}=    catenate    openssl req -x509 -newkey rsa:4096 -nodes -keyout clientkey.pem -out clientcert.pem -days 365
    ...    -subj "/C=ES/ST=Madrid/L=Madrid/O=OpenDayLight/OU=AAA/CN=MiguelAngelMunoz/emailAddress=myemail@unknown.com"
    Run    ${cmd}
    #Import client's cert as trusted
    Run    keytool -import -trustcacerts -file clientcert.pem -keystore ${KEYSTORE_PATH} -storepass 123456 -noprompt
    Log Certificates in Keystore
    Restart Jetty

Disable TLS in ODL
    [Documentation]    Remove TLS configuration in custom.properties
    Run    sed -i '/org.osgi.service.http.secure.enabled=/d' ${CUSTOMPROP}
    Run    sed -i '/org.ops4j.pax.web.ssl.keystore=/d' ${CUSTOMPROP}
    Run    sed -i '/org.ops4j.pax.web.ssl.password=/d' ${CUSTOMPROP}
    Run    sed -i '/org.ops4j.pax.web.ssl.keypassword=/d' ${CUSTOMPROP}
    Run    sed -i '/org.ops4j.pax.web.ssl.clientauthneeded=/d' ${CUSTOMPROP}
    Restart Karaf

Enable TLS in ODL
    [Documentation]    Add new secure configuration in custom.properties
    Run    echo "org.osgi.service.http.secure.enabled=true">> ${CUSTOMPROP}
    Run    echo "org.ops4j.pax.web.ssl.keystore=${KEYSTORE_RELATIVE_PATH}">> ${CUSTOMPROP}
    Run    echo "org.ops4j.pax.web.ssl.password=myPass">> ${CUSTOMPROP}
    Run    echo "org.ops4j.pax.web.ssl.keypassword=123456">> ${CUSTOMPROP}
    Restart Karaf

Enable Client TLS Authentication in ODL
    [Documentation]     Add custom.properties configuration to enable client auth
    Run    echo "org.ops4j.pax.web.ssl.clientauthneeded=true">> ${CUSTOMPROP}
    Restart Karaf

Init Suite
    [Documentation]    Cleans TLS configuration and restart Karaf system to reload
    Clean Up Certificates In Server
    Disable TLS in ODL

Cleanup Suite
    [Documentation]    Deletes pending sessions in case there were any
    Delete All Sessions
