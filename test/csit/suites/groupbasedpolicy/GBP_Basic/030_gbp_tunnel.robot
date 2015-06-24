*** Settings ***
Documentation     Test suite for GBP Tunnels, Operates functions from Restconf APIs.
Suite Setup       Create Session    session    http://${CONTROLLER}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS}
Suite Teardown    Delete All Sessions
Library           SSHLibrary
Library           Collections
Library           OperatingSystem
Library           RequestsLibrary
Variables         ../../../variables/Variables.py
Resource          ../../../libraries/Utils.txt

*** Variables ***
${GBP_TUNNELS_FILE}  ../../../variables/gbp/tunnels.json
${GBP_TUNNEL_ID}     openflow:1
${GBP_TUNNEL1_URL}    /restconf/config/opendaylight-inventory:nodes/opendaylight-inventory:node/${GBP_TUNNEL_ID}
${GBP_TUNNEL1_FILE}  ../../../variables/gbp/tunnel1.json

*** Test Cases ***
Add Tunnels
    [Documentation]    Add Tunnels from JSON file
    Add Elements To URI From File    ${GBP_TUNNELS_API}    ${GBP_TUNNELS_FILE}
    ${body}    OperatingSystem.Get File    ${GBP_TUNNELS_FILE}
    ${jsonbody}    To Json    ${body}
    ${resp}    RequestsLibrary.Get    session    ${GBP_TUNNELS_API}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${result}    To JSON    ${resp.content}
    Lists Should be Equal    ${jsonbody}    ${result}

Delete All Tunnels
    [Documentation]    Delete all Tunnels
    Add Elements To URI From File    ${GBP_TUNNELS_API}    ${GBP_TUNNELS_FILE}
    ${body}    OperatingSystem.Get File    ${GBP_TUNNELS_FILE}
    ${jsonbody}    To Json    ${body}
    ${resp}    RequestsLibrary.Get    session    ${GBP_TUNNELS_API}
    Should Be Equal As Strings    ${resp.status_code}    200
    Remove All Elements At URI    ${GBP_TUNNELS_API}
    ${resp}    RequestsLibrary.Get    session    ${GBP_TUNNELS_API}
    Should Be Equal As Strings    ${resp.status_code}    404

Add one Tunnel
    [Documentation]    Add one Tunnel from JSON file
    Add Elements To URI From File    ${GBP_TUNNEL1_URL}    ${GBP_TUNNEL1_FILE}
    ${body}    OperatingSystem.Get File    ${GBP_TUNNEL1_FILE}
    ${jsonbody}    To Json    ${body}
    ${resp}    RequestsLibrary.Get    session    ${GBP_TUNNEL1_URL}
    Should Be Equal As Strings    ${resp.status_code}    200
    ${result}    To JSON    ${resp.content}
    Lists Should be Equal    ${result}    ${jsonbody}

Get A Non-existing Tunnel
    [Documentation]    Get A Non-existing Tunnel
    Remove All Elements At URI    ${GBP_TUNNELS_API}
    ${resp}    RequestsLibrary.Get    session    ${GBP_TUNNEL1_URL}
    Should Be Equal As Strings    ${resp.status_code}    404

Delete one Tunnel
    [Documentation]    Delete one Tunnel
    Remove All Elements At URI    ${GBP_TUNNELS_API}
    Add Elements To URI From File    ${GBP_TUNNEL1_URL}    ${GBP_TUNNEL1_FILE}
    Remove All Elements At URI    ${GBP_TUNNEL1_URL}
    ${resp}    RequestsLibrary.Get    session    ${GBP_TUNNELS_API}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Not Contain    ${resp.content}    ${GBP_TUNNEL_ID}

Clean Datastore After Tests
    [Documentation]    Clean All Tunnels In Datastore After Tests
    Remove All Elements At URI    ${GBP_TUNNELS_API}
