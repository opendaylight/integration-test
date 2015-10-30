*** Settings ***
Documentation     Documentation     Waiting for flows to appear on switches.
Library           SSHLibrary
Resource          ../../../../../libraries/Utils.robot
Resource          ../../../../../libraries/GBP/ConnUtils.robot
Resource          ../../../../../libraries/GBP/DockerUtils.robot
Resource          ../../../../../libraries/GBP/OpenFlowUtils.robot
Variables         ../../../../../variables/Variables.py
Resource          ../Variables.robot
Resource          ../Connections.robot
Suite Setup       Start Connections
Suite Teardown    Close Connections

*** Testcases ***

Wait For Flows on GBPSFC1
    Switch Connection    GPSFC1_CONNECTION
    ${output}    SSHLibrary.Execute Command    sudo ovs-ofctl dump-flows sw1 -O Openflow13
    Log    ${output}
    Wait For Flows On Switch    ${GBPSFC1}    sw1
    ${output}    SSHLibrary.Execute Command    sudo ovs-ofctl dump-flows sw1 -O Openflow13
    Log    ${output}
    ${output}    SSHLibrary.Execute Command    ping ${GBPSFC2} -c1
    Log    ${output}
    ${output}    SSHLibrary.Execute Command    ping ${GBPSFC3} -c1
    Log    ${output}
    ${output}    SSHLibrary.Execute Command    ping ${GBPSFC4} -c1
    Log    ${output}
    ${output}    SSHLibrary.Execute Command    ping ${GBPSFC5} -c1
    Log    ${output}
    ${output}    SSHLibrary.Execute Command    ping ${GBPSFC6} -c1
    Log    ${output}

Wait For Flows on GBPSFC2
    Switch Connection    GPSFC2_CONNECTION
    ${output}    SSHLibrary.Execute Command    sudo ovs-ofctl dump-flows sw2 -O Openflow13
    Log    ${output}    Wait For Flows On Switch    ${GBPSFC2}    sw2
    ${output}    SSHLibrary.Execute Command    sudo ovs-ofctl dump-flows sw2 -O Openflow13
    Log    ${output}

Wait For Flows on GBPSFC3
    Switch Connection    GPSFC3_CONNECTION
    ${output}    SSHLibrary.Execute Command    sudo ovs-ofctl dump-flows sw3 -O Openflow13
    Log    ${output}    Wait For Flows On Switch    ${GBPSFC3}    sw3
    ${output}    SSHLibrary.Execute Command    sudo ovs-ofctl dump-flows sw3 -O Openflow13
    Log    ${output}

Wait For Flows on GBPSFC4
    Switch Connection    GPSFC4_CONNECTION
    ${output}    SSHLibrary.Execute Command    sudo ovs-ofctl dump-flows sw4 -O Openflow13
    Log    ${output}    Wait For Flows On Switch    ${GBPSFC4}    sw4
    ${output}    SSHLibrary.Execute Command    sudo ovs-ofctl dump-flows sw4 -O Openflow13
    Log    ${output}

Wait For Flows on GBPSFC5
    Switch Connection    GPSFC5_CONNECTION
    ${output}    SSHLibrary.Execute Command    sudo ovs-ofctl dump-flows sw5 -O Openflow13
    Log    ${output}    Wait For Flows On Switch    ${GBPSFC5}    sw5
    ${output}    SSHLibrary.Execute Command    sudo ovs-ofctl dump-flows sw5 -O Openflow13
    Log    ${output}

Wait For Flows on GBPSFC6
    Switch Connection    GPSFC6_CONNECTION
    ${output}    SSHLibrary.Execute Command    sudo ovs-ofctl dump-flows sw6 -O Openflow13
    Log    ${output}    Wait For Flows On Switch    ${GBPSFC6}    sw6
    ${output}    SSHLibrary.Execute Command    sudo ovs-ofctl dump-flows sw6 -O Openflow13
    Log    ${output}

