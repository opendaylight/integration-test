***Settings***
Library           ../../../libraries/iotdm.py
Library           ../../../libraries/riotdm.py
Library           Collections

***Variables***
${httphost}    ${CONTROLLER}
${httpuser}    admin
${httppass}    admin
${rt_ae}    2
${rt_container}    3
${rt_contentInstance}    4

***Test Cases***
Basic HTTP CRUD Test
    ${iserver}=    Connect To IoTDM    ${httphost}    ${httpuser}    ${httppass}    http
    #
    ${r}=    Create Resource    ${iserver}    InCSE1    ${rt_ae}
    ${ae}=    ResId    ${r}
    ${status_code}=    Status Code    ${r}
    ${text}=    Text    ${r}
    ${json}=    Json    ${r}
    ${elapsed}=    Elapsed    ${r}
    #
    ${r}=    Create Resource    ${iserver}    ${ae}    ${rt_container}
    ${container}=    ResId    ${r}
    ${status_code}=    Status Code    ${r}
    ${text}=    Text    ${r}
    ${json}=    Json    ${r}
    ${elapsed}=    Elapsed    ${r}
    #
    ${attr}=    Create Dictionary    con    101
    ${r}=    Create Resource    ${iserver}    ${container}    ${rt_contentInstance}    ${attr}
    ${contentinstance}=    ResId    ${r}
    ${status_code}=    Status Code    ${r}
    ${text}=    Text    ${r}
    ${json}=    Json    ${r}
    ${elapsed}=    Elapsed    ${r}
    #
    ${r}=    Retrieve Resource    ${iserver}    ${ae}
    ${status_code}=    Status Code    ${r}
    ${text}=    Text    ${r}
    ${json}=    Json    ${r}
    ${elapsed}=    Elapsed    ${r}
    #
    ${r}=    Retrieve Resource    ${iserver}    ${container}
    ${status_code}=    Status Code    ${r}
    ${text}=    Text    ${r}
    ${json}=    Json    ${r}
    ${elapsed}=    Elapsed    ${r}
    #
    ${r}=    Retrieve Resource    ${iserver}    ${contentInstance}
    ${status_code}=    Status Code    ${r}
    ${text}=    Text    ${r}
    ${json}=    Json    ${r}
    ${elapsed}=    Elapsed    ${r}
    #
    ${r}=    Delete Resource    ${iserver}    ${contentInstance}
    ${status_code}=    Status Code    ${r}
    ${text}=    Text    ${r}
    ${json}=    Json    ${r}
    ${elapsed}=    Elapsed    ${r}
    #
    ${r}=    Delete Resource    ${iserver}    ${container}
    ${status_code}=    Status Code    ${r}
    ${text}=    Text    ${r}
    ${json}=    Json    ${r}
    ${elapsed}=    Elapsed    ${r}
    #
    ${r}=    Delete Resource    ${iserver}    ${ae}
    ${status_code}=    Status Code    ${r}
    ${text}=    Text    ${r}
    ${json}=    Json    ${r}
    ${elapsed}=    Elapsed    ${r}
