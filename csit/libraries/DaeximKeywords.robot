*** Settings ***
Library           OperatingSystem
Library           SSHLibrary
Library           Collections
Library           RequestsLibrary
Resource          ClusterManagement.robot
Resource          ../variables/daexim/DaeximVariables.robot
Resource          ../variables/Variables.robot
Resource          SSHKeywords.robot
Resource          OpenStackOperations.robot
Resource          BgpOperations.robot

*** Keywords ***
Verify Export Files
    [Arguments]    ${host_index}
    [Documentation]    Verify if the backedup files are present in the controller
    ${host_index}    Builtin.Convert To Integer    ${host_index}
    ${cfg}    ClusterManagement.Run Bash Command On Member    ls -lart ${WORKSPACE}/${BUNDLEFOLDER}/daexim/${EXP_DATA_FILE}    ${host_index}
    Builtin.Log    ${cfg}
    Builtin.Should Match Regexp    ${cfg}    .*${EXP_DATA_FILE}
    ${mdl}    ClusterManagement.Run Bash Command On Member    ls -lart ${WORKSPACE}/${BUNDLEFOLDER}/daexim/${MODELS_FILE}    ${host_index}
    Builtin.Log    ${mdl}
    Builtin.Should Match Regexp    ${mdl}    .*${MODELS_FILE}
    ${opr}    ClusterManagement.Run Bash Command On Member    ls -lart ${WORKSPACE}/${BUNDLEFOLDER}/daexim/${EXP_OPER_FILE}    ${host_index}
    Builtin.Log    ${opr}
    Builtin.Should Match Regexp    ${opr}    .*${EXP_OPER_FILE}

Cleanup The Export Files
    [Arguments]    ${host_index}
    [Documentation]    Verify if the export directory exists and delete the files if needed
    ${host_index}    Builtin.Convert To Integer    ${host_index}
    Builtin.Run Keyword And Ignore Error    ClusterManagement.Delete_And_Check_Member_List_Or_All    ${TOPOLOGY_URL}    ${host_index}
    ${output1}    Builtin.Run Keyword and IgnoreError    ClusterManagement.Run Bash Command On Member    sudo rm -rf ${WORKSPACE}/${BUNDLEFOLDER}/daexim;clear    ${host_index}
    ${output2}    Builtin.Run Keyword and IgnoreError    ClusterManagement.Run Bash Command On Member    rm -rf ${WORKSPACE}/${BUNDLEFOLDER}/daexim;clear    ${host_index}
    ${output}    ClusterManagement.Run Bash Command On Member    ls -lart ${WORKSPACE}/${BUNDLEFOLDER}    ${host_index}
    Builtin.Log    ${output}
    Builtin.Should Not Match Regexp    ${output}    daexim

Verify Export Status
    [Arguments]    ${status}    ${controller_index}
    [Documentation]    Verify export status is as expected
    ${response_json}    ClusterManagement.Post_As_Json_To_Member    ${STATUS_EXPORT_URL}    ${EMPTY}    ${controller_index}
    Builtin.Log    ${response_json}
    ${response_json}    Builtin.Convert To String    ${response_json}
    Verify Export Status Message    ${status}    ${response_json}

Verify Scheduled Export Timestamp
    [Arguments]    ${controller_index}    ${time}
    [Documentation]    Verify export timestamp is as expected
    ${response_json}    ClusterManagement.Post_As_Json_To_Member    ${STATUS_EXPORT_URL}    ${EMPTY}    ${controller_index}
    Builtin.Log    ${response_json}
    ${response_json}    Builtin.Convert To String    ${response_json}
    Builtin.Should Match Regexp    ${response_json}    .*"run-at": "${time}"

Verify Export Status Message
    [Arguments]    ${status}    ${output}
    [Documentation]    Verify export restconf response message is as expected
    Builtin.Should Match Regexp    ${output}    "status": "${status}"
    Builtin.Run Keyword If    "${status}" == "initial" or "${status}" == "scheduled"    Verify Json Files Not Present    ${output}
    ...    ELSE    Verify Json Files Present    ${output}

