*** Settings ***
Library           ${CURDIR}/../../libraries/Appenders/ElasticsearchAppender.py
Resource          ${CURDIR}/../../libraries/ClusterKeywords.robot
Variables         ${CURDIR}/../../variables/Variables.py

*** Test Cases ***
Create Cluster List
    [Documentation]    Create cluster list.
    ${cluster_list}    ClusterKeywords.Create Controller Index List
    Set Suite Variable    ${cluster_list}

Create Elasticsearch Sessions
    [Documentation]    Create Elasticsearch sessions.
    : FOR    ${index}    IN    @{cluster_list}
    \    ${elastic}=    ElasticsearchAppender.Get Connection    ${ODL_SYSTEM_${index}_IP}    ${ELASTICPORT}
    \    Set Suite Variable    ${elastic-${index}}    ${elastic}

Test JVM Keywords
    [Documentation]    Call get_jvm methods for ${DURATION} s with ${STEP} s interval.
    : FOR    ${index}    IN    @{cluster_list}
    \    ${threading}=    ElasticsearchAppender.Get Jvm Threading    ${elastic-${index}}
    \    Log    ${threading}
    \    ${memory}=    ElasticsearchAppender.Get Jvm Memory    ${elastic-${index}}
    \    Log    ${memory}
    \    ${classload}=    ElasticsearchAppender.Get Jvm Classloading    ${elastic-${index}}
    \    Log    ${classload}
    \    ${operatingsystem}=    ElasticsearchAppender.Get Jvm operatingsystem    ${elastic-${index}}
    \    Log    ${operatingsystem}

Test Plot Points Call
    [Documentation]    Draw Resource usage plot using plot_points method.
    : FOR    ${index}    IN    @{cluster_list}
    \    ElasticsearchAppender.Plot Points    ${elastic-${index}}    JVM ThreadCount    threadcount-${index}.png    'Threading'    'TotalStartedThreadCount'
    \    ElasticsearchAppender.Plot Points    ${elastic-${index}}    JVM Heap Memory    heapmemory-${index}.png    'Memory'    'HeapMemoryUsage'
    \    ...    'used'
    \    ElasticsearchAppender.Plot Points    ${elastic-${index}}    JVM LoadedClassCount    class_count-${index}.png    'ClassLoading'    'TotalLoadedClassCount'
    \    ElasticsearchAppender.Plot Points    ${elastic-${index}}    JVM CPU Usage    cpu_usage-${index}.png    'OperatingSystem'    'ProcessCpuLoad'
