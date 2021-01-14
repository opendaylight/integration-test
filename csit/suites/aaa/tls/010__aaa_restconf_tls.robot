*** Settings ***
Documentation     Test suite for Securing RESTCONF communication.
...               Note this suite requires PycURLLibrary to handle client certificates. While Requests library is able
...               to handle server certificates well, it lacks capabilities to deal with client certificates.
...               TODO: Investigate the possibility to incorporate this into TemplatedRequests
Suite Setup       Init Suite
Suite Teardown    Cleanup Suite
Library           OperatingSystem
Library           RequestsLibrary
Library           PycURLLibrary
Library           SSHLibrary
Resource          ../../../libraries/ClusterManagement.robot
Resource          ../../../variables/Variables.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/SSHKeywords.robot

*** Variables ***
${RESTCONF_MONITORING_URI}    /restconf/operational/ietf-restconf-monitoring:restconf-state
${RESTCONF_MONITORING_URL}    https://${ODL_SYSTEM_IP}:${RESTCONFPORT_TLS}${RESTCONF_MONITORING_URI}

*** Test Cases ***
Basic Unsecure Restconf Request
    [Documentation]    Tests a basic HTTP request, just to ensure that system is working fine with normal, unsecure reqs
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    ${resp}    RequestsLibrary.GET On Session    session    ${RESTCONF_MONITORING_URI}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}
    Delete All Sessions

TLS on Restconf without Server Cert
    [Documentation]    Tests an HTTPS request towards secure port with ODL secure config deactivated
    PycURLLibrary.Set Url    ${RESTCONF_MONITORING_URL}
    PycURLLibrary.Add Header    "Content-Type:application/json"
    PycURLLibrary.Add Header    Authorization:Basic YWRtaW46YWRtaW4=
    PycURLLibrary.Request Method    GET
    Run Keyword And Expect Error    error: (7, 'Failed *${RESTCONFPORT_TLS}* Connection refused')    PycURLLibrary.Perform
    PycURLLibrary.Log Response

Activate TLS
    [Documentation]    Activates TLS configuration in ODL and restarts Karaf
    Enable TLS in ODL
    # Check ODL was restarted properly
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    ${resp}    RequestsLibrary.GET On Session    session    ${RESTCONF_MONITORING_URI}
    Delete All Sessions
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

