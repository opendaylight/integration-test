*** Settings ***
Suite Teardown
Default Tags      functional    netconf-performance
Library           OperatingSystem
Library           ../../../libraries/RequestsLibrary.py
Library           DateTime
Library           SSHLibrary    timeout=120s
Library           Collections
Library           ${CURDIR}/../../../libraries/netconf_library.py
Variables         ${CURDIR}/../../../variables/Variables.py
Resource          ../../../variables/netconf_scale/NetScale_variables.robot

*** Variables ***

*** Test Cases ***
Remove Old Plot Data
    [Documentation]    Verifies that plot_data.txt is not present.
    [Tags]    auxiliary    destructive    netconf-scale
    Remove Files    plot_data.txt

Create Connection To Controller
    [Documentation]    Connection used to setup netconf-testtool sem-device configuration file.
    [Tags]    auxiliary
    Open Connection    ${CONTROLLER}    controller
    Login With Public Key    ${CONTROLLER_USER}    ${USER_HOME}/.ssh/${SSH_KEY}, ${KEYFILE_PASS}

Create Connection To Mininet
    [Documentation]    Used to connect to VM and start semulated devices.
    [Tags]    auxiliary
    Open Connection    ${MININET}    mininet
    Login With Public Key    ${MININET_USER}, ${USER_HOME}/.ssh/${SSH_KEY}, ${KEYFILE_PASS}
    #Connect And Log In ODL
    #    [Tags]    auxiliary
    #    Open Connection    ${CONTROLLER}    odlsession
    #    Comment    Login With Public Key    ${user}    /home/${user}/.ssh/${SSH_KEY}    ${KEYFILE_PASS}

Create Config Path If Not Exists
    [Documentation]    Prepare Controller to mount simulated devices
    [Tags]    auxiliary
    Switch Connection    controller
    Execute Command    mkdir -p ${installdir}/etc/opendaylight/karaf/
    Execute Command    mkdir -p ${installdir}${featurepath}
    #Connect And Log In Testtool
    #    [Tags]    auxiliary
    #    Open Connection    ${MININET}
    #    Run Keyword If    "${MININET_PASSWD}"!="rsa_id"    Login    ${MININET_USER}    ${MININET_PASSWD}
    #    Run Keyword If    "${MININET_PASSWD}"=="rsa_id"    SSHLibrary.Login_With_Public_Key    ${MININET_USER}    ${USER_HOME}/.ssh/id_rsa    any

Clear Working Dirs
    [Documentation]    Preparing VM to run netconf-testtool
    [Tags]    auxiliary desctructive
    Switch Connection    mininet
    Clear Temp Dirs

