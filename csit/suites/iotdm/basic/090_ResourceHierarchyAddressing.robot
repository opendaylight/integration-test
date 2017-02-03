*** Settings ***
Documentation     Test suite tests addresing of entities (CSE and AE) and addressing of resources according to:
...               TS-0001: 7.2 M2M-SP-ID, CSE-ID, App-ID and AE-ID and resource Identifier formats
Suite Setup       Create Session    session    http://${ODL_SYSTEM_1_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Resource          ../../../libraries/Utils.robot
Resource          ../../../variables/Variables.robot

*** Variables ***

*** Test Cases ***
1.01 CRUD cseBase: Target resource ID: Unstructured, CSE-relative
    [Documentation]    Perform CRUD operations with cseBase resource using unstructured CSE-relative resource ID of the
    ...    cseBase resource. Format: <resource ID>
    [Tags]    not-implemented    exclude
    TODO

1.02 CRUD cseBase: Target resource ID: Structured, CSE-relative
    [Documentation]    Perform CRUD operations with cseBase resource using structured CSE-relative resource ID of the
    ...    cseBase resource. Format: <resource Name>
    [Tags]    not-implemented    exclude
    TODO

1.03 CRUD cseBase: Target resource ID: Unstructured, SP-relative
    [Documentation]    Perform CRUD operations with cseBase resource using unstructured SP-relative resource ID of the
    ...    cseBase resource. Format: /<CSE-ID>/<resource ID>
    [Tags]    not-implemented    exclude
    TODO

1.04 CRUD cseBase: Target resource ID: Strucutred, SP-relative
    [Documentation]    Perform CRUD operations with cseBase resource using structured SP-relative resource ID of the
    ...    cseBase resource. Format: /<CSE-ID>/resource name>
    [Tags]    not-implemented    exclude
    TODO

1.05 CRUD cseBase: Target resource ID: Unstructured, Absolute
    [Documentation]    Perform CRUD operations with cseBase resource using unstructured absolute resource ID of the
    ...    cseBase resource. Format: //<SP FQDN>/<CSE-ID>/<resource ID>
    [Tags]    not-implemented    exclude
    TODO

1.06 CRUD cseBase: Target resource ID: Strucutred, Absolute
    [Documentation]    Perform CRUD operations with cseBase resource using structured absolute resource ID of the
    ...    cseBase resource. Format: //<SP FQDN>/<CSE-ID>/<resource name>
    [Tags]    not-implemented    exclude
    TODO

2.00 Create testing resource hierarchy: cseBase/AE/Container/ContentInstances
    [Documentation]    Prepare testing resource hierarchy of cseBase/AE/Container/ContentInstances. Next tests will
    ...    perform operations with the contentInstance resources. cseBase and AE resources must have
    ...    different values set as: resource ID, resource name, CSE-ID / AE-ID.
    [Tags]    not-implemented    exclude
    TODO

2.01 CRUD contentInstance: Target resource ID: Unstructured, CSE-relative
    [Documentation]    Perform CRUD operations with contentInstance resource using unstructured CSE-relative resource ID of the
    ...    contentInstance resource. Format: <resource ID>
    [Tags]    not-implemented    exclude
    TODO

2.01-Negative CRUD contentInstance: Target resource ID: Unstructured, CSE-relative
    [Documentation]    Perform CRUD operations with contentInstance resource using invalid unstructured CSE-relative
    ...    resource ID of the contentInstance resource. Verify error result in response and use retrieve
    ...    operation to verify that the resource has not been changed.
    ...    Test these cases:
    ...    1. resource name instead of resource ID: Format: <resource Name>
    [Tags]    not-implemented    exclude
    TODO

2.02 CRUD contentInstance: Target resource ID: Structured, CSE-relative
    [Documentation]    Perform CRUD operations with contentInstance resource using structured CSE-relative resource ID of the
    ...    contentInstance resource. Format: <cseBase name>/<AE name>/<Container name>/<resource name>
    [Tags]    not-implemented    exclude
    TODO