TLS on Restconf with Server Cert (Self-signed) (insecure)
    [Documentation]    Tests HTTPS request. Server certificate is self-signed, thus communication is insecure
    Clean Up Certificates In Server
    Generate Server Self-Signed Certificate
    #TLS Request
    Insecure Ssl
    PycURLLibrary.Set Url    ${RESTCONF_MONITORING_URL}
    PycURLLibrary.Add Header    "Content-Type:application/json"
    PycURLLibrary.Add Header    Authorization:Basic YWRtaW46YWRtaW4=
    PycURLLibrary.Request Method    GET
    PycURLLibrary.Perform
    PycURLLibrary.Log Response
    PycURLLibrary.Response Status Should Contain    200
    ${resp}    PycURLLibrary.Response
    Should Contain    ${resp}    "restconf-state":{"capabilities":{"capability":["urn:ietf:params:restconf:capability:depth

TLS on Restconf with Server Cert (CA signed)
    [Documentation]    Tests HTTPS request with ODL TLS config by using CA signed certificates
    Clean Up Certificates In Server
    Generate Server CA Signed Certificate
    #TLS Request
    PycURLLibrary.Set Url    ${RESTCONF_MONITORING_URL}
    PycURLLibrary.Add Header    "Content-Type:application/json"
    PycURLLibrary.Add Header    Authorization:Basic YWRtaW46YWRtaW4=
    PycURLLibrary.Request Method    GET
    PycURLLibrary.Perform
    PycURLLibrary.Log Response
    PycURLLibrary.Response Status Should Contain    200
    ${resp}    PycURLLibrary.Response
    Should Contain    ${resp}    "restconf-state":{"capabilities":{"capability":["urn:ietf:params:restconf:capability:depth

Activate Client Authentication
    [Documentation]    Activates client authentication in odl by means of certificates.
    Enable Client TLS Authentication in ODL
    # Check ODL was restarted properly
    Create Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    ${resp}    RequestsLibrary.GET On Session    session    ${RESTCONF_MONITORING_URI}
    Delete All Sessions
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

TLS on Restconf with Server & Client Certs (Self-signed)
    [Documentation]    Test HTTPS request with ODL TLS config and client authentication by using certificate
    Clean Up Certificates In Server
    Generate Server Self-Signed Certificate
    Generate Client Self-Signed Certificate
    #TLS Request
    PycURLLibrary.Set Url    ${RESTCONF_MONITORING_URL}
    PycURLLibrary.Add Header    "Content-Type:application/json"
    PycURLLibrary.Add Header    Authorization:Basic YWRtaW46YWRtaW4=
    PycURLLibrary.Client Certificate File    ${USER_HOME}/clientcert.pem
    PycURLLibrary.Private Key File    ${USER_HOME}/clientkey.pem
    PycURLLibrary.Request Method    GET
    PycURLLibrary.Perform
    PycURLLibrary.Log Response
    PycURLLibrary.Response Status Should Contain    200
    ${resp}    PycURLLibrary.Response
    Should Contain    ${resp}    "restconf-state":{"capabilities":{"capability":["urn:ietf:params:restconf:capability:depth

TLS on Restconf with Server & Client Certs (CA signed)
    [Documentation]    Tests HTTPS request with ODL TLS config and client authentication by using CA signed certificates
    Clean Up Certificates In Server
    Generate Server CA Signed Certificate
    Generate Client CA Signed Certificate
    #TLS Request
    PycURLLibrary.Set Url    ${RESTCONF_MONITORING_URL}
    PycURLLibrary.Add Header    "Content-Type:application/json"
    PycURLLibrary.Add Header    Authorization:Basic YWRtaW46YWRtaW4=
    PycURLLibrary.Client Certificate File    ${USER_HOME}/client_ca_signed-cert.pem
    PycURLLibrary.Private Key File    ${USER_HOME}/client_ca_signed-key.pem
    PycURLLibrary.Request Method    GET
    PycURLLibrary.Perform
    PycURLLibrary.Log Response
    PycURLLibrary.Response Status Should Contain    200
    ${resp}    PycURLLibrary.Response
    Should Contain    ${resp}    "restconf-state":{"capabilities":{"capability":["urn:ietf:params:restconf:capability:depth

Restconf HTTPS/TLS Jolokia with server and client certificates CA signed
    [Documentation]    Tests HTTPS request with ODL TLS config and client authentication by using CA signed certificates for Jolokia
    Clean Up Certificates In Server
    Generate Server CA Signed Certificate
    Generate Client CA Signed Certificate
    #TLS Request
    PycURLLibrary.Set Url    https://${ODL_SYSTEM_IP}:${RESTCONFPORT_TLS}/${JOLOKIA_CONF_SHARD_MANAGER_URI}
    PycURLLibrary.Add Header    "Content-Type:application/json"
    PycURLLibrary.Add Header    Authorization:Basic YWRtaW46YWRtaW4=
    PycURLLibrary.Client Certificate File    ${USER_HOME}/client_ca_signed-cert.pem
    PycURLLibrary.Private Key File    ${USER_HOME}/client_ca_signed-key.pem
    PycURLLibrary.Request Method    GET
    PycURLLibrary.Perform
    PycURLLibrary.Log Response
    PycURLLibrary.Response Status Should Contain    200
    ${resp}    PycURLLibrary.Response
    Should Contain    ${resp}    "request":{"mbean":"org.opendaylight.controller:Category=ShardManager,name=shard-manager-config,type=DistributedConfigDatastore"

*** Keywords ***
Log Certificates in Keystore
    [Documentation]    Shows content of keystore
    ${output}    Run Command On Remote System    ${ODL_SYSTEM_IP}    ${JAVA_HOME}/bin/keytool -list -storepass 123456 -keystore ${KEYSTORE_PATH}
    log    ${output}

Clean Up Certificates In Server
    [Documentation]    Cleans keystore content (only for private keys and trusted certificates)
    Log Certificates in Keystore
    Run Command On Remote System    ${ODL_SYSTEM_IP}    ${JAVA_HOME}/bin/keytool -list -keystore ${KEYSTORE_PATH} -storepass 123456|egrep -e "(trustedCertEntry|PrivateKeyEntry)"|cut -d"," -f1|xargs -I[] ${JAVA_HOME}/bin/keytool -delete -alias [] -keystore ${KEYSTORE_PATH} -storepass 123456
    Log Certificates in Keystore

Generate Server Self-Signed Certificate
    [Documentation]    Generates a self-signed certificate, stores it into keystore and restarts jetty to load changes
    ${KEYSTORE_DIR}=    Split Path    ${KEYSTORE_PATH}
    Run Command On Remote System    ${ODL_SYSTEM_IP}    mkdir -p ${KEYSTORE_DIR[0]}
    Log Certificates in Keystore
    # Generate with openssl
    Run Command On Remote System    ${ODL_SYSTEM_IP}    openssl req -x509 -newkey rsa:4096 -passout pass:myPass -keyout serverkey.pem -out servercert.pem -days 365 -subj "/C=ES/ST=Madrid/L=Madrid/O=OpenDayLight/OU=AAA/CN=OpenDayLight/emailAddress=unknown@unknown.com"
    # Convert to pkcs12 (including public and private key together)
    Run Command On Remote System    ${ODL_SYSTEM_IP}    openssl pkcs12 -export -in servercert.pem -inkey serverkey.pem -out server.p12 -name odl -passin pass:myPass -passout pass:myPass
    # Import Certifcate into keystore
    Run Command On Remote System    ${ODL_SYSTEM_IP}    ${JAVA_HOME}/bin/keytool -importkeystore -deststorepass 123456 -destkeypass myPass -destkeystore ${KEYSTORE_PATH} -srckeystore server.p12 -srcstoretype PKCS12 -srcstorepass myPass -alias odl
    Log Certificates in Keystore
    Restart Jetty

Generate Client Self-Signed Certificate
    [Documentation]    Generates a client self-signed certificate, stores it into the keystore (as trusted cert) and
    ...    restarts jettty to load changes
    ${KEYSTORE_DIR}=    Split Path    ${KEYSTORE_PATH}
    Run Command On Remote System    ${ODL_SYSTEM_IP}    mkdir -p ${KEYSTORE_DIR[0]}
    Log Certificates in Keystore
    # Generate with openssl
    # Note -nodes is used to avoid passphrase in private key. Also -passout pass:myPass is skipped. This is due to a
    # limitation in pycurl library that does not support key pem files with passphrase in automatic mode (it asks for it)
    Run    openssl req -x509 -newkey rsa:4096 -nodes -keyout ${USER_HOME}/clientkey.pem -out ${USER_HOME}/clientcert.pem -days 365 -subj "/C=ES/ST=Madrid/L=Madrid/O=OpenDayLight/OU=AAA/CN=MiguelAngelMunoz/emailAddress=myemail@unknown.com"
    # Import client's cert as trusted
    Copy File To Odl System    ${ODL_SYSTEM_IP}    ${USER_HOME}/clientcert.pem
    Run Command On Remote System    ${ODL_SYSTEM_IP}    ${JAVA_HOME}/bin/keytool -import -trustcacerts -file clientcert.pem -keystore ${KEYSTORE_PATH} -storepass 123456 -noprompt
    Log Certificates in Keystore
    Restart Jetty

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
    Run    openssl pkcs12 -export -in ${USER_HOME}/server.crt -inkey ${USER_HOME}/server.key -out ${USER_HOME}/server.p12 -name odl -passin pass:myPass -passout pass:myPass
    Copy File To Odl System    ${ODL_SYSTEM_IP}    ${USER_HOME}/server.p12
    # Import Certifcate into keystore
    ${KEYSTORE_DIR}=    Split Path    ${KEYSTORE_PATH}
    Run Command On Remote System    ${ODL_SYSTEM_IP}    mkdir -p ${KEYSTORE_DIR[0]}
    Run Command On Remote System    ${ODL_SYSTEM_IP}    ${JAVA_HOME}/bin/keytool -importkeystore -deststorepass 123456 -destkeypass myPass -destkeystore ${KEYSTORE_PATH} -srckeystore ${USER_HOME}/server.p12 -srcstoretype PKCS12 -srcstorepass myPass -alias odl
    Log Certificates in Keystore
    Restart Jetty

Generate Client CA Signed Certificate
    [Documentation]    Generates a client certificate and signs it with own root CA
    #Generates Root CA key and certificate (note this has to be self-signed)
    Log Certificates in Keystore
    Run    openssl genrsa -out ${USER_HOME}/rootCA_for_clients-key.pem 2048
    Run    openssl req -x509 -new -nodes -key ${USER_HOME}/rootCA_for_clients-key.pem -sha256 -days 1024 -out ${USER_HOME}/rootCA_for_clients-cert.pem -subj "/C=ES/ST=Madrid/L=Madrid/O=FakeCA_ForClient/OU=FakeCA_ForClient/CN=www.fakecaforclients.com/emailAddress=unknown@fakecaforclients.com"
    #Generate client CSR
    Run    openssl genrsa -out ${USER_HOME}/client_ca_signed-key.pem 2048
    Run    openssl req -new -key ${USER_HOME}/client_ca_signed-key.pem -out ${USER_HOME}/client_ca_signed.csr -subj "/C=ES/ST=Madrid/L=Madrid/O=OpenDayLight/OU=RestClient/CN=RestClient/emailAddress=unknown@unknownclient.com"
    #Sign CSR
    Run    openssl x509 -req -in ${USER_HOME}/client_ca_signed.csr -CA ${USER_HOME}/rootCA_for_clients-cert.pem -CAkey ${USER_HOME}/rootCA_for_clients-key.pem -CAcreateserial -out ${USER_HOME}/client_ca_signed-cert.pem -days 500 -sha256
    Copy File To Odl System    ${ODL_SYSTEM_IP}    ${USER_HOME}/rootCA_for_clients-cert.pem
    # Import RootCA Certifcate into keystore
    ${KEYSTORE_DIR}=    Split Path    ${KEYSTORE_PATH}
    Run Command On Remote System    ${ODL_SYSTEM_IP}    mkdir -p ${KEYSTORE_DIR[0]}
    Run Command On Remote System    ${ODL_SYSTEM_IP}    ${JAVA_HOME}/bin/keytool -import -trustcacerts -file rootCA_for_clients-cert.pem -keystore ${KEYSTORE_PATH} -storepass 123456 -noprompt
    Log Certificates in Keystore
    Restart Jetty

Disable TLS in ODL
    [Documentation]    Remove TLS configuration in custom.properties
    Run Command On Remote System    ${ODL_SYSTEM_IP}    sed -i '/org.osgi.service.http.secure.enabled=/d' ${CUSTOMPROP}
    Run Command On Remote System    ${ODL_SYSTEM_IP}    sed -i '/org.ops4j.pax.web.ssl.keystore=/d' ${CUSTOMPROP}
    Run Command On Remote System    ${ODL_SYSTEM_IP}    sed -i '/org.ops4j.pax.web.ssl.password=/d' ${CUSTOMPROP}
    Run Command On Remote System    ${ODL_SYSTEM_IP}    sed -i '/org.ops4j.pax.web.ssl.keypassword=/d' ${CUSTOMPROP}
    Run Command On Remote System    ${ODL_SYSTEM_IP}    sed -i '/org.ops4j.pax.web.ssl.clientauthneeded=/d' ${CUSTOMPROP}
    Restart Karaf

Enable TLS in ODL
    [Documentation]    Add new secure configuration in custom.properties
    Run Command On Remote System    ${ODL_SYSTEM_IP}    sed -i '/org.osgi.service.http.secure.enabled=/d' ${CUSTOMPROP}
    Run Command On Remote System    ${ODL_SYSTEM_IP}    sed -i '/org.ops4j.pax.web.ssl.keystore=/d' ${CUSTOMPROP}
    Run Command On Remote System    ${ODL_SYSTEM_IP}    sed -i '/org.ops4j.pax.web.ssl.password=/d' ${CUSTOMPROP}
    Run Command On Remote System    ${ODL_SYSTEM_IP}    sed -i '/org.ops4j.pax.web.ssl.keypassword=/d' ${CUSTOMPROP}
    Run Command On Remote System    ${ODL_SYSTEM_IP}    sed -i '/org.ops4j.pax.web.ssl.clientauthneeded=/d' ${CUSTOMPROP}
    Run Command On Remote System    ${ODL_SYSTEM_IP}    echo "org.osgi.service.http.secure.enabled=true">> ${CUSTOMPROP}
    Run Command On Remote System    ${ODL_SYSTEM_IP}    echo "org.ops4j.pax.web.ssl.keystore=${KEYSTORE_RELATIVE_PATH}">> ${CUSTOMPROP}
    Run Command On Remote System    ${ODL_SYSTEM_IP}    echo "org.ops4j.pax.web.ssl.password=myPass">> ${CUSTOMPROP}
    Run Command On Remote System    ${ODL_SYSTEM_IP}    echo "org.ops4j.pax.web.ssl.keypassword=123456">> ${CUSTOMPROP}
    Restart Karaf

Enable Client TLS Authentication in ODL
    [Documentation]    Add custom.properties configuration to enable client auth
    Run Command On Remote System    ${ODL_SYSTEM_IP}    sed -i '/org.osgi.service.http.secure.enabled=/d' ${CUSTOMPROP}
    Run Command On Remote System    ${ODL_SYSTEM_IP}    sed -i '/org.ops4j.pax.web.ssl.keystore=/d' ${CUSTOMPROP}
    Run Command On Remote System    ${ODL_SYSTEM_IP}    sed -i '/org.ops4j.pax.web.ssl.password=/d' ${CUSTOMPROP}
    Run Command On Remote System    ${ODL_SYSTEM_IP}    sed -i '/org.ops4j.pax.web.ssl.keypassword=/d' ${CUSTOMPROP}
    Run Command On Remote System    ${ODL_SYSTEM_IP}    sed -i '/org.ops4j.pax.web.ssl.clientauthneeded=/d' ${CUSTOMPROP}
    Run Command On Remote System    ${ODL_SYSTEM_IP}    echo "org.osgi.service.http.secure.enabled=true">> ${CUSTOMPROP}
    Run Command On Remote System    ${ODL_SYSTEM_IP}    echo "org.ops4j.pax.web.ssl.keystore=${KEYSTORE_RELATIVE_PATH}">> ${CUSTOMPROP}
    Run Command On Remote System    ${ODL_SYSTEM_IP}    echo "org.ops4j.pax.web.ssl.password=myPass">> ${CUSTOMPROP}
    Run Command On Remote System    ${ODL_SYSTEM_IP}    echo "org.ops4j.pax.web.ssl.keypassword=123456">> ${CUSTOMPROP}
    Run Command On Remote System    ${ODL_SYSTEM_IP}    echo "org.ops4j.pax.web.ssl.clientauthneeded=true">> ${CUSTOMPROP}
    Restart Karaf

Init Suite
    [Documentation]    Cleans TLS configuration and restart Karaf system to reload
    KarafKeywords.Setup Karaf Keywords
    Clean Up Certificates In Server
    Disable TLS in ODL
    Install a Feature    odl-jolokia

Cleanup Suite
    [Documentation]    Deletes pending sessions in case there were any
    Delete All Sessions
