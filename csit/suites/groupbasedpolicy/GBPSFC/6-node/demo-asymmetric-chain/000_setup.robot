*** Settings ***
Library           SSHLibrary
Resource          ../../../../../libraries/Utils.robot
Resource          ../../../../../libraries/GBP/ConnUtils.robot
Variables         ../../../../../variables/Variables.py
Resource          ../Variables.robot


*** Variables ***
${timeout} =     10s


*** Test Cases ***
Setup Suite
    Log    Setup suite in asymetric-chain
    # TODO identical to symetric-chain, could be unificated?
    :FOR    ${GBPSFC}    IN    @{GBPSFCs}
    \    ConnUtils.Connect and Login    ${GBPSFC}    timeout=${timeout}
    \    SSHLibrary.Put Directory    ${CURDIR}/init_scripts    ${VM_SCRIPTS_FOLDER}/    mode=0755    recursive=True
    \    SSHLibrary.Execute Command    sudo ${VM_SCRIPTS_FOLDER}/infrastructure_launch.py
    \    SSHLibrary.Execute Command    sudo ${VM_SCRIPTS_FOLDER}/get-nsps.py
    \    SSHLibrary.Close Connection
