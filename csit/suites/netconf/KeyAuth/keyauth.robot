*** Settings ***
Documentation     Test suite to verify the device mount using public key based auth.
Suite Setup       Suite Setup
Suite Teardown    Suite Teardown
Library           SSHLibrary
Library           RequestsLibrary
Resource          ../../../libraries/SSHKeywords.robot
Resource          ../../../libraries/ClusterManagement.robot
Resource          ../../../variables/Variables.robot

*** Variables ***
${pkPassphrase}   topsecret

*** Test Cases ***
Mount netconf using public key auth
    [Documentation]    Mount the netopeer server which trusts the ODL SB's public key using key based auth.
    # Create the configuration file for netconf sb keypair
    # SSHLibrary.Put_File    ${CURDIR}/Counter.py    ${target_dir}/
    # Place the public key so it can be mounted to netopeer docker container
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    ls -l    return_stdout=True    return_stderr=True
    ...    return_rc=True

*** Keywords ***

Run Netopeer Docker Container
    [Documentation]    Install docker-compose on tools system.
    ${netopeer_conn_id} =    SSHKeywords.Open_Connection_To_Tools_System
    SSHLibrary.Put File    ${CURDIR}/../../../variables/netconf/KeyAuth/datastore.xml    .
    SSHLibrary.Put File    ${CURDIR}/../../../variables/netconf/KeyAuth/sb-rsa-key.pub    .
    Builtin.Set Suite Variable    ${netopeer_conn_id}
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    docker run -dt -p 830:830 -v ${USER_HOME}/datastore.xml:/usr/local/etc/netopeer/cfgnetopeer/datastore.xml -v ${USER_HOME}/RSA.pub:/root/RSA.pub sdnhub/netopeer netopeer-server -v 3
    ...    return_stdout=True    return_stderr=True    return_rc=True

Configure ODL with Key config
    [Documentation]    Configure the ODL with the Southbound key configuration file containing details about private key path and passphrase
    SSHKeywords.Open_Connection_To_ODL_System
    Log    Bundle folder ${USER_HOME}/${BUNDLEFOLDER}/etc
    SSHLibrary.Put File   ${CURDIR}/../../../variables/netconf/KeyAuth/sb-rsa-key    ${USER_HOME}/${BUNDLEFOLDER}/etc    mode=400
    SSHLibrary.Put File   ${CURDIR}/../../../variables/netconf/KeyAuth/org.opendaylight.netconf.topology.sb.keypair.cfg    ${USER_HOME}/${BUNDLE_FOLDER}/etc     mode=664
    Restart Controller

Restart Controller
    [Documentation]    Controller restart is needed in order the new shiro.ini config takes effect
    ClusterManagement.ClusterManagement_Setup
    Wait Until Keyword Succeeds    5x    20    Stop_Single_Member    1
    Start_Single_Member    1    wait_for_sync=False    timeout=120
    Wait Until Keyword Succeeds    30x    5s    Get Controller Modules

Get Controller Modules
    [Documentation]    Get the restconf modules, check 200 status and ietf-restconf presence
    Create Session    session1    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
    ${resp} =    RequestsLibrary.Get_Request    session1    ${MODULES_API}
    BuiltIn.Log    ${resp.content}
    BuiltIn.Should_Be_Equal    ${resp.status_code}    ${200}
    BuiltIn.Should_Contain    ${resp.content}    ietf-restconf

Suite Teardown
    [Documentation]    Tearing down the setup.
    RequestsLibrary.Delete_All_Sessions
    SSHLibrary.Close_All_Connections

Suite Setup
    [Documentation]    Get the suite ready for callhome test cases.
    RequestsLibrary.Create_Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
    Run Netopeer Docker Container
    Configure ODL with Key config
