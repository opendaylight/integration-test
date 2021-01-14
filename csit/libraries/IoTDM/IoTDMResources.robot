*** Settings ***
Documentation     Keywords for sanity test suites testing basic functionality
...               using multiple communication protocols
Library           Collections
Resource          ../../variables/Variables.robot
Resource          IoTDMKeywords.robot
Library           iotdm_comm.py
Library           OperatingSystem
Variables         client_libs/onem2m_primitive.py

*** Variables ***
${defCseBaseName}    InCSE1
${defAeId}        robotTestAe
# when AeId and resourceName of the AE are equal
${defAeUri}       ${defCseBaseName}/${defAeId}
${defTestApp}     testApp
${defSubscriptionName}    TestSubscription

*** Keywords ***
Log Primitive
    [Arguments]    ${primitive}
    [Documentation]    Logs primitive parameters, content and protocol specific parameters
    ${primitive_params} =    Get Primitive Parameters    ${primitive}
    ${content} =    Get Primitive Content    ${primitive}
    ${proto_specific_params} =    Get Primitive Protocol Specific Parameters    ${primitive}
    ${debug} =    Catenate    Parameters:    ${primitive_params}    Content:    ${content}    ProtocolParams: ${proto_specific_params}
    Log    ${debug}

Create Resource
    [Arguments]    ${resourceContent}    ${parentResourceUri}    ${resourceType}
    [Documentation]    Create resource, verify response and return the response
    ${primitive} =    New Create Request Primitive    ${parentResourceUri}    ${resourceContent}    ${resourceType}
    Log Primitive    ${primitive}
    ${rsp_primitive} =    Send Primitive    ${primitive}
    Log Primitive    ${rsp_primitive}
    Verify Exchange    ${primitive}    ${rsp_primitive}
    [Return]    ${rsp_primitive}

Update Resource
    [Arguments]    ${update_content}    ${resourceUri}
    [Documentation]    Update resource, verify response and return the response
    ${primitive} =    New Update Request Primitive    ${resourceUri}    ${update_content}
    Log Primitive    ${primitive}
    ${rsp_primitive} =    Send Primitive    ${primitive}
    Log Primitive    ${rsp_primitive}
    Verify Exchange    ${primitive}    ${rsp_primitive}
    [Return]    ${rsp_primitive}

Retrieve Resource
    [Arguments]    ${resourceUri}
    [Documentation]    Retrieve resource, verify response and return the response
    ${primitive} =    New Retrieve Request Primitive    ${resourceUri}
    Log Primitive    ${primitive}
    ${rsp_primitive} =    Send Primitive    ${primitive}
    Log Primitive    ${rsp_primitive}
    Verify Exchange    ${primitive}    ${rsp_primitive}
    [Return]    ${rsp_primitive}

Delete Resource
    [Arguments]    ${resourceUri}
    [Documentation]    Delete resource, verify response and return the response
    ${primitive} =    New DELETE On Session Primitive    ${resourceUri}
    Log Primitive    ${primitive}
    ${rsp_primitive} =    Send Primitive    ${primitive}
    Log Primitive    ${rsp_primitive}
    Verify Exchange    ${primitive}    ${rsp_primitive}
    [Return]    ${rsp_primitive}

Create Resource AE
    [Arguments]    ${cseBaseName}=${defCseBaseName}    ${aeId}=${defAeId}    ${appId}=${defTestApp}
    [Documentation]    Create AE resource and verify response
    ${attr} =    Set Variable    {"m2m:ae": {"api":"${appId}", "rr":true, "rn":"${aeId}"}}
    Run Keyword And Return    Create Resource    resourceContent=${attr}    parentResourceUri=${cseBaseName}    resourceType=${OneM2M.resource_type_application_entity}

Create Resource Container
    [Arguments]    ${parentResourceUri}    ${resourceName}
    [Documentation]    Create Container resource and verify response
    ${content}    Set Variable    {"m2m:cnt": {"rn": "${resourceName}"}}
    Run Keyword And Return    Create Resource    resourceContent=${content}    parentResourceUri=${parentResourceUri}    resourceType=${OneM2M.resource_type_container}

Create Resource ContentInstance
    [Arguments]    ${parentResourceUri}    ${contentValue}    ${resourceName}=${EMPTY}
    [Documentation]    Create ContentInstance resource and verify response
    ${resourceName} =    Set Variable If    """${resourceName}""" != """${EMPTY}"""    """, "rn":"${resourceName}"""    ${EMPTY}
    ${content}    Set Variable    {"m2m:cin":{"con":"${contentValue}"${resourceName}}}
    Run Keyword And Return    Create Resource    resourceContent=${content}    parentResourceUri=${parentResourceUri}    resourceType=${OneM2M.resource_type_content_instance}

Create Resource Subscription
    [Arguments]    ${parentResourceUri}    ${notificationUri}    ${resourceName}=${defSubscriptionName}    ${notifEventType}=${OneM2M.net_update_of_resource}    ${notifContentType}=${OneM2M.nct_all_attributes}
    [Documentation]    Create Suscription resource and verify response
    ${attr}    Set Variable    {"m2m:sub":{"nu":["${notificationUri}"],"nct": ${notifContentType},"rn":"${resourceName}", "enc":{"net":[${notifEventType}]}}}
    Create Resource    ${attr}    ${parentResourceUri}    ${OneM2M.resource_type_subscription}
