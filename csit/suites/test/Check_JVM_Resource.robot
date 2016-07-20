*** Settings ***
Library           ${CURDIR}/../../libraries/Appenders/ElasticsearchAppender.py
Variables         ${CURDIR}/../../variables/Variables.py

*** Test Cases ***
Test JVM Keywords
    [Documentation]    Call get_jvm methods for ${DURATION} s with ${STEP} s interval.
    ${DURATION}=    Convert To Integer    ${DURATION}
    : FOR    ${INDEX}    IN RANGE    0    ${DURATION+1}    ${STEP}
    \    ${session}    Get Connection    ${ODL_SYSTEM_IP}    ${ELASTICPORT}
    \    Log    ${session}
    \    ${threading}=    Get Jvm Threading    ${session}
    \    Log    ${threading}
    \    ${memory}=    Get Jvm Memory    ${session}
    \    Log    ${memory}
    \    ${classload}=    Get Jvm Classloading    ${session}
    \    Log    ${classload}
    \    ${operatingsystem}=    Get Jvm operatingsystem    ${session}
    \    Log    ${operatingsystem}
    \    Sleep    ${STEP}

Test Plot Points Call
    [Documentation]    Draw Resource usage plot using plot_points method.
    ${session}    Get Connection    ${ODL_SYSTEM_IP}    ${ELASTICPORT}
    Log    ${session}
    Plot Points    ${session}    JVM ThreadCount    threadcount.png    'Threading'    'TotalStartedThreadCount'
    Plot Points    ${session}    JVM Heap Memory    heapmemory.png    'Memory'    'HeapMemoryUsage'    'used'
    Plot Points    ${session}    JVM LoadedClassCount    class_count.png    'ClassLoading'    'TotalLoadedClassCount'
    Plot Points    ${session}    JVM CPU Usage    cpu_usage.png    'OperatingSystem'    'ProcessCpuLoad'