2.02-Negative CRUD contentInstance: Target resource ID: Structured, CSE-relative
    [Documentation]    Perform CRUD operations with contentInstance resource using invalid structured CSE-relative
    ...    resource ID of the contentInstance resource. Verify error result in response and use retrieve
    ...    operation to verify that the resource has not been changed.
    ...    Test these cases:
    ...    1. cseBase resource ID instead of name: Format: <cseBase resource ID>/<AE name>/<Container name>/<resource name>
    ...    2. cseBase CSE-ID instead of name: Format: <cseBase CSE-ID>/<AE name>/<Container name>/<resource name>
    ...    3. AE resource ID instead of name: Format: <cseBase name>/<AE resource ID>/<Container name>/<resource name>
    ...    4. AE AE-ID instead of name: Format: <cseBase name>/<AE AE-ID>/<Container name>/<resource name>
    ...    5. Container resource ID instead of name: Format: <cseBase name>/<AE name>/<Container resource ID>/<resource name>
    ...    6. Target resource ID instead of name: Format: <cseBase name>/<AE name>/<Container name>/<resource ID>
    [Tags]    not-implemented    exclude
    TODO

2.03 CRUD contentInstance: Target resource ID: Unstructured, SP-relative
    [Documentation]    Perform CRUD operations with contentInstance resource using unstructured SP-relative resource ID of the
    ...    contentInstance resource. Format: /<CSE-ID>/<resource ID>
    [Tags]    not-implemented    exclude
    TODO

2.03-Negative CRUD contentInstance: Target resource ID: Unstructured, SP-relative
    [Documentation]    Perform CRUD operations with contentInstance resource using invalid unstructured SP-relative
    ...    resource ID of the contentInstance resource. Verify error result in response and use retrieve
    ...    operation to verify that the resource has not been changed.
    ...    Test these cases:
    ...    1. cseBase resource ID instead of CSE-ID: Format: /<cseBase resource ID>/<resource ID>
    ...    2. cseBase resource name instead of CSE-ID: Format: /<cseBase resource name>/<resource ID>
    ...    3. Target resource name instead of ID: Format: /<CSE-ID>/<resource name>
    ...    4. missing leading slash: Format: <CSE-ID>/<resource ID>
    ...    5. leading double slash: Format: //<CSE-ID>/<resource ID>
    [Tags]    not-implemented    exclude
    TODO

2.04 CRUD contentInstance: Target resource ID: Strucutred, SP-relative
    [Documentation]    Perform CRUD operations with contentInstance resource using structured SP-relative resource ID of the
    ...    contentInstance resource. Format: /<CSE-ID>/<cseBase name>/<AE name>/<Container name>/<resource name>
    [Tags]    not-implemented    exclude
    TODO

2.04-Negative CRUD contentInstance: Target resource ID: Strucutred, SP-relative
    [Documentation]    Perform CRUD operations with contentInstance resource using invalid structured SP-relative
    ...    resource ID of the contentInstance resource. Verify error result in response and use retrieve
    ...    operation to verify that the resource has not been changed.
    ...    Test these cases:
    ...    1. missing slash at the begin: Format: <CSE-ID>/<cseBase name>/<AE name>/<Container name>/<resource name>
    ...    2. cseBase resource ID instead of CSE-ID: Format: /<cseBase resource ID>/<cseBase name>/<AE name>/<Container name>/<resource name>
    ...    3. cseBase resource name instead of CSE-ID: Format: /<cseBase resource name>/<cseBase name>/<AE name>/<Container name>/<resource name>
    ...    4. cseBase resource ID instead of name: Format: /<CSE-ID>/<cseBase resource ID>/<AE name>/<Container name>/<resource name>
    ...    5. cseBase CSE-ID instead of name: Format: /<CSE-ID>/<CSE-ID>/<AE name>/<Container name>/<resource name>
    ...    6. target resource ID instead of resource name: Format: /<CSE-ID>/<cseBase name>/<AE name>/<Container name>/<resource ID>
    ...    7. leading double spash: Format: //<CSE-ID>/<cseBase name>/<AE name>/<Container name>/<resource name>
    [Tags]    not-implemented    exclude
    TODO

