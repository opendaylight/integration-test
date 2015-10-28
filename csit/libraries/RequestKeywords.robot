*** Variables ***
${RequestsKeywords__Operationa_Requests_Session_Open}    False

*** Keywords ***
Create_Operational_Requests_Session
    [Documentation]    Create "operational" requests session pointing to http://${ODL_SYSTEM_IP}:${RESTCONFPORT}${OPERATIONAL_API}
    BuiltIn.Return_From_Keyword_If    ${RequestsKeywords__Operationa_Requests_Session_Open}
    BuiltIn.Set_Suite_Variable    ${RequestsKeywords__Operationa_Requests_Session_Open}    True
    # Setup a requests session for operational data (used by Netconf mount checks)
    # TODO: Do not include slash in ${OPERATIONAL_TOPO_API}, having it typed here is more readable.
    # TODO: Alternatively, create variable in Variables which starts with http.
    # Both TODOs would probably need to update every suite relying on current Variables.
    RequestsLibrary.Create_Session    operational    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}${OPERATIONAL_API}    auth=${AUTH}