Verify Json Files Present
    [Arguments]    ${output}    ${config_json}=${EXP_DATA_FILE}    ${models_json}=${MODELS_FILE}    ${operational_json}=${EXP_OPER_FILE}
    [Documentation]    Verify if the json files are generated after a export/export
    Builtin.Should Match Regexp    ${output}    .*${config_json}
    Builtin.Should Match Regexp    ${output}    .*${models_json}
    Builtin.Should Match Regexp    ${output}    .*${operational_json}
    Builtin.Log    Found all Json Files

Verify Json Files Not Present
    [Arguments]    ${output}    ${config_json}=${EXP_DATA_FILE}    ${models_json}=${MODELS_FILE}    ${operational_json}=${EXP_OPER_FILE}
    [Documentation]    Verify if the json files are not present under the daexim folder
    Builtin.Should Not Match Regexp    ${output}    .*${config_json}
    Builtin.Should Not Match Regexp    ${output}    .*${models_json}
    Builtin.Should Not Match Regexp    ${output}    .*${operational_json}
    Builtin.Log    Did not Find all Json Files

Schedule Export
    [Arguments]    ${controller_index}    ${TIME}=500    ${exclude}=${FALSE}    ${MODULE}=${EMPTY}    ${STORE}=${EMPTY}
    [Documentation]    Schedule Export job
    ${file}    Builtin.Set Variable If    ${exclude}    ${EXPORT_EXCLUDE_FILE}    ${EXPORT_FILE}
    ${JSON1}    OperatingSystem.Get File    ${file}
    ${JSON2}    Builtin.Replace Variables    ${JSON1}
    Cleanup The Export Files    ${controller_index}
    ${response_json}    ClusterManagement.Post_As_Json_To_Member    ${SCHEDULE_EXPORT_URL}    ${JSON2}    ${controller_index}
    Builtin.Log    ${response_json}

Schedule Exclude Export
    [Arguments]    ${controller_index}    ${store}    ${module}
    [Documentation]    Schedules a export with exclude option. Returns the file that has the excluded export.
    ${controller_index}    Builtin.Convert To Integer    ${controller_index}
    ${host}    ClusterManagement.Resolve IP Address For Member    ${controller_index}
    Schedule Export    ${controller_index}    500    ${TRUE}    ${module}    ${store}
    Builtin.Wait Until Keyword Succeeds    10 sec    5 sec    Verify Export Status    complete    ${controller_index}
    Verify Export Files    ${controller_index}
    Copy Export Directory To Test VM    ${host}
    ${export_file}    Builtin.Set Variable If    '${store}' == 'operational'    ${EXP_OPER_FILE}    ${EXP_DATA_FILE}
    ${file_path}    OperatingSystem.Join Path    ${EXP_DIR}${host}    ${export_file}
    [Return]    ${file_path}

Cancel Export
    [Arguments]    ${controller_index}
    [Documentation]    Cancel the export job
    ${response_json}    ClusterManagement.Post_As_Json_To_Member    ${CANCEL_EXPORT_URL}    ${EMPTY}    ${controller_index}
    Builtin.Log    ${response_json}

Return ConnnectionID
    [Arguments]    ${system}=${ODL_SYSTEM_IP}    ${prompt}=${DEFAULT_LINUX_PROMPT}    ${prompt_timeout}=${DEFAULT_TIMEOUT}    ${user}=${ODL_SYSTEM_USER}    ${password}=${ODL_SYSTEM_PASSWORD}
    [Documentation]    Returns the connection of any host. Defaults to controller
    ${conn_id}    SSHLibrary.Open Connection    ${system}    prompt=${prompt}    timeout=${prompt_timeout}
    SSHKeywords.Flexible SSH Login    ${user}    ${password}
    [Return]    ${conn_id}

Cleanup Directory
    [Arguments]    ${dir}
    [Documentation]    Cleans up the given directory if it exists
    OperatingSystem.Empty Directory    ${dir}
    OperatingSystem.Remove Directory    ${dir}

