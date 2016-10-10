*** Settings ***
Documentation     Test suite for SFC Backup & Restore. Checks that backup and restory is working as expected
Suite Setup       Init Suite
Suite Teardown    Cleanup Suite
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Library           HttpLibrary.HTTP
Library           DateTime
Library           ../../../libraries/SFC/SfcUtils.py
Variables         ../../../variables/Variables.py
Resource          ../../../variables/sfc/Variables.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/TemplatedRequests.robot
Resource          ../../../libraries/ClusterManagement.robot

*** Test Cases ***
Basic Environment Setup Tests
    [Documentation]    Prepare Basic Test Environment
    Create Session In Controller    ${ODL_SYSTEM_IP}
    ${timestamp}    Get Current Date    result_format=epoch
    Set Suite Variable    ${backup_file}    /tmp/sfc_redundancy-${timestamp}.tar.gz
    ClusterManagement_Setup
    Add SFC Elements
    Validate Persistency

Kill Karaf And Backup Karaf Data
    [Documentation]    Stop Karaf and Backup the karaf persistent information. Start karaf and check that no configuration is present
    Kill_Members_From_List_Or_All
    Backup Karaf Data
    Clean_Journals_And_Snapshots_On_List_Or_All
    Start_Members_From_List_Or_All
    BuiltIn.Sleep    10
    Validate Empty Configuration

Restore Karaf Data and Check Configuration
    [Documentation]    Stop Karaf and Restore the karaf persistent information. Check that configuration is present
    Kill_Members_From_List_Or_All
    Restore Karaf Data
    Start_Members_From_List_Or_All
    BuiltIn.Sleep    10
    Validate Persistency

*** Keywords ***
Init Suite
    [Documentation]    Connect Create session and initialize ODL version specific variables
    log    ${ODL_STREAM}
    Create Session In Controller    ${ODL_SYSTEM_IP}
    Run Keyword If    '${ODL_STREAM}' == 'stable-lithium'    Set Suite Variable    ${VERSION_DIR}    lithium
    ...    ELSE    Set Suite Variable    ${VERSION_DIR}    master
    ${JSON_DIR}=    Set Variable    ${CURDIR}/../../../variables/sfc/${VERSION_DIR}/redundancy
    Set Suite Variable    ${SERVICE_FUNCTIONS_FILE}    ${JSON_DIR}/service-functions.json
    Set Suite Variable    ${SERVICE_FORWARDERS_FILE}    ${JSON_DIR}/service-function-forwarders.json
    Set Suite Variable    ${SERVICE_NODES_FILE}    ${JSON_DIR}/service-nodes.json
    Set Suite Variable    ${SERVICE_CHAINS_FILE}    ${JSON_DIR}/service-function-chains.json
    Set Suite Variable    ${SERVICE_FUNCTION_PATHS_FILE}    ${JSON_DIR}/service-function-paths.json

Backup Karaf Data
    [Documentation]    Backups folders journal and snapshots under the KARAF_HOME folder
    ${command}=    Set Variable    tar zcvf ${backup_file} ${KARAF_HOME}/snapshots/ ${KARAF_HOME}/journal/
    ${output}=    Run_Bash_Command_On_List_Or_All    ${command}

Restore Karaf Data
    [Documentation]    Restores folders journal and snapshots under the KARAF_HOME folder from existing backup file
    ${command}=    Set Variable    sudo tar zxvf ${backup_file} -C /
    ${output}=    Run_Bash_Command_On_List_Or_All    ${command}

Add SFC Elements
    [Documentation]    Add Elements to the Controller via API REST
    Add Elements To URI From File    ${SERVICE_FORWARDERS_URI}    ${SERVICE_FORWARDERS_FILE}
    Add Elements To URI From File    ${SERVICE_NODES_URI}    ${SERVICE_NODES_FILE}
    Add Elements To URI From File    ${SERVICE_FUNCTIONS_URI}    ${SERVICE_FUNCTIONS_FILE}
    Add Elements To URI From File    ${SERVICE_CHAINS_URI}    ${SERVICE_CHAINS_FILE}
    Add Elements To URI From File    ${SERVICE_FUNCTION_PATHS_URI}    ${SERVICE_FUNCTION_PATHS_FILE}

