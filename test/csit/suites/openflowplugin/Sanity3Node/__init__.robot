*** Settings ***
Documentation     Test suite for the OpenDaylight base edition with of13, aimed for statistics manager
Suite Setup       Start Suite
Suite Teardown    Stop Suite
Library           SSHLibrary

*** Variables ***
${start}          sudo python DynamicMininet.py
${linux_prompt}    >

*** Keywords ***
Start Suite
    Log    Start the test on the base edition
    Open Connection    ${MININET}    prompt=>
    Login With Public Key    ${MININET_USER}    ${USER_HOME}/.ssh/id_rsa    any
    Put File    ${CURDIR}/../../../libraries/DynamicMininet.py    .
    Execute Command    sudo ovs-vsctl set-manager ptcp:6644
    Execute Command    sudo mn -c
    Write    ${start}
    Read Until    mininet>
    Write    start_with_cluster ${CONTROLLER},${CONTROLLER1},${CONTROLLER2}
    Read Until    mininet>

Stop Suite
    Log    Stop the test on the base edition
    Read
    Write    exit
    Read Until    ${linux_prompt}
    Close Connection
