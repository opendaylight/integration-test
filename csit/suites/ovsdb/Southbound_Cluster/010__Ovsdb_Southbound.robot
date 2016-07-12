*** Settings ***
Documentation     Test suite for Ovsdb Southbound Cluster - Owner failover and recover
Suite Setup       Create Controller Sessions
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Resource          ../../../libraries/ClusterOvsdb.robot
Resource          ../../../libraries/ClusterKeywords.robot
Resource          ../../../libraries/Utils.robot
Resource          ../../../libraries/OVSDB.robot
Variables         ../../../variables/Variables.py

*** Test Cases ***
Create Original Cluster List
    [Documentation]    Create original cluster list.
    ${original_cluster_list}    ClusterKeywords.Create Controller Index List
    Set Suite Variable    ${original_cluster_list}
    Log    ${original_cluster_list}

Start OVS Multiple Connections
    [Documentation]    Connect OVS to all cluster instances.
    ${ovsdb_uuid}    Ovsdb.Add Multiple Managers to OVS    ${TOOLS_SYSTEM_IP}    ${original_cluster_list}
    Set Suite Variable    ${ovsdb_uuid}

Create Bridge Manually and Verify Before Fail
    [Documentation]    Create bridge with OVS command and verify it gets applied from all instances.
    ClusterOvsdb.Create Sample Bridge Manually And Verify    ${original_cluster_list}

Add Port Manually and Verify Before Fail
    [Documentation]    Add port with OVS command and verify it gets applied from all instances.
    ClusterOvsdb.Add Sample Port To The Manual Bridge And Verify    ${original_cluster_list}

Delete an OVS instance to the Manager
    [Documentation]    Delete the ovs Mannager.
    Clean OVSDB Test del-manager    ${TOOLS_SYSTEM_IP}

Delete the Bridge Manually and Verify Before Fail
    [Documentation]    Delete bridge with OVS command and verify it gets deleted from all instances.
    ClusterOvsdb.Delete Sample Bridge Manually And Verify    ${original_cluster_list}

Reboot an OVS instance to the controller
    [Documentation]    Reboot OVS to all cluster instances.
    Run Command On Remote System    ${TOOLS_SYSTEM_IP}    sudo reboot

After Reboot to Start OVS Multiple Connections
    [Documentation]    Connect OVS to all cluster instances.
    ${ovsdb_uuid}    Ovsdb.After Reboot TO Check The OVS    ${TOOLS_SYSTEM_IP}    ${original_cluster_list}
    Set Suite Variable    ${ovsdb_uuid}

After Reboot To Create Bridge Manually and Verify
    [Documentation]    Create bridge with OVS command and verify it gets applied from all instances.
    ClusterOvsdb.Create Sample Bridge Manually And Verify    ${original_cluster_list}

Update the Bridge Manually and Verify
    [Documentation]    Modify the openflow version for bridge said.
    ClusterOvsdb.Update Sample Bridge Manually And Verify    ${original_cluster_list}
    
After Reboot TO Delete the Bridge Manually and Verify Before Fail
    [Documentation]    Reboot The Delete bridge with OVS command and verify it gets deleted from all instances.
    ClusterOvsdb.Delete Sample Bridge Manually And Verify    ${original_cluster_list}