Copy Export Directory To Test VM
    [Arguments]    ${host}
    [Documentation]    This keyword copies the daexim folder genereated in the controller to robot vm. This is done to editing if needed on the json files
    ${new_dir}    Builtin.Set Variable    ${EXP_DIR}${host}
    ${directory_exist}    Builtin.Run Keyword And Return Status    OperatingSystem.Directory Should Exist    ${new_dir}
    Builtin.Run Keyword If    ${directory_exist}    Cleanup Directory    ${new_dir}
    ${connections}    Return ConnnectionID    ${host}
    SSHLibrary.Switch Connection    ${connections}
    SSHLibrary.Directory Should Exist    ${WORKSPACE}/${BUNDLEFOLDER}/daexim
    SSHLibrary.Get Directory    ${WORKSPACE}/${BUNDLEFOLDER}/daexim    ${new_dir}
    SSHLibrary.Close Connection
    ${output}    OperatingSystem.List Files In Directory    ${new_dir}
    Builtin.Log    ${output}
    ${fl}    OperatingSystem.Get File    ${new_dir}/${EXP_DATA_FILE}
    Builtin.Log    ${fl}

Copy Config Data To Controller
    [Arguments]    ${host_index}
    [Documentation]    This keyword copies the daexim folder under variables folder to the Controller
    ${host_index}    Builtin.Convert To Integer    ${host_index}
    ${host}    ClusterManagement.Resolve IP Address For Member    ${host_index}
    ${connections}    Return ConnnectionID    ${host}
    SSHLibrary.Switch Connection    ${connections}
    SSHLibrary.Put Directory    ${CURDIR}/${DAEXIM_DATA_DIRECTORY}    ${WORKSPACE}/${BUNDLEFOLDER}/    mode=664
    SSHLibrary.Close Connection

Mount Netconf Endpoint
    [Arguments]    ${endpoint}    ${host_index}
    [Documentation]    Mount a netconf endpoint
    ${ENDPOINT}    Builtin.Set Variable    ${endpoint}
    ${JSON1}    OperatingSystem.Get File    ${CURDIR}/${NETCONF_PAYLOAD_JSON}
    ${JSON2}    Builtin.Replace Variables    ${JSON1}
    Builtin.Log    ${JSON2}
    ${resp}    ClusterManagement.Put_As_Json_To_Member    ${NETCONF_MOUNT_URL}${endpoint}    ${JSON2}    ${host_index}
    Builtin.Log    ${resp}

Fetch Status Information From Netconf Endpoint
    [Arguments]    ${endpoint}    ${host_index}
    [Documentation]    This keyword fetches netconf endpoint information
    ${resp}    ClusterManagement.Get_From_Member    ${NTCF_TPLG_OPR_URL}${endpoint}    ${host_index}
    ${output1}    Builtin.Set Variable    ${resp}
    ${output}    RequestsLibrary.To Json    ${output1}
    Builtin.Log    ${output}
    ${status}    Collections.Get From Dictionary    ${output['node'][0]}    netconf-node-topology:connection-status
    [Return]    ${status}    ${output}

Verify Status Information
    [Arguments]    ${endpoint}    ${host_index}    ${itr}=50
    [Documentation]    Verify if a netconf endpoint status is connected by running in a loop
    : FOR    ${i}    IN RANGE    ${itr}
    \    ${sts}    ${op}    Fetch Status Information From Netconf Endpoint    ${endpoint}    ${host_index}
    \    Builtin.Log    ${i}
    \    Builtin.Exit For Loop If    "${sts}" == "${NTCF_OPR_STATUS}"
    [Return]    ${sts}    ${op}

Verify Netconf Mount
    [Arguments]    ${endpoint}    ${host_index}
    [Documentation]    Verify if a netconf endpoint is mounted
    ${sts1}    ${output}    Verify Status Information    ${endpoint}    ${host_index}
    ${ep}    Collections.Get From Dictionary    ${output['node'][0]}    node-id
    ${port}    Collections.Get From Dictionary    ${output['node'][0]}    netconf-node-topology:port
    ${port}    Builtin.Convert To String    ${port}
    Builtin.Should Be Equal    ${endpoint}    ${ep}
    Builtin.Should Be Equal    ${port}    ${NETCONF_PORT}