2.05 CRUD contentInstance: Target resource ID: Unstructured, Absolute
    [Documentation]    Perform CRUD operations with contentInstance resource using unstructured absolute resource ID of the
    ...    contentInstance resource. Format: //<SP FQDN>/<CSE-ID>/<resource ID>
    [Tags]    not-implemented    exclude
    TODO

2.05-Negative CRUD contentInstance: Target resource ID: Unstructured, Absolute
    [Documentation]    Perform CRUD operations with contentInstance resource using invalid unstructured absolute
    ...    resource ID of the contentInstance resource. Verify error result in response and use retrieve
    ...    operation to verify that the resource has not been changed.
    ...    Test these cases:
    ...    1. missing slash at the begin: Format: /<SP FQDN>/<CSE-ID>/<resource ID>
    ...    2. missing double slash at the begin: Format: <SP FQDN>/<CSE-ID>/<resource ID>
    ...    3. invalid SP FQDN: Format: //<Invalid SP FQDN>/<CSE-ID>/<resource ID>
    ...    4. cseBase resource ID instead of CSE-ID: Format: //<SP FQDN>/<cseBase resource ID>/<resource ID>
    ...    5. cseBase resource name instead of CSE-ID: Format: //<SP FQDN>/<cseBase resource name>/<resource ID>
    ...    6. target resource name instead of resource ID: Format: //<SP FQDN>/<CSE-ID>/<resource name>
    [Tags]    not-implemented    exclude
    TODO

2.06 CRUD contentInstance: Target resource ID: Strucutred, Absolute
    [Documentation]    Perform CRUD operations with contentInstance resource using structured absolute resource ID of the
    ...    contentInstance resource. Format: //<SP FQDN>/<CSE-ID>/<cseBase name>/<AE name>/<Container name>/<resource name>
    [Tags]    not-implemented    exclude
    TODO

2.06-Negative CRUD contentInstance: Target resource ID: Strucutred, Absolute
    [Documentation]    Perform CRUD operations with contentInstance resource using invalid structured absolute
    ...    resource ID of the contentInstance resource. Verify error result in response and use retrieve
    ...    operation to verify that the resource has not been changed.
    ...    Test these cases:
    ...    1. cseBase resource ID instead of name: Format: //<SP FQDN>/<CSE-ID>/<cseBase resource ID>/<AE name>/<Container name>/<resource name>
    ...    2. cseBase CSE-ID instead of name: Format: //<SP FQDN>/<CSE-ID>/<CSE-ID>/<AE name>/<Container name>/<resource name>
    ...    3. target resource ID instead of resource name: Format: //<SP FQDN>/<CSE-ID>/<cseBase name>/<AE name>/<Container name>/<resource ID>
    [Tags]    not-implemented    exclude
    TODO

3.01 CRUD contentInstance: Originator ID: relative AE-ID-Stem, first character 'C'
    [Documentation]    Perform CRUD operations with contentInstance resource using relative AE-ID-Stem starting with 'C'
    ...    set in the originator parameter of requests. Format: <C-AE-ID-Stem>
    [Tags]    not-implemented    exclude
    TODO

3.01-Negative CRUD contentInstance: Originator ID: relative AE-ID-Stem, first character 'C'
    [Documentation]    Perform CRUD operations with contentInstance resource using invalid relative AE-ID-Stem starting
    ...    with 'C' set in the originator parameter of requests. Verify error result in response
    ...    and use retrieve operation to verify that the resource has not been changed.
    ...    Test these cases:
    ...    1. Leading slash: Format: /<C-AE-ID-Stem>
    ...    2. Leading double slash: Format: //<C-AE-ID-Stem>
    ...    3. AE resource ID instead of AE-ID: Format: <AE resource ID>
    ...    4. AE resource name instead of AE-ID: Format: <AE resource name>
    ...    5. Leading slash and AE resource ID instead of AE-ID: Format: /<AE resource ID>
    ...    6. Leading slash and AE resource name instead of AE-ID: Format: /<AE resource name>
    ...    7. Leading double slash and AE resource ID instead of AE-ID: Format: //<AE resource ID>
    ...    8. Leading double slash AE resource name instead of AE-ID: Format: //<AE resource name>
    [Tags]    not-implemented    exclude
    TODO