Download Testtool
    [Documentation]    Download Testtool to Mininet VM
    [Tags]    auxiliary
    Execute Command    mkdir -p ${ttlocation}
    ${log}=    Execute Command    rm -r -v ${ttlocation}/*
    Log    ${log}
    ${url}    ${name}=    get_ttool_url
    Should Not Be Empty    ${url}
    Execute Command    wget -t 3 ${url} -P ${ttlocation}
    Execute Command    mv ${ttlocation}/${name} ${ttlocation}/netconf-testtool-0.3.0-SNAPSHOT-executable.jar

Copy Logback
    [Tags]    auxiliary
    SCP Copy    ${PWD}    ${CONTROLLER_USER}@${CONTROLLER}:${installdir}/configuration/logback.xml    ${ttlocation}

Killall Java Testtool
    [Tags]    auxiliary    destructive
    Execute Command    killall java

Copy ODL Files To Mininet
    [Tags]    auxiliary
    Execute Command    mkdir -p ${ttdistribution}${featurepath}features-netconf-connector
    SCP Folder Copy    ${PWD}    ${CONTROLLER_USER}@${CONTROLLER}:${installdir}${featurepath}features-netconf-connector    ${ttdistribution}${featurepath}

Setup Testtool
    [Tags]    auxiliary
    Log Many    Testtool command: ${ttstartcommand}    Testtool location: ${ttlocation}
    Start Command    ${ttstartcommand} &> ${ttlocation}/testtool.log
    Sleep    60s
    #    Close Connection

Copy ODL Device Config
    [Tags]    auxiliary    destructive
    #    Open Connection    ${MININET}
    #    Run Keyword If    "${MININET_PASSWD}"!="rsa_id"    Login    ${MININET_USER}    ${MININET_PASSWD}
    #    Run Keyword If    "${MININET_PASSWD}"=="rsa_id"    SSHLibrary.Login_With_Public_Key    ${MININET_USER}    ${USER_HOME}/.ssh/id_rsa    any
    #    Wait Until Keyword Succeeds    120s    1s    Check If Dir Contains File    ${ttdistribution}/etc/opendaylight/karaf    simulated-devices
    #    Sleep    15s
    Switch Connection    controller
    SCP Copy    ${PWD}    ${MININET_USER}@${MININET}:${ttdistribution}/etc/opendaylight/karaf/simulated-devices*    ${installdir}/etc/opendaylight/karaf/
    SCP Folder Copy    ${PWD}    ${MININET_USER}@${MININET}:${ttdistribution}${featurepath}/features-netconf-connector    ${installdir}${featurepath}
    #    Close Connection

Define Ses
    [Tags]    auxiliary
    Create Session    ses    http://${CONTROLLER}:${RESTCONFPORT}

Start ODL
    [Tags]    auxiliary
    Execute Command    rm ${installdir}/data/log/karaf*
    Log    ${startcommand}
    Start Command    ${startcommand}
    ${timestamp}=    Get Current Date
    @{tuple}=    Create List    ${timestamp}    0    Starting ODL
    Append To List    ${Timestamps}    ${tuple}
    Close Connection
    Wait Until Keyword Succeeds    10m    5s    Poll ODL
    ${odlisuptime}=    Get Current Date
    ${timestamp}=    Get Current Date
    ${delta}=    Subtract Date From Date    ${timestamp}    ${Timestamps[-1][0]}
    @{tuple}=    Create List    ${odlisuptime}    ${delta}    ODL Started
    Append To List    ${Timestamps}    ${tuple}
    Log    ${Timestamps}
    [Teardown]    Run Keyword If Test Failed    Fatal Error    ODL Start Failed

Find PID Of Karaf
    [Tags]    auxiliary
    ${karafpid}=    Execute Command    /usr/sbin/pidof java
    Set Global Variable    ${karafpid}
    Log    ${karafpid}

Check sim-devices
    Set Global Variable    ${Maxdevices}    0
    Set Global Variable    ${error}    true
    Wait Until Keyword Succeeds    30m    5s    Simdevices
    Set Global Variable    ${error}    false
    ${timestamp}=    Get Current Date
    ${delta}=    Subtract Date From Date    ${timestamp}    ${Timestamps[-1][0]}
    @{tuple}=    Create List    ${timestamp}    ${delta}    All devices connected
    Append To List    ${Timestamps}    ${tuple}

Check mount-points
    Run Keyword If    "${error}"=="false"    Check Mount Points

Check Number Of Missing Devices
    [Documentation]    Check if all devices was connected during test
    [Tags]    auxiliary
    Should Be Equal As Integers    ${missing}    0

Copy Logs
    [Documentation]    Copies log files form both VMs.
    [Tags]    auxiliary
    Switch Connection    controller
    SSHLibrary.Get File    ${installdir}/data/log/karaf*    ${CURDIR}/log/
    Switch Connection    mininet
    SSHLibrary.Get File    ${ttlocation}/testtool.log    ${CURDIR}/log/testtool.log

Log Timestamps
    [Tags]    auxiliary
    Log List    ${Timestamps}
    Log List    ${Partialtimestamps}

Create Plot Data
    [Documentation]    Creates Data necessary to plot performance results
    [Tags]    auxiliary
    Should Not Be True    ${missing}>${DevicesTolerance}
    Run    echo ODL Start,Connecting Devices,ODL+Connect,Mountpoints Check>plot_data.txt
    ${sum}=    Evaluate    ${Timestamps[1][1]}+${Timestamps[2][1]}
    Run    echo ${Timestamps[1][1]},${Timestamps[2][1]},${sum},${Timestamps[3][1]}>>plot_data.txt

Close All Connections
    [Documentation]    Close Controller and Mininet connections
    [Tags]    auxiliary    destructive
    Get Connections
    Close All Connections

*** Keywords ***
Check Mount Points
    : FOR    ${dev}    IN RANGE    ${startport}    ${startport}+${ttnumberofdevices}
    \    Log    ${dev}
    \    ${uri}=    Set Variable    /restconf/operational/opendaylight-inventory:nodes/node/${dev}-sim-device/yang-ext:mount
    \    Log    ${uri}
    \    ${rsp}=    GET    ses    ${uri}
    \    Log Many    ${rsp.status_code}    ${rsp.text}
    \    @{tuple}=    Create List    Device: ${dev}-sim-device    Reply code: ${rsp.status_code}
    \    Append To List    ${Replycodes}    ${tuple}
    \    Run Keyword If    ${rsp.status_code}==200    Inc Mountpoints
    Log List    ${Replycodes}
    Log    ${Mountpoints}
    ${missingmounted}=    Evaluate    ${ttnumberofdevices}-${Mountpoints}
    Run Keyword If    ${Mountpoints}!=${ttnumberofdevices}    Log    Number of not mounted devices: ${missingmounted}    level=WARN
    Should Be True    ${Mountpoints}+${missingmounted}==${ttnumberofdevices}
    ${timestamp}=    Get Current Date
    ${delta}=    Subtract Date From Date    ${timestamp}    ${Timestamps[-1][0]}
    @{tuple}=    Create List    ${timestamp}    ${delta}    All mountpoints checked
    Append To List    ${Timestamps}    ${tuple}

Inc Mountpoints
    ${Mountpoints}=    Evaluate    ${Mountpoints}+1
    Set Global Variable    ${Mountpoints}

Simdevices
    ${url}=    Set Variable    http://${CONTROLLER}:${RESTCONFPORT}/restconf/operational/opendaylight-inventory:nodes
    ${timestamp}    Get Current Date
    ${cfgcon}    ${numdev}    ${numcon}    ${rspcode}    ${rsplen}=    get_num_of_connected    ${url}
    ${netstatdev}=    Execute Command    netstat -an \| grep ${MININET} \| grep ESTABLISHED \| wc -l
    ${odlmem}=    Execute Command    top -b -n1 -p ${karafpid} \| grep java \| tr -s " " \| sed -e 's/^ *//' \| cut -d " " -f 6
    ${odlcpu}=    Execute Command    top -b -n1 -p ${karafpid} \| grep java \| tr -s " " \| sed -e 's/^ *//' \| cut -d " " -f 9
    Log Many    ${timestamp}    ${cfgcon}    ${netstatdev}    ${numdev}    ${numcon}    ${rspcode}
    ...    ${rsplen}
    @{tuple}=    Create List    Time: ${timestamp}    Controller-config Connected: ${cfgcon}    Netstat Connections: ${netstatdev}    Restconf Devices: ${numdev}    Connected Restconf Devices: ${numcon}
    ...    Response Code: ${rspcode}    Response Length: ${rsplen}    Memory Usage: ${odlmem}    CPU Usage: ${odlcpu}
    Append To List    ${Partialtimestamps}    ${tuple}
    Log List    ${Partialtimestamps}
    Run Keyword If    ${Maxdevices}>${numcon}    Fatal Error    Something goes wrong
    Set Global Variable    ${Maxdevices}    ${numcon}
    ${missing}=    Evaluate    ${ttnumberofdevices}-${numcon}
    Set Global Variable    ${missing}
    Should Be True    ${numcon}>${ttnumberofdevices}-${DevicesTolerance}-1
    Run Keyword If    ${numcon}!=${ttnumberofdevices}    Log    Number of not connected devices: ${missing}    level=WARN

