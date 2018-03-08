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
Resource          ${CURDIR}/../../../libraries/CompareStream.robot
Resource          ${CURDIR}/../../../variables/Variables.robot

*** Variables ***
${directory_with_keyauth_template}    ${CURDIR}/../../../variables/netconf/KeyAuth
${pkPassphrase}    topsecret
${device_name}    netconf-test-device
${device_type_passw}    full-uri-device
${device_type_key}    full-uri-device-key
${netopeer_port}    830
${netopeer_user}    root
${netopeer_pwd}    wrong
${netopeer_key}    device-key
${USE_NETCONF_CONNECTOR}    ${False}

*** Test Cases ***
Check_Device_Is_Not_Configured_At_Beginning
    [Documentation]    Sanity check making sure our device is not there. Fail if found.
    Wait Until Keyword Succeeds    5x    20    NetconfKeywords.Check_Device_Has_No_Netconf_Connector    ${device_name}

Configure_Device_On_Netconf
    [Documentation]    Make request to configure netconf netopeer with wrong password. Correct auth is root/root
    ...    ODL should connect to device using public key auth as password auth will fail.
    NetconfKeywords.Configure_Device_In_Netconf    ${device_name}    device_type=${device_type}    http_timeout=2    device_user=${netopeer_user}    device_password=${netopeer_pwd}    device_port=${netopeer_port}
    ...    device_key=${netopeer_key}

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
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    docker run -dt -p ${netopeer_port}:830 -v ${USER_HOME}/datastore.xml:/usr/local/etc/netopeer/cfgnetopeer/datastore.xml -v ${USER_HOME}/sb-rsa-key.pub:/root/RSA.pub sdnhub/netopeer netopeer-server -v 3    return_stdout=True    return_stderr=True
    ...    return_rc=True
    ${stdout}    ${stderr}    ${rc}=    SSHLibrary.Execute Command    docker ps    return_stdout=True    return_stderr=True
    ...    return_rc=True
    Log    ${stdout}

Configure ODL with Key config
    [Documentation]    Configure the ODL with the Southbound key configuration file containing details about private key path and passphrase
    SSHKeywords.Open_Connection_To_ODL_System
    Log    Bundle folder ${WORKSPACE}/${BUNDLEFOLDER}/etc
    SSHLibrary.Put File    ${CURDIR}/../../../variables/netconf/KeyAuth/org.opendaylight.netconf.topology.sb.keypair.cfg    ${WORKSPACE}/${BUNDLEFOLDER}/etc/
    SSHLibrary.Put File    ${CURDIR}/../../../variables/netconf/KeyAuth/sb-rsa-key    ${WORKSPACE}/${BUNDLEFOLDER}/etc/    400
    ${stdout}=    SSHLibrary.Execute Command    ls -l ${WORKSPACE}/${BUNDLEFOLDER}/etc/    return_stdout=True
    Log    ${stdout}
    Restart Controller

Add Netconf Key
    [Documentation]    Add Netconf Southbound key containing details about device private key and passphrase
    ${mapping}=    BuiltIn.Create_dictionary    DEVICE_KEY=${netopeer_key}
    TemplatedRequests.Post_As_Xml_Templated    folder=${directory_with_keyauth_template}    mapping=${mapping}

Restart Controller
    [Documentation]    Controller restart is needed in order the new shiro.ini config takes effect
    ClusterManagement.ClusterManagement_Setup
    Wait Until Keyword Succeeds    5x    20    Stop_Single_Member    1
    Start_Single_Member    1    wait_for_sync=False    timeout=120
    Wait Until Keyword Succeeds    30x    5s    Get Controller Modules

Get Controller Modules
    [Documentation]    Get the restconf modules, check 200 status and ietf-restconf presence
    ${resp} =    RequestsLibrary.Get_Request    default    ${MODULES_API}
    BuiltIn.Log    ${resp.content}
    BuiltIn.Should_Be_Equal    ${resp.status_code}    ${200}
    BuiltIn.Should_Contain    ${resp.content}    ietf-restconf

Suite Teardown
    [Documentation]    Tearing down the setup.
    RequestsLibrary.Delete_All_Sessions
    SSHLibrary.Close_All_Connections

Suite Setup
    [Documentation]    Get the suite ready for callhome test cases.
    SetupUtils.Setup_Utils_For_Setup_And_Teardown
    NetconfKeywords.Setup_Netconf_Keywords
    ${device_type_passw}=    BuiltIn.Set_Variable_If    """${USE_NETCONF_CONNECTOR}""" == """True"""    default    ${device_type_passw}
    ${device_type}    CompareStream.Set_Variable_If_At_Most_Nitrogen    ${device_type_passw}    ${device_type_key}
    BuiltIn.Set_Suite_Variable    ${device_type}
    Run Netopeer Docker Container
    CompareStream.Run_Keyword_If_At_Most_Nitrogen    Configure ODL with Key config
    CompareStream.Run_Keyword_If_At_Least_Oxygen    Add Netconf Key
