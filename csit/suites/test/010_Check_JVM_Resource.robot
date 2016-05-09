*** Settings ***
Library           ${CURDIR}/../../libraries/Appenders/ElasticsearchAppender.py    ${ODL_SYSTEM_IP}    ${ELASTICPORT}
Variables         ${CURDIR}/../../variables/Variables.py

*** Test Cases ***
Test JVM Keywords
    [Documentation]    Call get_jvm methods for ${DURATION} s with ${STEP} s interval.
    ${DURATION}=    Convert To Integer    ${DURATION}
    : FOR    ${INDEX}    IN RANGE    0    ${DURATION+1}    ${STEP}
    \    ${threading}=    Get Jvm Threading
    \    Log    ${threading}
    \    ${memory}=    Get Jvm Memory
    \    Log    ${memory}
    \    ${classload}=    Get Jvm Classloading
    \    Log    ${classload}
    \    ${operatingsystem}=    Get Jvm operatingsystem
    \    Log    ${operatingsystem}
    \    Sleep    ${STEP}

Test Plot Points Call
    [Documentation]    Draw Resource usage plot using plot_points method.
    Plot Points    JVM ThreadCount    threadcount.png    'Threading'    'TotalStartedThreadCount'
    Plot Points    JVM Heap Memory    heapmemory.png    'Memory'    'HeapMemoryUsage'    'used'
    Plot Points    JVM LoadedClassCount    class_count.png    'ClassLoading'    'TotalLoadedClassCount'
    Plot Points    JVM CPU Usage    cpu_usage.png    'OperatingSystem'    'ProcessCpuLoad'
