*** Settings ***
Documentation     Robot keyword library for Monitoring JVM resources
Library           ${CURDIR}/Appenders/ElasticsearchAppender.py
Variables         ${CURDIR}/../variables/Variables.py

*** Keywords ***
Get JVM Memory
    [Arguments]    ${controller-ip}=${ODL_SYSTEM_IP}    ${elastic-port}=${ELASTICPORT}
    [Documentation]    Return latest jvm Memory object
    ${session}    ElasticsearchAppender.Get_Connection    ${controller-ip}    ${elastic-port}
    ${value}=    ElasticsearchAppender.Get Jvm Memory    ${session}
    Log    ${value}
    [Return]    ${value}

Get JVM Threading
    [Arguments]    ${controller-ip}=${ODL_SYSTEM_IP}    ${elastic-port}=${ELASTICPORT}
    [Documentation]    Return latest jvm Threading object
    ${session}    ElasticsearchAppender.Get_Connection    ${controller-ip}    ${elastic-port}
    ${value}=    ElasticsearchAppender.Get Jvm Threading    ${session}
    Log    ${value}
    [Return]    ${value}

Get JVM Classloading
    [Arguments]    ${controller-ip}=${ODL_SYSTEM_IP}    ${elastic-port}=${ELASTICPORT}
    [Documentation]    Return latest jvm Classloading object
    ${session}    ElasticsearchAppender.Get_Connection    ${controller-ip}    ${elastic-port}
    ${value}=    ElasticsearchAppender.Get Jvm Classloading    ${session}
    Log    ${value}
    [Return]    ${value}

Get JVM Operatingsystem
    [Arguments]    ${controller-ip}=${ODL_SYSTEM_IP}    ${elastic-port}=${ELASTICPORT}
    [Documentation]    Return latest jvm Operatingsystem object
    ${session}    ElasticsearchAppender.Get_Connection    ${controller-ip}    ${elastic-port}
    ${value}=    ElasticsearchAppender.Get Jvm Operatingsystem    ${session}
    Log    ${value}
    [Return]    ${value}

Create JVM Plots
    [Arguments]    ${controllers_number}=${NUM_ODL_SYSTEM}    ${elastic-port}=${ELASTICPORT}
    [Documentation]    Draw Resource usage plot using plot_points method.
    FOR    ${index}    IN RANGE    1    ${controllers_number}+1
        ${controller-ip}=    Builtin.Set Variable    ${ODL_SYSTEM_${index}_IP}
        Log    ${controller-ip}
        ${session}    ElasticsearchAppender.Get_Connection    ${controller-ip}    ${elastic-port}
        Log    ${session}
        ElasticsearchAppender.Plot Points    ${session}    JVM Threads    threadcount_${index}.png    'Threading'    'ThreadCount'
        ElasticsearchAppender.Plot Points    ${session}    JVM Heap Memory    heapmemory_${index}.png    'Memory'    'HeapMemoryUsage'
        ...    'used'
        ElasticsearchAppender.Plot Points    ${session}    JVM Loaded Classes    class_count_${index}.png    'ClassLoading'    'TotalLoadedClassCount'
        ElasticsearchAppender.Plot Points    ${session}    JVM CPU Usage    cpu_usage_${index}.png    'OperatingSystem'    'ProcessCpuLoad'
    END