Schedule Import
    [Arguments]    ${host_index}    ${result}=true    ${reason}=${EMPTY}    ${mdlflag}=${MDL_DEF_FLAG}    ${strflag}=${STR_DEF_FLAG}
    [Documentation]    Schedule an Import API
    ${MODELFLAG}    Builtin.Set Variable    ${mdlflag}
    ${STOREFLAG}    Builtin.Set Variable    ${strflag}
    ${JSON1}    OperatingSystem.Get File    ${CURDIR}/${IMPORT_PAYLOAD}
    ${JSON2}    Builtin.Replace Variables    ${JSON1}
    Builtin.Log    ${JSON2}
    ${resp}    Builtin.Wait Until Keyword Succeeds    120 seconds    10 seconds    ClusterManagement.Post_As_Json_To_Member    ${IMPORT_URL}    ${JSON2}
    ...    ${host_index}
    Builtin.Log    ${resp}
    Builtin.Should Match Regexp    ${resp}    .*"result": ${result}
    Builtin.Run Keyword If    "${reason}" != "${EMPTY}"    Builtin.Should Match Regexp    ${response_json}    .*"reason":"${reason}

ELAN Functionality Verification
    [Documentation]    This Keyword Verifies VMs mac address in flows and ping between VMs.
    ${SRCMAC_CN1} =    Create List    ${VM_MACAddr_ELAN1[0]}    ${VM_MACAddr_ELAN1[1]}    ${VM_MACAddr_ELAN1[2]}    ${VM_MACAddr_ELAN1[3]}    ${VM_MACAddr_ELAN1[4]}
    ...    ${VM_MACAddr_ELAN1[5]}    ${VM_MACAddr_ELAN1[6]}    ${VM_MACAddr_ELAN1[7]}    ${VM_MACAddr_ELAN1[8]}    ${VM_MACAddr_ELAN1[9]}
    ${SRCMAC_CN2} =    Create List    ${VM_MACAddr_ELAN2[0]}    ${VM_MACAddr_ELAN2[1]}    ${VM_MACAddr_ELAN2[2]}    ${VM_MACAddr_ELAN2[3]}    ${VM_MACAddr_ELAN2[4]}
    ...    ${VM_MACAddr_ELAN2[5]}    ${VM_MACAddr_ELAN2[6]}    ${VM_MACAddr_ELAN2[7]}    ${VM_MACAddr_ELAN2[8]}    ${VM_MACAddr_ELAN2[9]}
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present For ELAN Service    ${OS_COMPUTE_1_IP}    ${SRCMAC_CN1}    ${VM_MACAddr_ELAN1}
    Wait Until Keyword Succeeds    30s    5s    Verify Flows Are Present For ELAN Service    ${OS_COMPUTE_2_IP}    ${SRCMAC_CN2}    ${VM_MACAddr_ELAN1}
    Log    <<Verify Datapath Test>>
    : FOR    ${list}    IN RANGE    0    10
    \    ${output} =    Execute Command on VM Instance    ${Networks[${list}]}    ${VM_IP_ELAN1[${list}]}    ping -c 3 ${VM_IP_ELAN2[${list}]}
    \    Should Contain    ${output}    ${PING_PASS}
    \    ${output} =    Execute Command on VM Instance    ${Networks[${list}]}    ${VM_IP_ELAN2[${list}]}    ping -c 3 ${VM_IP_ELAN1[${list}]}
    \    Should Contain    ${output}    ${PING_PASS}