3.02 CRUD contentInstance: Originator ID: relative AE-ID-Stem, first character 'S'
    [Documentation]    Perform CRUD operations with contentInstance resource using relative AE-ID-Stem starting with 'S'
    ...    set in the originator parameter of requests. Format: <S-AE-ID-Stem>
    [Tags]    not-implemented    exclude
    TODO

3.02-Negative CRUD contentInstance: Originator ID: relative AE-ID-Stem, first character 'S'
    [Documentation]    Perform CRUD operations with contentInstance resource using invalid relative AE-ID-Stem starting
    ...    with 'S' set in the originator parameter of requests. Verify error result in response
    ...    and use retrieve operation to verify that the resource has not been changed.
    ...    Test these cases (single leading slash is valid case when starting with 'S'):
    ...    1. Leading double slash: Format: //<S-AE-ID-Stem>
    [Tags]    not-implemented    exclude
    TODO

3.03 CRUD contentInstance: Originator ID: SP-relative AE-ID, first character 'C'
    [Documentation]    Perform CRUD operations with contentInstance resource using SP-relative AE-ID-Stem starting with 'C'
    ...    set in the originator parameter of requests. Format: /<SP-relative-CSE-ID>/<C-AE-ID-Stem>
    [Tags]    not-implemented    exclude
    TODO

3.03-Negative CRUD contentInstance: Originator ID: SP-relative AE-ID, first character 'C'
    [Documentation]    Perform CRUD operations with contentInstance resource using invalid SP-relative AE-ID-Stem
    ...    starting with 'C' set in the originator parameter of requests. Verify error result in response
    ...    and use retrieve operation to verify that the resource has not been changed.
    ...    Test these cases:
    ...    1. missing leading slash: Format: <SP-relative-CSE-ID>/<C-AE-ID-Stem>
    ...    2. cseBase resource name instead of CSE-ID: Format: /<cseBase resource name>/<C-AE-ID-Stem>
    ...    3. cseBase resource ID instead of CSE-ID: Format: /<cseBase resource ID>/<C-AE-ID-Stem>
    ...    4. AE resource ID instead of AE-ID: Format: /<SP-relative-CSE-ID>/<AE resource ID>
    ...    5. AE resource name instead of AE-ID: Format: /<SP-relative-CSE-ID>/<AE resource name>
    ...    6. leading double slash: Format: //<SP-relative-CSE-ID>/<C-AE-ID-Stem>
    [Tags]    not-implemented    exclude
    TODO

3.04 CRUD contentInstance: Originator ID: SP-relative AE-ID, first character 'S'
    [Documentation]    Perform CRUD operations with contentInstance resource using SP-relative AE-ID-Stem starting with 'S'
    ...    set in the originator parameter of requests. Format: /<S-AE-ID-Stem>
    [Tags]    not-implemented    exclude
    TODO

3.05 CRUD contentInstance: Originator ID: Absolute AE-ID, first character 'C'
    [Documentation]    Perform CRUD operations with contentInstance resource using Absolute AE-ID starting with 'C'
    ...    set in the originator parameter of requests. Format: //<SP FQDN>/<SP-relative-CSE-ID>/<C-AE-ID-Stem>
    [Tags]    not-implemented    exclude
    TODO

3.05-Negative CRUD contentInstance: Originator ID: Absolute AE-ID, first character 'C'
    [Documentation]    Perform CRUD operations with contentInstance resource using invalid Absolute AE-ID starting with 'C'
    ...    set in the originator parameter of requests. Verify error result in response
    ...    and use retrieve operation to verify that the resource has not been changed.
    ...    Test these cases:
    ...    1. Missing leading slash: Format: /<SP FQDN>/<SP-relative-CSE-ID>/<C-AE-ID-Stem>
    ...    2. Missing leading double slash: Format: <SP FQDN>/<SP-relative-CSE-ID>/<C-AE-ID-Stem>
    ...    3. Invalid SP FQDN: Format: //<Invalid SP FQDN>/<SP-relative-CSE-ID>/<C-AE-ID-Stem>
    ...    4. cseBase resource name instead of CSE-ID: Format: //<SP FQDN>/<cseBase resource name>/<C-AE-ID-Stem>
    ...    5. cseBase resource ID instead of CSE-ID: Format: //<SP FQDN>/<cseBase resource ID>/<C-AE-ID-Stem>
    ...    6. AE resource ID instead of AE-ID: Format: //<SP FQDN>/<SP-relative-CSE-ID>/<AE resource ID>
    ...    7. AE resource name instead of AE-ID: Format: //<SP FQDN>/<SP-relative-CSE-ID>/<AE resource name>
    [Tags]    not-implemented    exclude
    TODO

