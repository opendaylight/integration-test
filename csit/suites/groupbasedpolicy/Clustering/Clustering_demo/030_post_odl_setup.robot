*** Settings ***
Suite Setup       Start Connections
Library           SSHLibrary    120 seconds
Resource          ../Connections.robot

*** Test Cases ***
Setup Initialized Nodes
    Switch Connection    VPP2_CONNECTION
    Wait Until Keyword Succeeds    5x    10 sec    Check Ports
    Switch Connection    VPP3_CONNECTION
    Wait Until Keyword Succeeds    5x    10 sec    Check Ports
    Switch Connection    VPP2_CONNECTION
    ${out}    SSHLibrary.Execute Command    sudo brctl addif br1 tap00000000-01
    Log    ${out}
    ${out}    SSHLibrary.Execute Command    sudo brctl addif br2 tap00000000-02
    Log    ${out}
    ${out}    SSHLibrary.Execute Command    sudo brctl addif br3 tap00000000-03
    Switch Connection    VPP3_CONNECTION
    ${out}    SSHLibrary.Execute Command    sudo brctl addif br1 tap00000000-01
    Log    ${out}
    ${out}    SSHLibrary.Execute Command    sudo brctl addif br2 tap00000000-02
    Log    ${out}
    ${out}    SSHLibrary.Execute Command    sudo brctl addif br3 tap00000000-03
    Log    ${out}
    Switch Connection    VPP2_CONNECTION
    ${out}    SSHLibrary.Execute Command    sudo vppctl sh int
    Log    ${out}
    ${out}    SSHLibrary.Execute Command    sudo vppctl sh br
    Log    ${out}
    ${out}    SSHLibrary.Execute Command    sudo vppctl sh br 1 det
    Log    ${out}
    ${out}    SSHLibrary.Execute Command    sudo vppctl sh br 2 det
    Log    ${out}
    ${out}    SSHLibrary.Execute Command    sudo vppctl sh vxlan tunnel
    Log    ${out}

*** Keywords ***
Check Ports
    [Documentation]    Checks whether all port are already present
    ${out}    SSHLibrary.Execute Command    sudo vppctl sh int
    Log    ${out}
    Should Contain    ${out}    tap-1
    Should Contain    ${out}    tap-2
    Should Contain    ${out}    tap-3
    Should Contain    ${out}    vxlan_tunnel0
    Should Contain    ${out}    vxlan_tunnel1
    Should Contain    ${out}    vxlan_tunnel2
    Should Contain    ${out}    vxlan_tunnel3
    ${out}    SSHLibrary.Execute Command    sudo vppctl sh br
    Should Contain    ${out}    1
    Should Contain    ${out}    2
    