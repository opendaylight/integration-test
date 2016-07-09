*** Settings ***
Documentation     Robot keyword library for Monitoring JVM resources
Library           ${CURDIR}/Appenders/ElasticsearchAppender.py
Variables         ${CURDIR}/../variables/Variables.py

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
    Plot Points    ${session}    JVM ThreadCount    threadcount.png    'Threading'    'TotalStartedThreadCount'
    Plot Points    ${session}    JVM Heap Memory    heapmemory.png    'Memory'    'HeapMemoryUsage'    'used'
    Plot Points    ${session}    JVM LoadedClassCount    class_count.png    'ClassLoading'    'TotalLoadedClassCount'
    Plot Points    ${session}    JVM CPU Usage    cpu_usage.png    'OperatingSystem'    'ProcessCpuLoad'