3.06 CRUD contentInstance: Originator ID: Absolute AE-ID, first character 'S'
    [Documentation]    Perform CRUD operations with contentInstance resource using Absolute AE-ID starting with 'S'
    ...    set in the originator parameter of requests. Format: //<SP FQDN>/<S-AE-ID-Stem>
    [Tags]    not-implemented    exclude
    TODO

3.06-Negative CRUD contentInstance: Originator ID: Absolute AE-ID, first character 'S'
    [Documentation]    Perform CRUD operations with contentInstance resource using invalid Absolute AE-ID starting with 'S'
    ...    set in the originator parameter of requests. Verify error result in response
    ...    and use retrieve operation to verify that the resource has not been changed.
    ...    Test these cases:
    ...    1. Missing leading slash: Format: /<SP FQDN>/<S-AE-ID-Stem>
    ...    2. Missing leading double slash: Format: <SP FQDN>/<S-AE-ID-Stem>
    ...    3. Invalid SP FQDN: Format: //<Invalid SP FQDN>/<S-AE-ID-Stem>
    ...    4. AE resource ID instead of AE-ID: Format: //<SP FQDN>/<AE resource ID>
    ...    5. AE resource name instead of AE-ID: Format: //<SP FQDN>/<AE resource name>
    [Tags]    not-implemented    exclude
    TODO

4.01 CRUD contentInstance: Originator ID: SP-relative CSE-ID
    [Documentation]    Perform CRUD operations with contentInstance resource using SP-relative CSE-ID
    ...    set in the originator parameter of requests. Format: /<CSE-ID>
    [Tags]    not-implemented    exclude
    TODO

4.01-Negative CRUD contentInstance: Originator ID: SP-relative CSE-ID
    [Documentation]    Perform CRUD operations with contentInstance resource using invalid SP-relative CSE-ID
    ...    set in the originator parameter of requests. Verify error result in response
    ...    and use retrieve operation to verify that the resource has not been changed.
    ...    Test these cases:
    ...    1. missing leading slash: Format: <CSE-ID>
    ...    2. leading double slash: Format: //<CSE-ID>
    ...    3. remoteCSE resource name instead of CSE-ID: Format: /<remoteCSE resource name>
    ...    4. remoteCSE resource id instead of CSE-ID: Format: /<remoteCSE resource ID>
    [Tags]    not-implemented    exclude
    TODO

4.02 CRUD contentInstance: Originator ID: Absolute CSE-ID
    [Documentation]    Perform CRUD operations with contentInstance resource using Absolute CSE-ID
    ...    set in the originator parameter of requests. Format: //<SP FQDN>/<CSE-ID>
    [Tags]    not-implemented    exclude
    TODO

4.02-Negative CRUD contentInstance: Originator ID: Absolute CSE-ID
    [Documentation]    Perform CRUD operations with contentInstance resource using invalid Absolute CSE-ID
    ...    set in the originator parameter of requests. Verify error result in response
    ...    and use retrieve operation to verify that the resource has not been changed.
    ...    Test these cases:
    ...    1. missing leading slash: Format: /<SP FQDN>/<CSE-ID>
    ...    2. missing leading double slash: Format: <SP FQDN>/<CSE-ID>
    ...    3. remoteCSE resource name instead of CSE-ID: Format: //<SP FQDN>/<remoteCSE resource name>
    ...    4. remoteCSE resource id instead of CSE-ID: Format: //<SP FQDN>/<remoteCSE resource ID>
    [Tags]    not-implemented    exclude
    TODO

*** Keywords ***
TODO
    Fail    "Not implemented"
