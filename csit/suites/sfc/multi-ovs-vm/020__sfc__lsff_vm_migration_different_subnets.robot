*** Settings ***
Documentation     Test suite for SFC Service Functions, Operates functions from Restconf APIs
...               Test The Logical SFF end to end traffic (using 'dovs' simulated neutron network)
...               Test traffic in two Service Function Chains, each SFs in a different subnet
...               Test traffic after moving one VM to other compute node
...
...               Every VM in a different subnet
Suite Setup       Init Suite
Suite Teardown    Cleanup Suite
Test Timeout      45 minutes
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Library           ../../../libraries/SFC/SfcUtils.py
Variables         ../../../variables/Variables.py
Resource          ../../../variables/sfc/Variables.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/TemplatedRequests.robot
Resource          ../../../libraries/KarafKeywords.robot
Resource          ../../../libraries/SFC/DockerSfc.robot

*** Variables ***
${CREATE_RSP1_INPUT}    {"input":{"parent-service-function-path":"SFP1","name":"RSP1"}}
${CREATE_RSP_FAILURE_INPUT}    {"input":{"parent-service-function-path":"SFC1-empty","name":"RSP1-empty-Path-1"}}

*** Test Cases ***
Test Traffic in two Service Function Chains
    [Documentation]    Test traffic involving two Service Function Chains
    ...    Test Traffic involving one Service Function Chain and VM migration
    [Timeout]    5 minutes
    ${result}    SSHLibrary.Execute Command    cd sfc-docker/sf_hhe/logical_sff;sudo ./test_case_01_traffic_different_subnet.sh -o ${ODL_SYSTEM_IP} > >(tee myFile.log) 2> >(tee myFile.log)    return_stderr=True    return_stdout=True    return_rc=True
    ${result1}    convert to string    ${result}
    log    ${result1}
    ${result}    SSHLibrary.Execute Command    sudo modinfo openvswitch > >(tee myFile.log) 2> >(tee myFile.log)
    log    ${result}
    ${result}    SSHLibrary.Execute Command    ls -la /lib/modules/3.10.0-514.2.2.el7.x86_64/extra/openvswitch.ko > >(tee myFile.log) 2> >(tee myFile.log)
    log    ${result}
    ${result}    SSHLibrary.Execute Command    sudo ls -la /lib/modules/ > >(tee myFile.log) 2> >(tee myFile.log)
    log    ${result}
    ${result}    SSHLibrary.Execute Command    sudo lsmod > >(tee myFile.log) 2> >(tee myFile.log)
    log    ${result}
    Should be equal as integers    ${result[2]}    0

*** Keywords ***
Post Elements To URI As JSON
    [Arguments]    ${uri}    ${data}
    ${resp}    RequestsLibrary.Post Request    session    ${uri}    data=${data}    headers=${headers}
    Should Contain    ${ALLOWED_STATUS_CODES}    ${resp.status_code}

Get JSON Elements From URI
    [Arguments]    ${uri}
    ${resp}    RequestsLibrary.Get Request    session    ${uri}
    ${value}    To Json    ${resp.content}
    [Return]    ${value}

Check Classifier Flows
    ${flowList}=    DockerSfc.Get Flows In Docker Containers
    log    ${flowList}
    Should Contain Match    ${flowList}    *actions=pop_nsh*
    Should Contain Match    ${flowList}    *actions=push_nsh*