Create Setup With 20 VMs
    [Documentation]    This Keyword creates setup with 10 Networks,10 Subnets,20 Neutron ports,20 Vms \ and quota update accordingly.
    log    >>>creating ITM tunnel
    Comment    Check ITM Tunnel and Configure
    Comment    @{araay}    create list    goto_table:36
    Comment    DaeximKeywords1.Table Check    ${conn_id_1}    ${br_name}    table=0    ${araay}
    log    <<quata update>>
    @{quota_update}    create list    openstack quota set --instances 20    openstack quota set --cores 48    openstack quota set --ram 102400    openstack quota set --network -1    openstack quota set --subnet -1
    ...    openstack quota set --port -1
    : FOR    ${list}    IN    ${quota_update}
    \    VM Creation Quota Update    ${list}
    Log    >>>> Creating 10 Network <<<<
    : FOR    ${list}    IN RANGE    0    10
    \    Wait Until Keyword Succeeds    60 sec    10 Sec    Create Network    ${Networks[${list}]}
    Log    >>>> Creating 10 \ subnets <<<<
    : FOR    ${list}    IN RANGE    0    10
    \    Wait Until Keyword Succeeds    60 sec    10 Sec    Create SubNet    ${Networks[${list}]}    ${V4subnet_Names[${list}]}
    \    ...    ${V4subnets[${list}]}/16    --enable-dhcp
    Log    >>>> Creating 20 neutron ports and associating to each network <<<<
    : FOR    ${list}    IN RANGE    0    10
    \    Wait Until Keyword Succeeds    60 sec    10 Sec    Create Port    ${Networks[${list}]}    ${port_name[${list}]}
    : FOR    ${list}    IN RANGE    0    10
    \    Wait Until Keyword Succeeds    60 sec    10 Sec    Create Port    ${Networks[${list}]}    ${port_name1[${list}]}
    Log    >>>> Creating 20 VMs<<<<
    : FOR    ${list}    IN RANGE    0    10
    \    Wait Until Keyword Succeeds    60 sec    10 Sec    Create Vm Instance With Port On Compute Node    ${port_name[${list}]}    ${VM_list[${list}]}
    \    ...    ${OS_COMPUTE_1_IP}
    : FOR    ${list}    IN RANGE    0    10
    \    Wait Until Keyword Succeeds    60 sec    10 Sec    Create Vm Instance With Port On Compute Node    ${port_name1[${list}]}    ${VM_list1[${list}]}
    \    ...    ${OS_COMPUTE_2_IP}
    Log    <<Verify VMs are Active>>
    : FOR    ${VM}    IN RANGE    0    10
    \    Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${VM_list[${list}]}
    : FOR    ${VM}    IN RANGE    0    10
    \    Wait Until Keyword Succeeds    25s    5s    Verify VM Is ACTIVE    ${VM_list1[${list}]}
    Log    <<Get IP address for ELAN1>>
    Wait Until Keyword Succeeds    180s    10s    Collect VM IP Addresses    true    ${VM_list}
    ${VM_IP_ELAN1}    ${DHCP_IP_ELAN1}    Collect VM IP Addresses    false    ${VM_list}
    Log    ${VM_IP_ELAN1}
    Set Suite Variable    ${VM_IP_ELAN1}
    Log    <<Get MACAddr for ELAN1>>
    ${VM_MACAddr_ELAN1}    Wait Until Keyword Succeeds    30s    10s    Get Ports MacAddr    ${port_name}
    Log    ${VM_MACAddr_ELAN1}
    Set Suite Variable    ${VM_MACAddr_ELAN1}
    Log    <<Get IP address for ELAN2>>
    Wait Until Keyword Succeeds    180s    10s    Collect VM IP Addresses    true    ${VM_list1}
    ${VM_IP_ELAN2}    ${DHCP_IP_ELAN2}    Collect VM IP Addresses    false    ${VM_list1}
    Log    ${VM_IP_ELAN2}
    Set Suite Variable    ${VM_IP_ELAN2}
    Log    <<Get MACAddr for ELAN2>>
    ${VM_MACAddr_ELAN2}    Wait Until Keyword Succeeds    30s    10s    Get Ports MacAddr    ${port_name1}
    Log    ${VM_MACAddr_ELAN2}
    Set Suite Variable    ${VM_MACAddr_ELAN2}

