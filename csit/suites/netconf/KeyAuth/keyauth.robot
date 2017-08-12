*** Settings ***
Documentation     Test suite to verify the device mount using public key based auth.
Suite Setup       Suite Setup
Suite Teardown    Suite Teardown
Library           SSHLibrary
Library           RequestsLibrary
Resource          ../../../libraries/SSHKeywords.robot
Resource          ../../../libraries/ClusterManagement.robot
Resource          ../../../variables/Variables.robot
Resource          ${CURDIR}/../../../libraries/NetconfKeywords.robot
Resource          ${CURDIR}/../../../libraries/SetupUtils.robot
Resource          ${CURDIR}/../../../libraries/TemplatedRequests.robot
Variables         ${CURDIR}/../../../variables/Variables.py

*** Variables ***
${pkPassphrase}    topsecret
${directory_with_template_folders}    ${CURDIR}/../../../variables/netconf/CRUD
${device_name}    netconf-test-device
${device_type}    full-uri-device
${netopeer_port}    830
${netopeer_user}    root
${netopeer_pwd}     wrong
${USE_NETCONF_CONNECTOR}    ${False}

*** Test Cases ***
Check_Device_Is_Not_Configured_At_Beginning
    [Documentation]    Sanity check making sure our device is not there. Fail if found.
    NetconfKeywords.Check_Device_Has_No_Netconf_Connector    ${device_name}

Configure_Device_On_Netconf
    [Documentation]    Make request to configure a testtool device on Netconf connector.
    NetconfKeywords.Configure_Device_In_Netconf    ${device_name}    device_type=${device_type}    http_timeout=2    device_user=${netopeer_user}   device_password=${netopeer_pwd}    device_port=${netopeer_port}

Wait_For_Device_To_Become_Connected
    [Documentation]    Wait until the device becomes available through Netconf.
    NetconfKeywords.Wait_Device_Connected    ${device_name}

Deconfigure_Device_From_Netconf
    [Documentation]    Make request to deconfigure the testtool device on Netconf connector.
    [Setup]    SetupUtils.Setup_Test_With_Logging_And_Without_Fast_Failing
    NetconfKeywords.Remove_Device_From_Netconf    ${device_name}

Check_Device_Going_To_Be_Gone_After_Deconfiguring
    [Documentation]    Check that the device is really going to be gone. Fail
    ...    if found after one minute. This is an expected behavior as the
    ...    delete request is sent to the config subsystem which then triggers
    ...    asynchronous destruction of the netconf connector referring to the
    ...    device and the device's data. This test makes sure this
    ...    asynchronous operation does not take unreasonable amount of time
    ...    by making sure that both the netconf connector and the device's
    ...    data is gone before reporting success.
    [Tags]    critical
    NetconfKeywords.Wait_Device_Fully_Removed    ${device_name}

*** Keywords ***
Run Netopeer Docker Container
    [Documentation]    Start a new docker container for netopeer server.
    ${netopeer_conn_id} =    SSHKeywords.Open_Connection_To_Tools_System
    SSHLibrary.Put File    ${CURDIR}/../../../variables/netconf/KeyAuth/datastore.xml    .
    SSHLibrary.Put File    ${CURDIR}/../../../variables/netconf/KeyAuth/sb-rsa-key.pub    .
    Builtin.Set Suite Variable    ${netopeer_conn_id}
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    docker run -dt -p ${netopeer_port}:830 -v ${USER_HOME}/datastore.xml:/usr/local/etc/netopeer/cfgnetopeer/datastore.xml -v ${USER_HOME}/sb-rsa-key.pub:/root/RSA.pub sdnhub/netopeer netopeer-server -v 3    return_stdout=True    return_stderr=True     return_rc=True
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    docker ps    return_stdout=True    return_stderr=True     return_rc=True
    Log    ${stdout}

Configure ODL with Key config
    [Documentation]    Configure the ODL with the Southbound key configuration file containing details about private key path and passphrase
    SSHKeywords.Open_Connection_To_ODL_System
    Log    Bundle folder ${USER_HOME}/${BUNDLEFOLDER}/etc
    SSHLibrary.Put File    ${CURDIR}/../../../variables/netconf/KeyAuth/*    ${USER_HOME}/${BUNDLEFOLDER}/etc/
    SSHLibrary.Execute_Command    chmod 400 ${USER_HOME}/${BUNDLEFOLDER}/etc/sb-rsa-key
    SSHLibrary.Execute_Command    ls -l ${USER_HOME}/${BUNDLEFOLDER}/etc/
ER}/etc
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

Prepare for public key auth
    [Documentation]    Mount the netopeer server which trusts the ODL SB's public key using key based auth.
    # Create the configuration file for netconf sb keypair
    # Place the public key so it can be mounted to netopeer docker container
    Run Netopeer Docker Container
    Configure ODL with Key config

Suite Teardown
    [Documentation]    Tearing down the setup.
    RequestsLibrary.Delete_All_Sessions
    SSHLibrary.Close_All_Connections

Suite Setup
    [Documentation]    Get the suite ready for callhome test cases.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    RequestsLibrary.Create_Session    operational    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}${OPERATIONAL_API}    auth=${AUTH}
    RequestsLibrary.Create_Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}
    NetconfKeywords.Setup_Netconf_Keywords
    ${device_type}=    BuiltIn.Set_Variable_If    """${USE_NETCONF_CONNECTOR}""" == """True"""    default    ${device_type}
    BuiltIn.Set_Suite_Variable    ${device_type}
    Prepare for public key auth
