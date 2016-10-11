*** Settings ***
Resource          ../Variables.robot
Resource          ../Nodes.robot

*** Test Cases ***
Initialize Nodes
    Register Node    controller    ${VPP1}
    Register Node    compute0    ${VPP2}
    Register Node    compute1    ${VPP3}
