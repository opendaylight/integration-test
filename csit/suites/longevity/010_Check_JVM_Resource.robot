*** Settings ***
Library     ${CURDIR}/../../libraries/Appenders/ElasticsearchAppender.py      ${IP}  ${PORT}

*** Test Cases ***

Test Plot Points Call
    [Documentation]     Draw Resource usage plot using plot_points method for a duration ${DURATION} s
    Plot Points    ${DURATION}     'Threading'     'TotalStartedThreadCount'

Test JVM Threading Call
    [Documentation]    Call get_jvm_threading method for ${DURATION} s
    : FOR    ${INDEX}    IN RANGE    1    ${DURATION}
    \    Get Jvm Threading
    \    Sleep      1s

Test JVM Memory Call
    [Documentation]    Call get_jvm_memory method for ${DURATION} s
    : FOR    ${INDEX}    IN RANGE    1    ${DURATION}
    \    Get Jvm Memory
    \    Sleep      1s

Test JVM ClassLoading Call
    [Documentation]    Call get_jvm_classloading method for ${DURATION} s
    : FOR    ${INDEX}    IN RANGE    1    ${DURATION}
    \    Get Jvm Classloading
    \    Sleep      1s

Test JVM GarbageCollector Call
    [Documentation]    Call get_jvm_garbagecollector method for ${DURATION} s
    : FOR    ${INDEX}    IN RANGE    1    ${DURATION}
    \    Get Jvm Garbagecollector
    \    Sleep      1s
