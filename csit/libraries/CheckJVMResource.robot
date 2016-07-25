*** Settings ***
Documentation     Robot keyword library for Monitoring JVM resources
Library           ${CURDIR}/Appenders/ElasticsearchAppender.py
Variables         ${CURDIR}/../variables/Variables.py
Resource          ${CURDIR}/ClusterManagement.robot

*** Keywords ***
Get JVM Memory
    [Documentation]    Return latest jvm Memory object
    [Arguments]     ${controller-ip}=${ODL_SYSTEM_IP}       ${elastic-port}=${ELASTICPORT}
    ${session}    ElasticsearchAppender.Get_Connection    ${controller-ip}    ${elastic-port}
    ${value}=    ElasticsearchAppender.Get Jvm Memory       ${session}
    Log    ${value}
    [Return]    ${value}

Get JVM Threading
    [Documentation]    Return latest jvm Threading object
    [Arguments]     ${controller-ip}=${ODL_SYSTEM_IP}       ${elastic-port}=${ELASTICPORT}
    ${session}    ElasticsearchAppender.Get_Connection    ${controller-ip}    ${elastic-port}
    ${value}=    ElasticsearchAppender.Get Jvm Threading       ${session}
    Log    ${value}
    [Return]    ${value}

Get JVM Classloading
    [Documentation]    Return latest jvm Classloading object
    [Arguments]     ${controller-ip}=${ODL_SYSTEM_IP}       ${elastic-port}=${ELASTICPORT}
    ${session}    ElasticsearchAppender.Get_Connection    ${controller-ip}    ${elastic-port}
    ${value}=    ElasticsearchAppender.Get Jvm Classloading      ${session}
    Log    ${value}
    [Return]    ${value}

Get JVM Operatingsystem
    [Documentation]    Return latest jvm Operatingsystem object
    [Arguments]     ${controller-ip}=${ODL_SYSTEM_IP}       ${elastic-port}=${ELASTICPORT}
    ${session}    ElasticsearchAppender.Get_Connection    ${controller-ip}    ${elastic-port}
    ${value}=    ElasticsearchAppender.Get Jvm Operatingsystem      ${session}
    Log    ${value}
    [Return]    ${value}


Create JVM Plots
    [Documentation]    Draw Resource usage plot using plot_points method.
    [Arguments]     ${controller-ip}=${ODL_SYSTEM_IP}       ${elastic-port}=${ELASTICPORT}
    ${session}    ElasticsearchAppender.Get_Connection    ${controller-ip}    ${elastic-port}
    Log    ${session}
    Plot Points    ${session}    JVM ThreadCount    threadcount_${controller-ip}.png    'Threading'    'TotalStartedThreadCount'
    Plot Points    ${session}    JVM Heap Memory    heapmemory_${controller-ip}.png    'Memory'    'HeapMemoryUsage'    'used'
    Plot Points    ${session}    JVM LoadedClassCount    class_count_${controller-ip}.png    'ClassLoading'    'TotalLoadedClassCount'
    Plot Points    ${session}    JVM CPU Usage    cpu_usage_${controller-ip}.png    'OperatingSystem'    'ProcessCpuLoad'

Create_JVM_Plots_Cluster
    [Arguments]    ${member_index_list}=${EMPTY}
    [Documentation]    Draw Resource usage plot using plot_points method for cluster environment. Fail if no-sync is detected on a member from list (or any).
    ${index_list} =    ClusterManagement__Given_Or_Internal_Index_List    given_list=${member_index_list}
    : FOR    ${index}    IN    @{index_list}    # usually: 1, 2, 3.
    \       Create JVM Plots       ${ODL_SYSTEM_${index}_IP}       ${ELASTICPORT}