Data Export Import Process
    [Documentation]    This Keyword performs SBI/NBI Port block,data export/Import,compare backup json after daexim.
    Log    <<Blocking SBI/NBI Ports>>
    ${host_index}    Builtin.Convert To Integer    ${FIRST_CONTROLLER_INDEX}
    Builtin.Run Keyword And Ignore Error    ClusterManagement.Delete_And_Check_Member_List_Or_All    ${TOPOLOGY_URL}    ${host_index}
    ${output1}    Builtin.Run Keyword and IgnoreError    ClusterManagement.Run Bash Command On Member    sudo /sbin/iptables -A INPUT -p tcp --destination-port ${block_port} -j DROP ${WORKSPACE}/${BUNDLEFOLDER}/    ${host_index}
    ${output2}    Builtin.Run Keyword and IgnoreError    ClusterManagement.Run Bash Command On Member    /sbin/iptables -A INPUT -p tcp --destination-port ${block_port} -j DROP ${WORKSPACE}/${BUNDLEFOLDER}/    ${host_index}
    ${output1}    Builtin.Run Keyword and IgnoreError    ClusterManagement.Run Bash Command On Member    sudo /sbin/iptables -A INPUT -p tcp --destination-port ${block_port1} -j DROP ${WORKSPACE}/${BUNDLEFOLDER}/    ${host_index}
    ${output2}    Builtin.Run Keyword and IgnoreError    ClusterManagement.Run Bash Command On Member    /sbin/iptables -A INPUT -p tcp --destination-port ${block_port1} -j DROP ${WORKSPACE}/${BUNDLEFOLDER}/    ${host_index}
    log    <<Verifying the blocked port status>>
    Wait Until Keyword Succeeds    3 min    30s    Verify SBI NBI Block Port Status    ${host_index}    down
    log    <<Export Config>>
    DaeximKeywords.Mount Netconf Endpoint    ${NETCONF_EP_NAME}    ${FIRST_CONTROLLER_INDEX}
    DaeximKeywords.Schedule Export    ${FIRST_CONTROLLER_INDEX}
    ${Time_taken}    Time Calculation For Given Task    DaeximKeywords.Verify Export Status    ${EXPORT_SCHEDULED_STATUS}    ${FIRST_CONTROLLER_INDEX}
    log    ${Time_taken} in sec
    Builtin.Wait Until Keyword Succeeds    10 sec    5 sec    DaeximKeywords.Verify Export Status    ${EXPORT_COMPLETE_STATUS}    ${FIRST_CONTROLLER_INDEX}
    DaeximKeywords.Verify Export Files    ${FIRST_CONTROLLER_INDEX}
    DaeximKeywords.Verify Netconf Mount    ${NETCONF_EP_NAME}    ${FIRST_CONTROLLER_INDEX}
    log    <<Taking backup \ B0>>
    ${output1}    Builtin.Run Keyword and IgnoreError    ClusterManagement.Run Bash Command On Member    sudo mkdir backupdaexim ${WORKSPACE}    ${host_index}
    ${output2}    Builtin.Run Keyword and IgnoreError    ClusterManagement.Run Bash Command On Member    mkdir backupdaexim ${WORKSPACE}    ${host_index}
    Config Backup For Compare    odl_backup_config_elan_b0.json
    log    <<Stop all controllers>>
    ClusterManagement.Stop_Members_From_List_Or_All
    log    <<Cleanup Controller>>
    Clean_Journals_And_Snapshots_On_List_Or_All
    ${index_list} =    List_Indices_Or_All    given_list=${member_index_list}
    ${command} =    Set Variable    rm -rf "${karaf_home}/data"
    : FOR    ${index}    IN    @{index_list}    # usually: 1, 2, 3.
    \    Run_Bash_Command_On_Member    command=${command}    member_index=${index}
    log    <<Cluster configuration>>
    : FOR    ${index}    IN    @{index_list}    # usually: 1, 2, 3.
    \    ${output1}    Builtin.Run Keyword and IgnoreError    ClusterManagement.Run Bash Command On Member    sudo ./configure_cluster.sh ${index} ${ODL_SYSTEM_1_IP} ${ODL_SYSTEM_2_IP} ${ODL_SYSTEM_3_IP} ${WORKSPACE}/${BUNDLEFOLDER}/bin/    ${host_index}
    \    ${output2}    Builtin.Run Keyword and IgnoreError    ClusterManagement.Run Bash Command On Member    ./configure_cluster.sh ${index} ${ODL_SYSTEM_1_IP} ${ODL_SYSTEM_2_IP} ${ODL_SYSTEM_3_IP} ${WORKSPACE}/${BUNDLEFOLDER}/bin/    ${host_index}
    log    <<Start Cluster>>
    ClusterManagement.Start_Members_From_List_Or_All
    Check_Cluster_Is_In_Sync
    ${Time_taken}    Time Calculation For Given Task    DaeximKeywords.Schedule Import    ${FIRST_CONTROLLER_INDEX}
    log    ${Time_taken} in sec
    Builtin.Wait Until Keyword Succeeds    30 sec    5 sec    DaeximKeywords.Verify Netconf Mount    ${NETCONF_EP_NAME}    ${FIRST_CONTROLLER_INDEX}
    log    <<Cleanup the Daexim Folder>>
    DaeximKeywords.Cleanup The Export Files    ${FIRST_CONTROLLER_INDEX}
    ${NETCONF_EP_NAME}    ${FIRST_CONTROLLER_INDEX}
    DaeximKeywords.Schedule Export    ${FIRST_CONTROLLER_INDEX}
    ${Time_taken}    Time Calculation For Given Task    DaeximKeywords.Verify Export Status    ${EXPORT_SCHEDULED_STATUS}    ${FIRST_CONTROLLER_INDEX}
    log    ${Time_taken} in sec
    Builtin.Wait Until Keyword Succeeds    10 sec    5 sec    DaeximKeywords.Verify Export Status    ${EXPORT_COMPLETE_STATUS}    ${FIRST_CONTROLLER_INDEX}
    DaeximKeywords.Verify Export Files    ${FIRST_CONTROLLER_INDEX}
    DaeximKeywords.Verify Netconf Mount    ${NETCONF_EP_NAME}    ${FIRST_CONTROLLER_INDEX}
    log    <<Taking backup \ B1>>
    Config Backup For Compare    odl_backup_config_elan_b1.json
    log    <<Unblocking the SBI and NBI ports>>
    ${output1}    Builtin.Run Keyword and IgnoreError    ClusterManagement.Run Bash Command On Member    sudo iptables -F \ ${WORKSPACE}/${BUNDLEFOLDER}/    ${host_index}
    ${output2}    Builtin.Run Keyword and IgnoreError    ClusterManagement.Run Bash Command On Member    iptables -F \ ${WORKSPACE}/${BUNDLEFOLDER}/    ${host_index}
    log    <<Verifying the blocked port status>>
    Wait Until Keyword Succeeds    3 min    30s    Verify SBI NBI Block Port Status    ${host_index}    up
    log    <<Comparing backup json whether the backup file \ contains VMIPs>>
    Comparing Backup JSON    ${DAEXIM_DATA_DIRECTORY}/backupdaexim/odl_backup_config_elan_b0.json    ${DAEXIM_DATA_DIRECTORY}/backupdaexim/odl_backup_config_elan_b1.json    ${VM_IP_ELAN1}    ${VM_IP_ELAN1}

