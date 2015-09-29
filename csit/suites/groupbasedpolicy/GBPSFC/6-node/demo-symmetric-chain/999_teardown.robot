*** Settings ***
Library           SSHLibrary
Resource          ../../../../../libraries/Utils.robot
Resource          ../../../../../libraries/GBP/ConnUtils.robot
Variables         ../../../../../variables/Variables.py
Variables         ../Variables.py


*** Variables ***
${timeout} =     10s


*** Test Cases ***
Teardown Suite
    Log    Teardown suite in symetric-chain
    :FOR    ${GBPSFC}    IN    ${GBPSFCs}
    \    ConnUtils.Connect and Login    ${GBPSFC}    timeout=${timeout}
    \    SSHLibrary.Execute Command    sudo rm ${VM_SCRIPTS_FOLDER}/infrastructure_launch.py
    \    SSHLibrary.Execute Command    sudo rm ${VM_SCRIPTS_FOLDER}/get-nsps.py
    \    SSHLibrary.Close Connection
    
