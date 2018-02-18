*** Settings ***
Documentation     This suite is a common keywords file for OVS utilities
Library           SSHLibrary
Library           re
Library           string
Resource          Utils.robot
Resource          ../variables/Variables.robot

*** Variables ***

*** Keywords ***
Get DumpFlows And Ovsconfig
    [Arguments]    ${conn_id}    ${bridge}
    [Documentation]    Get the OvsConfig and Flow entries from OVS
    SSHLibrary.Switch Connection    ${conn_id}
    Utils.Write Commands Until Expected Prompt    sudo ovs-vsctl show    ${DEFAULT_LINUX_PROMPT_STRICT}
    Utils.Write Commands Until Expected Prompt    sudo ovs-vsctl list Open_vSwitch    ${DEFAULT_LINUX_PROMPT_STRICT}
    Utils.Write Commands Until Expected Prompt    sudo ovs-ofctl show ${bridge} -OOpenFlow13    ${DEFAULT_LINUX_PROMPT_STRICT}
    Utils.Write Commands Until Expected Prompt    sudo ovs-ofctl dump-flows ${bridge} -OOpenFlow13    ${DEFAULT_LINUX_PROMPT_STRICT}
    Utils.Write Commands Until Expected Prompt    sudo ovs-ofctl dump-groups ${bridge} -OOpenFlow13    ${DEFAULT_LINUX_PROMPT_STRICT}
    Utils.Write Commands Until Expected Prompt    sudo ovs-ofctl dump-group-stats ${bridge} -OOpenFlow13    ${DEFAULT_LINUX_PROMPT_STRICT}