Verify SBI NBI Block Port Status
    [Arguments]    ${host_index}    ${flag}
    [Documentation]    This Keyword Verifies SBI/NBI port status after blocking and unblocking.
    @{plist}    create list    ${block_port}    ${block_port1}
    : FOR    ${list}    IN    @{plist}
    \    ${netns_verifying}    Builtin.Run Keyword and IgnoreError    ClusterManagement.Run Bash Command On Member    sudo \ ${block_cmd} ${list} \ ${WORKSPACE}/${BUNDLEFOLDER}/    ${host_index}
    \    ${netns_verifying}    Builtin.Run Keyword and IgnoreError    ClusterManagement.Run Bash Command On Member    ${block_cmd} ${list} \ ${WORKSPACE}/${BUNDLEFOLDER}/    ${host_index}
    \    log    ${netns_verifying}
    \    should contain    ${netns_verifying}    LISTEN
    \    Run Keyword If    '${flag}' == 'down'    Should Not Contain    ${netns_verifying}    ESTABLISHED
    \    Run Keyword If    '${flag}' == 'up'    should contain    ${netns_verifying}    ESTABLISHED
    [Teardown]

Time Calculation For Given Task
    [Arguments]    ${Task}    ${*args}
    [Documentation]    This Keyword measure and returns the time taken for the given task.
    ${date1}    Get Current Date
    log    ${date1}
    ${time1}    Should Match Regexp    ${date1}    [0-9]+\:[0-9]+\:[0-9]+\.[0-9]+
    log    ${time1}
    Run Keyword    ${Task}
    ${date2}    Get Current Date
    log    ${date2}
    ${time2}    Should Match Regexp    ${date2}    [0-9]+\:[0-9]+\:[0-9]+\.[0-9]+
    log    ${time2}
    ${time-diff}    Subtract Time From Time    ${time2}    ${time1}
    log    ${time-diff} in seconds

