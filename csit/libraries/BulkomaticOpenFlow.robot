*** Settings ***
Documentation     This library contains Bulkomatic specific KWs which one can use to avoid test code replication specifically in the area of json body change ... or other generic Bulkomatic test specific utility
Library           RequestsLibrary
Library           Collections
Library           json
Library           String
Library           OperatingSystem
Resource          Utils.robot
Variables         ../variables/Variables.py

*** Variables ***
${json_config_add}    temp_sal_add_bulk_flow_config.json
${json_config_get}    temp_sal_get_bulk_flow_config.json
${json_config_del}    temp_sal_del_bulk_flow_config.json

*** Keywords ***
Set DPN And Flow Count In Json Add
    [Arguments]    ${json_config}    ${dpn_count}    ${flows_count}
    [Documentation]    Set new DPN count and flows count per DPN in the Bulkomatic Add json file.
    ${body}=    OperatingSystem.Get File    ${CURDIR}/../variables/openflowplugin/${json_config}
    ${get_string}=    Set variable    "sal-bulk-flow:dpn-count" : "1"
    ${put_string}=    Set variable    "sal-bulk-flow:dpn-count" : "${dpn_count}"
    ${str}    Replace String Using Regexp    ${body}    ${get_string}    ${put_string}
    ${get_string}=    Set variable    "sal-bulk-flow:flows-per-dpn" : "1000"
    ${put_string}=    Set variable    "sal-bulk-flow:flows-per-dpn" : "${flows_count}"
    ${str}    Replace String Using Regexp    ${str}    ${get_string}    ${put_string}
    Log    ${str}
    OperatingSystem.Create File    ${CURDIR}/../variables/openflowplugin/${json_config_add}    ${str}
    [Return]    ${json_config_add}

Set DPN And Flow Count In Json Get
    [Arguments]    ${json_config}    ${dpn_count}    ${flows_count}
    [Documentation]    Set new DPN count and flows count per DPN in the Bulkomatic Get json file.
    ${body}=    OperatingSystem.Get File    ${CURDIR}/../variables/openflowplugin/${json_config}
    ${get_string}=    Set variable    "sal-bulk-flow:dpn-count" : "1"
    ${put_string}=    Set variable    "sal-bulk-flow:dpn-count" : "${dpn_count}"
    ${str}    Replace String Using Regexp    ${body}    ${get_string}    ${put_string}
    ${get_string}=    Set variable    "sal-bulk-flow:flows-per-dpn" : "1000"
    ${put_string}=    Set variable    "sal-bulk-flow:flows-per-dpn" : "${flows_count}"
    ${str}    Replace String Using Regexp    ${str}    ${get_string}    ${put_string}
    Log    ${str}
    OperatingSystem.Create File    ${CURDIR}/../variables/openflowplugin/${json_config_get}    ${str}
    [Return]    ${json_config_get}

Set DPN And Flow Count In Json Del
    [Arguments]    ${json_config}    ${dpn_count}    ${flows_count}
    [Documentation]    Set new DPN count and flows count per DPN in the Bulkomatic Del json file.
    ${body}=    OperatingSystem.Get File    ${CURDIR}/../variables/openflowplugin/${json_config}
    ${get_string}=    Set variable    "sal-bulk-flow:dpn-count" : "1"
    ${put_string}=    Set variable    "sal-bulk-flow:dpn-count" : "${dpn_count}"
    ${str}    Replace String Using Regexp    ${body}    ${get_string}    ${put_string}
    ${get_string}=    Set variable    "sal-bulk-flow:flows-per-dpn" : "1000"
    ${put_string}=    Set variable    "sal-bulk-flow:flows-per-dpn" : "${flows_count}"
    ${str}    Replace String Using Regexp    ${str}    ${get_string}    ${put_string}
    Log    ${str}
    OperatingSystem.Create File    ${CURDIR}/../variables/openflowplugin/${json_config_del}    ${str}
    [Return]    ${json_config_del}

Remove Temporary Json Files
    [Documentation]    Remove temporary json files.
    ${cmd}=    Set variable    rm ${CURDIR}/../variables/openflowplugin/temp_sal*.json
    Utils.Run Command On Controller    ${ODL_SYSTEM_IP}    ${cmd}
