*** Settings ***
Library           SSHLibrary
Resource          ../../../../../libraries/Utils.robot
Resource          ../../../../../libraries/GBP/ConnUtils.robot
Variables         ../../../../../variables/Variables.py
Variables         ../Variables.py


*** Variables ***
${timeout} =     10s


*** Test Cases ***
Setup Suite
    Log    Setup suite in symetric-chain
    # TODO identical to asymetric-chain, could be unificated?
    :FOR    ${GBPSFC}    IN    @{GBPSFCs}
    \    ConnUtils.Connect and Login    ${GBPSFC}    timeout=${timeout}
    \    SSHLibrary.Put Directory    ${CURDIR}/init_scripts    ${VM_SCRIPTS_FOLDER}/    mode=0755    recursive=True
    \    SSHLibrary.Execute Command    sudo ${VM_SCRIPTS_FOLDER}/infrastructure_launch.py
    \    SSHLibrary.Execute Command    sudo ${VM_SCRIPTS_FOLDER}/get-nsps.py
    \    SSHLibrary.Close Connection
