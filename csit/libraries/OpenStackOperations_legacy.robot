*** Settings ***
Documentation     Openstack library. This library is useful for tests to create network, subnet, router and vm instances
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Library           SSHLibrary
Resource          DataModels.robot
Resource          DevstackUtils.robot
Resource          L2GatewayOperations.robot
Resource          SetupUtils.robot
Resource          SSHKeywords.robot
Resource          Utils.robot
Resource          ../variables/Variables.robot
Resource          ../variables/netvirt/Variables.robot
Variables         ../variables/netvirt/Modules.py


*** Keywords ***



Collect VM IP Addresses
    [Arguments]    ${fail_on_none}    @{vm_list}
    [Documentation]    Using the console-log on the provided ${vm_list} to search for the string "obtained" which
    ...    correlates to the instance receiving it's IP address via DHCP. Also retrieved is the ip of the nameserver
    ...    if available in the console-log output. The keyword will also return a list of the learned ips as it
    ...    finds them in the console log output, and will have "None" for Vms that no ip was found.
    ${ip_list}    Create List    @{EMPTY}
    : FOR    ${vm}    IN    @{vm_list}
    \    ${rc}    ${vm_ip_line}=    Run And Return Rc And Output    openstack console log show ${vm} | grep -i "obtained"
    \    @{vm_ip}    Get Regexp Matches    ${vm_ip_line}    [0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}
    \    ${vm_ip_length}    Get Length    ${vm_ip}
    \    Run Keyword If    ${vm_ip_length}>0    Append To List    ${ip_list}    @{vm_ip}[0]
    \    ...    ELSE    Append To List    ${ip_list}    None
    \    ${rc}    ${dhcp_ip_line}=    Run And Return Rc And Output    openstack console log show ${vm} | grep "^nameserver"
    \    ${dhcp_ip}    Get Regexp Matches    ${dhcp_ip_line}    [0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}
    \    ${dhcp_ip_length}    Get Length    ${dhcp_ip}
    \    Run Keyword If    ${dhcp_ip_length}<=0    Append To List    ${dhcp_ip}    None
    \    ${vm_console_output}=    Run    openstack console log show ${vm}
    \    Log    ${vm_console_output}
    ${dhcp_length}    Get Length    ${dhcp_ip}
    Run Keyword If    '${fail_on_none}' == 'true'    Should Not Contain    ${ip_list}    None
    Run Keyword If    '${fail_on_none}' == 'true'    Should Not Contain    ${dhcp_ip}    None
    Return From Keyword If    ${dhcp_length}==0    ${ip_list}    ${EMPTY}
    [Return]    ${ip_list}    ${dhcp_ip}

Collect IP
    [Arguments]    ${VM_Name}
    ${rc}    ${vm_ip_line}=    Run And Return Rc And Output    openstack server list | grep -i "${VM_Name}"
    ${vm_ip}    Get Regexp Matches    ${vm_ip_line}    [0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}
    [Return]    ${vm_ip}

Get ComputeNode Connection
    [Arguments]    ${compute_ip}
    ${compute_conn_id}=    SSHLibrary.Open Connection    ${compute_ip}    prompt=]>
    SSHKeywords.Flexible SSH Login    ${OS_USER}    ${DEVSTACK_SYSTEM_PASSWORD}
    SSHLibrary.Set Client Configuration    timeout=30s
    [Return]    ${compute_conn_id}

Verify VM UP Status
    [Arguments]    ${vm_name}
    [Documentation]    Run these commands to check whether the created vm instance is ready to login.
    ${output}=    Run And Return Rc And Output    openstack console log show ${vm_name}
    #${status}=    encode('utf-8').${output}
    #${status}=    Decode Bytes To String    ${output}   UTF-8
    #Log    ${status}
    #Should Contain    ${status}    finished at
    Sleep   500s

Poll VM UP Boot Status
    [Arguments]    ${vm_name}    ${retry}=1800s    ${retry_interval}=5s
    [Documentation]    Run these commands to check whether the created vm instance is active or not.
    Wait Until Keyword Succeeds    ${retry}    ${retry_interval}    Verify VM UP Status    ${vm_name}

Create ANY SecurityGroup Rule
    [Arguments]    ${sg_name}    ${dir}    ${ether_type}=IPv4    ${additional_args}=${EMPTY}
    [Documentation]    Create Security Group Rule without Protocol
    ${rc}    ${output}=    Run And Return Rc And Output    neutron security-group-rule-create ${sg_name} --direction ${dir} ${additional_args}
    Log    ${output}
    Should Not Be True    ${rc}

Create Availabilityzone
    [Arguments]    ${hypervisor_ip}    ${zone_name}    ${aggregate_name}
    [Documentation]    Creates the Availabilityzone for given host IP
    ${hostname}=    Get Hypervisor Hostname From IP    ${hypervisor_ip}
    ${rc}    ${output}=    Run And Return Rc And Output    openstack aggregate create --zone ${zone_name} ${aggregate_name}
    Log    ${output}
    ${rc}    ${output}=    Run And Return Rc And Output    openstack aggregate add host ${aggregate_name} ${hostname}
    Should Not Be True    ${rc}
    [Return]    ${zone_name}

Delete Availabilityzone
    [Arguments]    ${hypervisor_ip}    ${aggregate_name}
    [Documentation]    Removes the Availabilityzone for given host IP
    ${hostname}=    Get Hypervisor Hostname From IP    ${hypervisor_ip}
    ${rc}    ${output}=    Run And Return Rc And Output    openstack aggregate remove host ${aggregate_name} ${hostname}
    Log    ${output}
    ${rc}    ${output}=    Run And Return Rc And Output    openstack aggregate delete ${aggregate_name}
    Log    ${output}
    Should Not Be True    ${rc}

Ssh From VM Instance Should Not Succeed
    [Arguments]    ${vm_ip}    ${user}=cirros    ${password}=cubswin:)
    [Documentation]    Login to the vm instance using ssh from another VM instance
    Log    ${vm_ip}
    ${output}=    Write Commands Until Expected Prompt    ssh ${user}@${vm_ip}    ${OS_SYSTEM_PROMPT}    timeout=90s
    Should Contain Any    ${output}    Connection timed out    No route to host
    Log    ${output}


Ssh From VM Instance
    [Arguments]    ${vm_ip}    ${user}=cirros    ${password}=cubswin:)    ${first_login}=True
    [Documentation]    Login to the vm instance using ssh from another VM instance
    Log    ${vm_ip}
    ${output} =    Run Keyword If    "${first_login}" == "True"    Write Commands Until Expected Prompt    ssh ${user}@${vm_ip}    (y/n)
    ...   ELSE    Write Commands Until Expected Prompt    ssh ${user}@${vm_ip}    password:
    Log    ${output}
    ${output} =    Run Keyword If    "${first_login}" == "True"    Write Commands Until Expected Prompt    y    password:
    Log    ${output}
    ${output} =    Write Commands Until Expected Prompt    ${password}    $
    Log    ${output}
    ${rcode} =    Run Keyword And Return Status    Check If Console Is VmInstance
    ${output} =    Write Commands Until Expected Prompt    ifconfig    $
    Should Contain    ${output}    ${vm_ip}
    ${output} =    Write Commands Until Expected Prompt    exit    $
    [Return]    ${output}
