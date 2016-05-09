*** Settings ***
Library     ${CURDIR}/../../libraries/Appenders/ElasticsearchAppender.py      ${IP}  ${PORT}

*** Test Cases ***
Test JVM Keywords
    [Documentation]    Call get_jvm methods for ${DURATION} s with  ${STEP} s interval.
    ${DURATION}=    Convert To Integer    ${DURATION}
    : FOR    ${INDEX}    IN RANGE    0    ${DURATION+1}    ${STEP}
    \    ${threading}=    Get Jvm Threading
    \    Log    ${threading}
    \    ${memory}=    Get Jvm Memory
    \    Log    ${memory}
    \    ${classload}=    Get Jvm Classloading
    \    Log    ${classload}
    \    ${garbagecollect}=    Get Jvm Garbagecollector
    \    Log    ${garbagecollect}
    \    Sleep    ${STEP}


Test Plot Points Call
    [Documentation]    Draw Resource usage plot using plot_points method.
    Plot Points    JVM Started Threads    threadcount.png   ${DURATION}     'Threading'    'TotalStartedThreadCount'
    Plot Points    JVM Heap Memory    heapmemory.png    ${DURATION}     'Memory'    'HeapMemoryUsage'   'used'