Check If Dir Contains File
    [Arguments]    ${Dir}    ${File}
    @{files}=    SSHLibrary.List Files In Directory    ${Dir}
    Log Many    ${Dir}    ${File}    @{files}
    Should Contain    repr(@{files})    ${File}

Poll ODL
    ${reply}=    Run Keyword    GET    ses    /restconf/operational/opendaylight-inventory:nodes/node/controller-config/yang-ext:mount/config:modules
    Should Be Equal As Integers    ${reply.status_code}    200

SCP Copy
    [Arguments]    ${remotepassword}    ${source}    ${dest}
    Write    scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${source} ${dest}
    Read Until    ${prompt}

SCP Folder Copy
    [Arguments]    ${remotepassword}    ${source}    ${dest}
    Write    scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -r ${source} ${dest}
    Read Until    ${prompt}

Mininet Cleanup
    Open Connection    ${MININET}
    Run Keyword If    "${MININET_PASSWD}"!="rsa_id"    Login    ${MININET_USER}    ${MININET_PASSWD}
    Run Keyword If    "${MININET_PASSWD}"=="rsa_id"    SSHLibrary.Login_With_Public_Key    ${MININET_USER}    ${USER_HOME}/.ssh/id_rsa    any
    Execute Command    killall java
    Clear Temp Dirs
    Get Connections
    Close All Connections

Clear Temp Dirs
    Execute Command    rm -r ${ttlocation}
    Execute Command    rm -r ${ttdistribution}

Run Command On Remote System
    [Arguments]    ${remote_system}    ${cmd}    ${user}=${MININET_USER}    ${prompt}=${DEFAULT_LINUX_PROMPT}    ${prompt_timeout}=30s
    [Documentation]    Reduces the common work of running a command on a remote system to a single higher level \ \ robot keyword, taking care to log in with a public key and. The command given is written \ and the output returned. No test conditions are checked.
    Log    Attempting to execute ${cmd} on ${remote_system} by ${user} with ${keyfile_pass} and ${prompt}
    ${conn_id}=    SSHLibrary.Open Connection    ${remote_system}    prompt=${prompt}    timeout=${prompt_timeout}
    Login With Public Key    ${user}    ${USER_HOME}/.ssh/${SSH_KEY}    ${KEYFILE_PASS}
    SSHLibrary.Write    ${cmd}
    ${output}=    SSHLibrary.Read Until    ${prompt}
    SSHLibrary.Close Connection
    Log    ${output}
