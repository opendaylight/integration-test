*** Settings ***
Library           Collections
Library           RequestsLibrary
Library           json

*** Keywords ***
Send_Request_To_Query_Topology_Id
    [Arguments]    ${module}    ${oper}
    ${resp}    Post Request    session    /restconf/operations/${module}:${oper}
    BuiltIn.Log    ${resp.content}
    [Return]    ${resp}

Send_Request_Operation_Besides_QueryTopologyId
    [Arguments]    ${module}    ${oper}    ${input}
    ${pkg}    Create Dictionary    input=${input}
    ${data}    dumps    ${pkg}
    ${resp}    Post Request    session    /restconf/operations/${module}:${oper}    data=${data}
    BuiltIn.Log    ${resp.content}

Construct_Af
    [Arguments]    ${ipv4bsl}    ${ipv6bsl}    ${biermlslabbase}    ${biermlslabrangesize}
    ${ipv4}    Create Dictionary    bitstringlength=${ipv4bsl}    bier-mpls-label-base=${biermlslabbase}    bier-mpls-label-range-size=${biermlslabrangesize}
    ${ipv6}    Create Dictionary    bitstringlength=${ipv6bsl}    bier-mpls-label-base=${biermlslabbase}    bier-mpls-label-range-size=${biermlslabrangesize}
    ${ipv4list}    Create List    ${ipv4}
    ${ipv6list}    Create List    ${ipv6}
    ${af}    Create Dictionary    ipv4=${ipv4list}    ipv6=${ipv6list}
    [Return]    ${af}

Construct_Subdomain
    [Arguments]    ${subdomainid}    ${igptype}    ${mtid}    ${bfrid}    ${bitstringlength}    ${af}
    ${subdomain}    Create Dictionary    sub-domain-id=${subdomainid}    igp-type=${igptype}    mt-id=${mtid}    bfr-id=${bfrid}    bitstringlength=${bitstringlength}
    ...    af=${af}
    [Return]    ${subdomain}

Construct_Bier_Global
    [Arguments]    ${encapsulationtype}    ${bitstringlength}    ${bfrid}    ${ipv4bfrprefix}    ${ipv6bfrprefix}    ${subdomainlist}
    ${bierglobal}    Create Dictionary    encapsulation-type=${encapsulationtype}    bitstringlength=${bitstringlength}    bfr-id=${bfrid}    ipv4-bfr-prefix=${ipv4bfrprefix}    ipv6-bfr-prefix=${ipv6bfrprefix}
    ...    sub-domain=${subdomainlist}
    [Return]    ${bierglobal}

Construct_Domain
    [Arguments]    ${domainid}    ${bierglobal}
    ${domain}    Create Dictionary    domain-id=${domainid}    bier-global=${bierglobal}
    [Return]    ${domain}

Add_Subdomain
    [Arguments]    ${subdomainlist}    ${af}
    : FOR    ${i}    IN RANGE    1    3
    \    ${subdomain}    Construct_Subdomain    ${i+1}    ${IGP_TYPE_LIST[1]}    ${MT_ID_LIST[0]}    ${BFR_ID_LIST[9]}
    \    ...    ${BITSTRINGLENGTH_LIST[0]}    ${af}
    \    Append To List    ${subdomainlist}    ${subdomain}
    BuiltIn.Log    ${subdomainlist}
    [Return]    ${subdomainlist}

Add_Or_Modify_Ipv4
    [Arguments]    ${ipv4bsl}    ${ipv6bsl}    ${biermlslabbase}    ${biermlslabrangesize}
    ${ipv4one}    Create Dictionary    bitstringlength=${ipv4bsl}    bier-mpls-label-base=${biermlslabbase}    bier-mpls-label-range-size=${biermlslabrangesize}
    ${ipv4two}    Create Dictionary    bitstringlength=${ipv6bsl}    bier-mpls-label-base=${biermlslabbase}    bier-mpls-label-range-size=${biermlslabrangesize}
    ${ipv6}    Create Dictionary    bitstringlength=${ipv6bsl}    bier-mpls-label-base=${biermlslabbase}    bier-mpls-label-range-size=${biermlslabrangesize}
    ${ipv4list}    Create List    ${ipv4one}    ${ipv4two}
    ${ipv6list}    Create List    ${ipv6}
    ${af}    Create Dictionary    ipv4=${ipv4list}    ipv6=${ipv6list}
    [Return]    ${af}
