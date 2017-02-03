*** Settings ***
Documentation     Test suite testing IoTDM security methods without authentication of the request sender entity.
...               Test cases are implemented according to tables in 000_IoTDMSecurityNoAuthTable.txt
...               TODO: It seems that data driven approach is much more appropriate for implementation
...               of TCs described below which can be merged as needed.
Suite Setup       Create Session    session    http://${ODL_SYSTEM_1_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Resource          ../../../libraries/Utils.robot
Resource          ../../../variables/Variables.robot

*** Variables ***

*** Test Cases ***
1.00 L0: Verify configured security level
    [Documentation]    Verifies if the security level configured for IoTDM core and used protocol provider is L0
    [Tags]    not-implemented    exclude
    TODO

1.01 L0: Local CSE as target, AE as originator
    [Documentation]    Tests positive and negative cases of requests targetted to local CSE and originated by AE
    [Tags]    not-implemented    exclude
    TODO

1.02 L0: Local CSE as target, CSE as originator
    [Documentation]    Tests positive and negative cases of requests targetted to local CSE and originated by CSE
    [Tags]    not-implemented    exclude
    TODO

1.03 L0: Remote CSE as target, AE as originator
    [Documentation]    Tests positive and negative cases of requests targetted to remote CSE and originated by AE
    [Tags]    not-implemented    exclude
    TODO

1.04 L0: Remote CSE as target, CSE as originator
    [Documentation]    Tests positive and negative cases of requests targetted to remote CSE and originated by CSE
    [Tags]    not-implemented    exclude
    TODO

2.00 L1: Configure security level L1 in IoTDM core
    [Documentation]    Changes security level of IoTDM core from L0 to L1 and verifies.
    [Tags]    not-implemented    exclude
    TODO

2.01 L1: IoTDM core: Local CSE as target, AE as originator
    [Documentation]    Tests positive and negative cases of requests targetted to local CSE and originated by AE
    [Tags]    not-implemented    exclude
    TODO

2.02 L1: IoTDM core: Local CSE as target, CSE as originator
    [Documentation]    Tests positive and negative cases of requests targetted to local CSE and originated by CSE
    [Tags]    not-implemented    exclude
    TODO

2.03 L1: IoTDM core: Remote CSE as target, AE as originator
    [Documentation]    Tests positive and negative cases of requests targetted to remote CSE and originated by AE
    [Tags]    not-implemented    exclude
    TODO

2.04 L1: IoTDM core: Remote CSE as target, CSE as originator
    [Documentation]    Tests positive and negative cases of requests targetted to remote CSE and originated by CSE
    [Tags]    not-implemented    exclude
    TODO

2.99 Configure security level L0 in IoTDM core
    [Documentation]    Changes security level of IoTDM core back to L0 and verifies.
    [Tags]    not-implemented    exclude
    TODO

3.00 L1: Configure security level L1 in OneM2M HTTP module
    [Documentation]    Changes security level of OneM2M HTTP module from L0 to L1 and verifies. Security level
    ...    of IoTDM core is still set to L0 (so L1 security is applied to HTTP requests).
    [Tags]    not-implemented    exclude
    TODO

3.01 L1: HTTP: Local CSE as target, AE as originator
    [Documentation]    Tests positive and negative cases of requests targetted to local CSE and originated by AE
    [Tags]    not-implemented    exclude
    TODO

3.02 L1: HTTP: Local CSE as target, CSE as originator
    [Documentation]    Tests positive and negative cases of requests targetted to local CSE and originated by CSE
    [Tags]    not-implemented    exclude
    TODO

3.03 L1: HTTP: Remote CSE as target, AE as originator
    [Documentation]    Tests positive and negative cases of requests targetted to remote CSE and originated by AE
    [Tags]    not-implemented    exclude
    TODO

3.04 L1: HTTP: Remote CSE as target, CSE as originator
    [Documentation]    Tests positive and negative cases of requests targetted to remote CSE and originated by CSE
    [Tags]    not-implemented    exclude
    TODO

3.99 L1: Configure security level L0 in OneM2M HTTP module
    [Documentation]    Changes security level of OneM2M HTTP module back to L0 and verifies.
    [Tags]    not-implemented    exclude
    TODO

