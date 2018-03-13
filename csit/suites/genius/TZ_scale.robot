*** Settings ***
Documentation     Test Suite for IdManager
Suite Setup       Start Ovs Containers
#Suite Teardown    Delete All Sessions
#Test Teardown     Get Model Dump    ${ODL_SYSTEM_IP}    ${idmanager_data_models}
Library           OperatingSystem
Library           String
Library           RequestsLibrary
Library           Collections
Library           re
Variables         ../../variables/genius/Modules.py
Resource          ../../libraries/DataModels.robot
Resource          ../../libraries/Utils.robot
Resource          ../../libraries/Genius.robot
Resource          ../../variables/Variables.robot

*** Variables ***

*** Test Cases ***

*** Keywords ***
Start Ovs Containers
    [Documentation]    Pull the image, start instances
    SSHLibrary.Open_Connection    ${TOOLS_SYSTEM_IP}    timeout=20s
    SSHKeywords.Flexible_Controller_Login
    SSHLibrary.Execute Command    docker pull jhershbe/centos7-ovs-multimode    timeout=300s