Switch Ips In Json Files
    [Arguments]    ${json_dir}    ${container_names}
    ${normalized_dir}=    OperatingSystem.Normalize Path    ${json_dir}/*.json
    : FOR    ${cont_name}    IN    @{container_names}
    \    ${cont_ip}=    Get Docker IP    ${cont_name}
    \    OperatingSystem.Run    sudo sed -i 's/${cont_name}/${cont_ip}/g' ${normalized_dir}

Init Suite
    [Documentation]    Connect Create session and initialize ODL version specific variables
    SSHLibrary.Open Connection    ${TOOLS_SYSTEM_IP}    timeout=3s
    ${result} =    Run Command On Remote System    ${ODL_SYSTEM_IP}    cat /etc/hosts    ${ODL_SYSTEM_USER}    prompt=${ODL_SYSTEM_PROMPT}
    Log    ${result}
    ${result}    SSHLibrary.Execute Command    cat /etc/hosts    return_stderr=True    return_stdout=True    return_rc=True
    log    ${result}
    ${result}    OperatingSystem.Run    cat /etc/hosts
    log    ${result}
    Utils.Flexible Mininet Login
    ${docker_cidr}=    DockerSfc.Get Docker Bridge Subnet
    ${docker_nw}=    SfcUtils.Get Network From Cidr    ${docker_cidr}
    ${docker_mask}=    SfcUtils.Get Mask From Cidr    ${docker_cidr}
    ${nwbrmgmt}    SSHLibrary.Execute Command    sudo ip a show dovs-mgmt|grep dovs-mgmt|grep inet|awk '{ print $2 }' \ > >(tee myFile.log) 2> >(tee myFile.log)
    ${route_to_docker_net}=    Set Variable    sudo route add -net ${nwbrmgmt} netmask ${docker_mask} gw ${TOOLS_SYSTEM_IP}
    Run Command On Remote System    ${ODL_SYSTEM_IP}    ${route_to_docker_net}    ${ODL_SYSTEM_USER}    prompt=${ODL_SYSTEM_PROMPT}
    SSHLibrary.Put Directory    ${CURDIR}/sfc-docker    .    mode=0755    recursive=True
    ${result}    SSHLibrary.Execute Command    cd sfc-docker/provision;sudo ./setup_ovs.sh > >(tee myFile.log) 2> >(tee myFile.log)    return_stderr=True    return_stdout=True    return_rc=True
    log    ${result}
    Should be equal as integers    ${result[2]}    0
    ${result}    SSHLibrary.Execute Command    cd sfc-docker/provision;sudo ./setup_ovs_docker.sh > >(tee myFile.log) 2> >(tee myFile.log)    return_stderr=True    return_stdout=True    return_rc=True
    log    ${result}
    Should be equal as integers    ${result[2]}    0
    ${result}    SSHLibrary.Execute Command    cd sfc-docker/provision;sudo ./setup_dovs_network.sh > >(tee myFile.log) 2> >(tee myFile.log)    return_stderr=True    return_stdout=True    return_rc=True
    log    ${result}
    Should be equal as integers    ${result[2]}    0
    ${result}    SSHLibrary.Execute Command    cd sfc-docker/provision;sudo ./setup_dovs.sh > >(tee myFile.log) 2> >(tee myFile.log)    return_stderr=True    return_stdout=True    return_rc=True
    log    ${result}
    Should be equal as integers    ${result[2]}    0
    ${result}    SSHLibrary.Execute Command    cd sfc-docker/provision;chmod 777 setup_sf_hhe.sh;sudo ./setup_sf_hhe.sh > >(tee myFile.log) 2> >(tee myFile.log)    return_stderr=True    return_stdout=True    return_rc=True
    log    ${result}
    Should be equal as integers    ${result[2]}    0
    ${result}    SSHLibrary.Execute Command    sudo ip a show docker0 > >(tee myFile.log) 2> >(tee myFile.log)    return_stderr=True    return_stdout=True    return_rc=True
    log    ${result}
    Should be equal as integers    ${result[2]}    0
    ${result}    SSHLibrary.Execute Command    sudo ip a \ > >(tee myFile.log) 2> >(tee myFile.log)    return_stderr=True    return_stdout=True    return_rc=True
    log    ${result}
    Should be equal as integers    ${result[2]}    0
    ${result}    SSHLibrary.Execute Command    sudo modinfo openvswitch > >(tee myFile.log) 2> >(tee myFile.log)    return_stderr=True    return_stdout=True    return_rc=True
    log    ${result}
    ${result}    SSHLibrary.Execute Command    ls -la /lib/modules/3.10.0-514.2.2.el7.x86_64/extra/openvswitch.ko > >(tee myFile.log) 2> >(tee myFile.log)    return_stderr=True    return_stdout=True    return_rc=True
    log    ${result}
    ${result}    SSHLibrary.Execute Command    sudo ls -la /lib/modules/ > >(tee myFile.log) 2> >(tee myFile.log)    return_stderr=True    return_stdout=True    return_rc=True
    log    ${result}
    ${result}    SSHLibrary.Execute Command    sudo lsmod > >(tee myFile.log) 2> >(tee myFile.log)    return_stderr=True    return_stdout=True    return_rc=True
    log    ${result}
    ${nwbrmgmt}    SSHLibrary.Execute Command    sudo ip a show dovs-mgmt|grep dovs-mgmt|grep inet|awk '{ print $2 }' \ > >(tee myFile.log) 2> >(tee myFile.log)
    ${nw_brmgmt}    SfcUtils.Get Network From Cidr    ${nwbrmgmt}
    ${route_to_docker_net}=    Set Variable    sudo route add -net ${nw_brmgmt} netmask ${docker_mask} gw ${TOOLS_SYSTEM_IP}
    Run Command On Remote System    ${ODL_SYSTEM_IP}    ${route_to_docker_net}    ${ODL_SYSTEM_USER}    prompt=${ODL_SYSTEM_PROMPT}
    ${route_to_docker_net}=    Set Variable    sudo route add -net 172.19.0.0 netmask ${docker_mask} gw ${TOOLS_SYSTEM_IP}
    Run Command On Remote System    ${ODL_SYSTEM_IP}    ${route_to_docker_net}    ${ODL_SYSTEM_USER}    prompt=${ODL_SYSTEM_PROMPT}

Cleanup Suite
    [Documentation]    Clean up all docker containers created and delete sessions
    ${result}    SSHLibrary.Execute Command    cd sfc-docker/sf_hhe/logical_sff;sudo cat myFile.log    return_stderr=True    return_stdout=True    return_rc=True
    ${result1}    convert to string    ${result}
    log    ${result1}
    Should be equal as integers    ${result[2]}    0
    Remove All Elements At URI    ${SERVICE_CLASSIFIERS_URI}
    Remove All Elements At URI    ${SERVICE_FUNCTION_ACLS_URI}
    Remove All Elements At URI    ${SERVICE_FUNCTIONS_URI}
    Remove All Elements At URI    ${SERVICE_FORWARDERS_URI}
    Remove All Elements At URI    ${SERVICE_NODES_URI}
    Remove All Elements At URI    ${SERVICE_CHAINS_URI}
    Remove All Elements At URI    ${SERVICE_FUNCTION_PATHS_URI}
    Remove All Elements At URI    ${SERVICE_METADATA_URI}
    DockerSfc.Docker Ovs Clean    log_file=myFile4.log
    Delete All Sessions
    SSHLibrary.Close Connection