Remove SFC Elements
    [Documentation]    Remove Elements from the Controller via API REST
    Remove All Elements At URI    ${SERVICE_FUNCTIONS_URI}
    Remove All Elements At URI    ${SERVICE_FORWARDERS_URI}
    Remove All Elements At URI    ${SERVICE_NODES_URI}
    Remove All Elements At URI    ${SERVICE_CHAINS_URI}
    Remove All Elements At URI    ${SERVICE_FUNCTION_PATHS_URI}

Validate Empty Configuration
    [Documentation]    Check that different elements (SF, SFF, SCFs) are not configured
    No Content From URI     session     ${SERVICE_FORWARDERS_URI}
    No Content From URI     session     ${SERVICE_NODES_URI}
    No Content From URI     session     ${SERVICE_FUNCTIONS_URI}
    No Content From URI     session     ${SERVICE_CHAINS_URI}
    No Content From URI     session     ${SERVICE_FUNCTION_PATHS_URI}
    
Validate Persistency
    [Documentation]    Check that different elements (SF, SFF, SCFs) are configured
    # Service Nodes
    ${elements}=    Create List    "ip-mgmt-address":"172.17.0.3"    "name":"sf1"    "dpi-1"    "ip-mgmt-address":"172.17.0.2"    "name":"sff1"
    Check For Elements At URI    ${SERVICE_NODES_URI}    ${elements}
    # Service Function Forwarders
    ${elements}=    Create List    "name":"SFF1"    "name":"dpi-1"    "sf-dpl-name":"dpi-1-dpl"    "sff-dpl-name":"sff1-dpl"    "service-function-forwarder-ovs:ovs-bridge"
    ...    "bridge-name":"br-int"    "service-node":"sff1"    "ip":"172.17.0.2"    "port":6633     "transport":"service-locator:vxlan-gpe"    "name":"sff1-dpl"
    ...    "service-function-forwarder-ovs:ovs-options"    "dst-port":"6633"    "key":"flow"    "nshc1":"flow"    "nshc2":"flow"    "nshc3":"flow"    "nshc4":"flow"
    ...    "nsi":"flow"    "nsp":"flow"    "remote-ip":"flow"
    Check For Elements At URI    ${SERVICE_FORWARDERS_URI}    ${elements}
    # Service Functions
    ${elements}=    Create List    "ip-mgmt-address":"172.17.0.3"    "name":"dpi-1"    "nsh-aware":true    "ip":"172.17.0.3"    "name":"dpi-1-dpl"
    ...    "service-function-forwarder":"SFF1"
    Check For Elements At URI    ${SERVICE_FUNCTIONS_URI}    ${elements}
    # Service Function Chains
    ${elements}=    Create List    "service-function-chains"    "service-function-chain"    "name":"SFC1"    "sfc-service-function"    "name":"dpi-abstract1"    "type":"dpi"
    Check For Elements At URI    ${SERVICE_CHAINS_URI}    ${elements}
    # Service Function Paths
    ${elements}=    Create List    "service-function-paths"    "service-function-path"    "context-metadata":"NSH1"    "name":"SFP1"    "service-chain-name":"SFC1"
    ...    "service-path-hop"    "hop-number":0    "service-function-name":"dpi-1"    "starting-index":255    "symmetric":true
    Check For Elements At URI    ${SERVICE_FUNCTION_PATHS_URI}    ${elements}
    
Create Session In Controller
    [Arguments]    ${CONTROLLER}=${ODL_SYSTEM_IP}
    [Documentation]    Removes previously created Sessions and creates a session in specified controller
    Delete All Sessions
    Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}

Cleanup Suite
    [Documentation]    Clean up all docker containers created and delete sessions
    Remove SFC Elements
    Delete All Sessions