4.00 L1: Configure security level L1 in OneM2M CoAP module
    [Documentation]    Changes security level of OneM2M CoAP module from L0 to L1 and verifies. Security level
    ...    of IoTDM core is still set to L0 (so L1 security is applied to CoAP requests).
    [Tags]    not-implemented    exclude
    TODO

4.01 L1: CoAP: Local CSE as target, AE as originator
    [Documentation]    Tests positive and negative cases of requests targetted to local CSE and originated by AE
    [Tags]    not-implemented    exclude
    TODO

4.02 L1: CoAP: Local CSE as target, CSE as originator
    [Documentation]    Tests positive and negative cases of requests targetted to local CSE and originated by CSE
    [Tags]    not-implemented    exclude
    TODO

4.03 L1: CoAP: Remote CSE as target, AE as originator
    [Documentation]    Tests positive and negative cases of requests targetted to remote CSE and originated by AE
    [Tags]    not-implemented    exclude
    TODO

4.04 L1: CoAP: Remote CSE as target, CSE as originator
    [Documentation]    Tests positive and negative cases of requests targetted to remote CSE and originated by CSE
    [Tags]    not-implemented    exclude
    TODO

4.99 L1: Configure security level L0 in OneM2M CoAP module
    [Documentation]    Changes security level of OneM2M CoAP module back to L0 and verifies.
    [Tags]    not-implemented    exclude
    TODO

5.00 L1: Configure security level L1 in OneM2M MQTT module
    [Documentation]    Changes security level of OneM2M MQTT module from L0 to L1 and verifies. Security level
    ...    of IoTDM core is still set to L0 (so L1 security is applied to MQTT requests).
    [Tags]    not-implemented    exclude
    TODO

5.01 L1: MQTT: Local CSE as target, AE as originator
    [Documentation]    Tests positive and negative cases of requests targetted to local CSE and originated by AE
    [Tags]    not-implemented    exclude
    TODO

5.02 L1: MQTT: Local CSE as target, CSE as originator
    [Documentation]    Tests positive and negative cases of requests targetted to local CSE and originated by CSE
    [Tags]    not-implemented    exclude
    TODO

5.03 L1: MQTT: Remote CSE as target, AE as originator
    [Documentation]    Tests positive and negative cases of requests targetted to remote CSE and originated by AE
    [Tags]    not-implemented    exclude
    TODO

5.04 L1: MQTT: Remote CSE as target, CSE as originator
    [Documentation]    Tests positive and negative cases of requests targetted to remote CSE and originated by CSE
    [Tags]    not-implemented    exclude
    TODO

5.99 L1: Configure security level L0 in OneM2M MQTT module
    [Documentation]    Changes security level of OneM2M MQTT module back to L0 and verifies.
    [Tags]    not-implemented    exclude
    TODO

6.00 L1: Configure security level L1 in OneM2M WS module
    [Documentation]    Changes security level of OneM2M WS module from L0 to L1 and verifies. Security level
    ...    of IoTDM core is still set to L0 (so L1 security is applied to WS requests).
    [Tags]    not-implemented    exclude
    TODO

6.01 L1: WS: Local CSE as target, AE as originator
    [Documentation]    Tests positive and negative cases of requests targetted to local CSE and originated by AE
    [Tags]    not-implemented    exclude
    TODO

6.02 L1: WS: Local CSE as target, CSE as originator
    [Documentation]    Tests positive and negative cases of requests targetted to local CSE and originated by CSE
    [Tags]    not-implemented    exclude
    TODO

6.03 L1: WS: Remote CSE as target, AE as originator
    [Documentation]    Tests positive and negative cases of requests targetted to remote CSE and originated by AE
    [Tags]    not-implemented    exclude
    TODO

6.04 L1: WS: Remote CSE as target, CSE as originator
    [Documentation]    Tests positive and negative cases of requests targetted to remote CSE and originated by CSE
    [Tags]    not-implemented    exclude
    TODO

6.99 L1: Configure security level L0 in OneM2M WS module
    [Documentation]    Changes security level of OneM2M WS module back to L0 and verifies.
    [Tags]    not-implemented    exclude
    TODO

*** Keywords ***
TODO
    Fail    "Not implemented"