Comparing Backup JSON
    [Arguments]    ${backuppath1}    ${backuppath2}    @{parameter1}    @{parameter2}
    [Documentation]    This Keyword Compares config backup JSON files.
    log    <<Comparing the Json backup files>>
    : FOR    ${list}    IN RANGE    0    10
    \    log    <<Comparing the B0 and B1>>
    \    SSHLibrary.Get Directory    ${WORKSPACE}/backupdaexim    ${DAEXIM_DATA_DIRECTORY}/backupdaexim
    \    ${file_B0}    OperatingSystem.Get File    ${backuppath1}
    \    log    ${file_B0}
    \    ${count_B0}    get count    ${file_B0}    ${parameter1[${list}]}
    \    log    ${count_B0}
    \    ${file_B1}    OperatingSystem.Get File    ${backuppath2}
    \    log    ${file_B1}
    \    ${count_B1}    get count    ${file_B1}    ${parameter2[${list}]}
    \    log    ${count_B1}
    \    ${compare_B0_B1}    Should Be Equal As Numbers    ${count_B0}    ${count_B1}
    \    log    ${compare_B0_B1}
    : FOR    ${list}    IN RANGE    0    10
    \    log    <<Comparing the B0 and B1>>
    \    ${file_B0}    OperatingSystem.Get File    ${backuppath1}
    \    log    ${file_B0}
    \    ${count_B0}    get count    ${file_B0}    ${parameter1[${list}]}
    \    log    ${count_B0}
    \    ${file_B1}    OperatingSystem.Get File    ${backuppath2}
    \    log    ${file_B1}
    \    ${count_B1}    get count    ${file_B1}    ${parameter2[${list}]}
    \    log    ${count_B1}
    \    ${compare_B0_B1}    Should Be Equal As Numbers    ${count_B0}    ${count_B1}
    \    log    ${compare_B0_B1}

Config Backup For Compare
    [Arguments]    ${filename}
    ${output1}    Builtin.Run Keyword and IgnoreError    ClusterManagement.Run Bash Command On Member    sudo cp ${WORKSPACE}/${BUNDLEFOLDER}/daexim/odl_backup_config.json \ \ ${WORKSPACE}/backupdaexim/${filename}    ${host_index}
    ${output2}    Builtin.Run Keyword and IgnoreError    ClusterManagement.Run Bash Command On Member    cp ${WORKSPACE}/${BUNDLEFOLDER}/daexim/odl_backup_config.json \ \ ${WORKSPACE}/backupdaexim/${filename}    ${host_index}
    ${cfg}    ClusterManagement.Run Bash Command On Member    ls -lart ${WORKSPACE}/backupdaexim    ${host_index}
    Builtin.Log    ${cfg}
    should contain    ${cfg}    ${filename}
