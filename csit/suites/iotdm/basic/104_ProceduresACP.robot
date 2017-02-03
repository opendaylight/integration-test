*** Settings ***
Documentation     Test suite tests access controll procedures related to accessControlPolicy resource described
...               in OneM2M specifications:
...               TS-0001: 9.6.2 Resource Type accessControlPolicy
...               TS-0004: 7.3.3.15 Check authorization of the originator
...               TS-0003: 7.1 Access Control Mechanism
Suite Setup       Create Session    session    http://${ODL_SYSTEM_1_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_XML}
Suite Teardown    Delete All Sessions
Library           RequestsLibrary
Library           ../../../libraries/Common.py
Resource          ../../../libraries/Utils.robot
Resource          ../../../variables/Variables.robot

*** Variables ***

*** Test Cases ***
1.01.01 ACP cseBase: Permit: privileges: AE, CRUD
    [Documentation]    Test ACPs of cseBase which are used by target container resource. Test only privileges with single
    ...    accessControlRule with accessControlOriginators set to AE-ID and accessControlOperations set to
    ...    CRUD operations. Test CRUD requests which are permitted by ACP.
    [Tags]    not-implemented    exclude
    TODO

1.01.02 ACP cseBase: Deny: privileges: AE, CRUD
    [Documentation]    Test ACPs of cseBase which are used by target container resource. Test only privileges with single
    ...    accessControlRule with accessControlOriginators set to AE-ID and accessControlOperations set to
    ...    CRUD operations. Test CRUD requests which are denied by ACP due to different request originator
    ...    AE-ID or CSE as originator.
    [Tags]    not-implemented    exclude
    TODO

1.01.03 ACP cseBase: Deny: privileges: AE, other than REQ operations
    [Documentation]    Test ACPs of cseBase which are used by target container resource. Test only privileges with single
    ...    accessControlRule with accessControlOriginators set to AE-ID and accessControlOperations set to
    ...    all operations expect to the operation used in the request.
    ...    Test CRUD requests which are denied by ACP due to non-permitted operation.
    [Tags]    not-implemented    exclude
    TODO

1.01.04 ACP cseBase: Permit: privileges: AE, N
    [Documentation]    Test ACPs of cseBase which are used by target container resource. Test only privileges with single
    ...    accessControlRule with accessControlOriginators set to AE-ID and accessControlOperations set
    ...    to N operation. Test the notification request which is permitted by ACP.
    [Tags]    not-implemented    exclude
    TODO

1.01.05 ACP cseBase: Deny: privileges: AE, N
    [Documentation]    Test ACPs of cseBase which are used by target container resource. Test only privileges with single
    ...    accessControlRule with accessControlOriginators set to AE-ID and accessControlOperations set
    ...    to N operation. Test notify reques which is denied by ACP due to different request originator
    ...    AE-ID or CSE as originator.
    [Tags]    not-implemented    exclude
    TODO

1.01.06 ACP cseBase: Deny: privileges: AE, CRUD + Discovery
    [Documentation]    Test ACPs of cseBase which are used by target container resource. Test only privileges with single
    ...    accessControlRule with accessControlOriginators set to AE-ID and accessControlOperations set
    ...    to CRUD + Discovery operations. Test CRUD + Discovery requests which are denied by ACP because
    ...    the notify operation is not permitted.
    [Tags]    not-implemented    exclude
    TODO

1.01.07 ACP cseBase: Permit: privileges: AE, Discovery
    [Documentation]    Test ACPs of cseBase which are used by target container resource. Test only privileges with single
    ...    accessControlRule with accessControlOriginators set to AE-ID and accessControlOperations set
    ...    to Discovery operation. Test the discovery request which is permitted by ACP.
    [Tags]    not-implemented    exclude
    TODO

1.01.08 ACP cseBase: Deny: privileges: AE, Discovery
    [Documentation]    Test ACPs of cseBase which are used by target container resource. Test only privileges with single
    ...    accessControlRule with accessControlOriginators set to AE-ID and accessControlOperations set
    ...    to Discovery operation. Test discovery request which is denied by ACP due to different request
    ...    originator AE-ID or CSE as originator.
    [Tags]    not-implemented    exclude
    TODO

1.01.09 ACP cseBase: Deny: privileges: AE, CRUDN
    [Documentation]    Test ACPs of cseBase which are used by target container resource. Test only privileges with single
    ...    accessControlRule with accessControlOriginators set to AE-ID and accessControlOperations set
    ...    to CRUDN operations. Test discovery request which is denied by ACP because the discovery operation
    ...    is not permitted.
    [Tags]    not-implemented    exclude
    TODO

1.01.10 ACP cseBase: Permit: privileges: AE, CRUDN + Discovery, multiple accessControlRules
    [Documentation]    Test ACPs of cseBase which are used by target container resource. Test only privileges with three
    ...    accessControlRules and only one of them permits tested requests. Used ACPs have set AE-ID in
    ...    accessControlOriginators and accessControlOperations set to CRUDN + Discovery operations.
    [Tags]    not-implemented    exclude
    TODO

1.01.11 ACP cseBase: Permit: selfPrivileges: AE, CRUDN + Discovery, multiple accessControlRules
    [Documentation]    Test ACPs of cseBase and test their selfPrivileges with three
    ...    accessControlRules and only one of them permits tested requests. Used ACPs have set AE-ID in
    ...    accessControlOriginators and accessControlOperations set to CRUDN + Discovery operations.
    [Tags]    not-implemented    exclude
    TODO

1.01.12 ACP cseBase: Deny: selfPrivileges: AE, CRUDN + Discovery, multiple accessControlRules
    [Documentation]    Test ACPs of cseBase and test their selfPrivileges with three
    ...    accessControlRules and all of them deny tested requests. Used ACPs have set AE-ID in
    ...    accessControlOriginators and accessControlOperations set to CRUDN + Discovery operations.
    [Tags]    not-implemented    exclude
    TODO

1.01.13 ACP cseBase: Permit: AE, CRUDN + Discovery, accessControlContexts/accessControlWindow
    [Documentation]    Test ACPs of cseBase which are used by target container resource. Test only privileges with single
    ...    accessControlRule with accessControlOriginators set to AE-ID and accessControlOperations set
    ...    to CRUDN + Discovery operations. Used ACPs have set also accessControlWindow and tested requests
    ...    meet all cryteria and are permitted.
    [Tags]    not-implemented    exclude
    TODO

1.01.14 ACP cseBase: Deny: AE, CRUDN + Discovery, accessControlContexts/accessControlWindow
    [Documentation]    Test ACPs of cseBase which are used by target container resource. Test only privileges with single
    ...    accessControlRule with accessControlOriginators set to AE-ID and accessControlOperations set
    ...    to CRUDN + Discovery operations. Used ACPs have set also accessControlWindow and tested requests
    ...    do not meet this cryteria and are denied.
    [Tags]    not-implemented    exclude
    TODO

1.01.15 ACP cseBase: Permit: AE, CRUDN + Discovery, accessControlContexts/accessControlIpAddresses/ipv4Addresses
    [Documentation]    Test ACPs of cseBase which are used by target container resource. Test only privileges with single
    ...    accessControlRule with accessControlOriginators set to AE-ID and accessControlOperations set
    ...    to CRUDN + Discovery operations. Used ACPs have set also accessControlIpAddresses/ipv4Addresses
    ...    and tested requests meet all cryteria and are permitted.
    [Tags]    not-implemented    exclude
    TODO

1.01.16 ACP cseBase: Deny: AE, CRUDN + Discovery, accessControlContexts/accessControlIpAddresses/ipv4Addresses
    [Documentation]    Test ACPs of cseBase which are used by target container resource. Test only privileges with single
    ...    accessControlRule with accessControlOriginators set to AE-ID and accessControlOperations set
    ...    to CRUDN + Discovery operations. Used ACPs have set also accessControlIpAddresses/ipv4Addresses
    ...    and tested requests do not meet this cryteria and are denied.
    [Tags]    not-implemented    exclude
    TODO

1.01.17 ACP cseBase: Permit: AE, CRUDN + Discovery, accessControlContexts/accessControlIpAddresses/ipv6Addresses
    [Documentation]    Test ACPs of cseBase which are used by target container resource. Test only privileges with single
    ...    accessControlRule with accessControlOriginators set to AE-ID and accessControlOperations set
    ...    to CRUDN + Discovery operations. Used ACPs have set also accessControlIpAddresses/ipv6Addresses
    ...    and tested requests meet all cryteria and are permitted.
    [Tags]    not-implemented    exclude
    TODO

1.01.18 ACP cseBase: Deny: AE, CRUDN + Discovery, accessControlContexts/accessControlIpAddresses/ipv6Addresses
    [Documentation]    Test ACPs of cseBase which are used by target container resource. Test only privileges with single
    ...    accessControlRule with accessControlOriginators set to AE-ID and accessControlOperations set
    ...    to CRUDN + Discovery operations. Used ACPs have set also accessControlIpAddresses/ipv6Addresses
    ...    and tested requests do not meet this cryteria and are denied.
    [Tags]    not-implemented    exclude
    TODO

1.01.19 ACP cseBase: Permit: AE, CRUDN + Discovery, accessControlContexts/accessControlLocationRegions
    [Documentation]    Test ACPs of cseBase which are used by target container resource. Test only privileges with single
    ...    accessControlRule with accessControlOriginators set to AE-ID and accessControlOperations set
    ...    to CRUDN + Discovery operations. Used ACPs have set also accessControlLocationRegions
    ...    and tested requests meet all cryteria and are permitted.
    [Tags]    not-implemented    exclude
    TODO

1.01.20 ACP cseBase: Deny: AE, CRUDN + Discovery, accessControlContexts/accessControlLocationRegions
    [Documentation]    Test ACPs of cseBase which are used by target container resource. Test only privileges with single
    ...    accessControlRule with accessControlOriginators set to AE-ID and accessControlOperations set
    ...    to CRUDN + Discovery operations. Used ACPs have set also accessControlLocationRegions
    ...    and tested requests do not meet this cryteria and are denied.
    [Tags]    not-implemented    exclude
    TODO

1.01.21 ACP cseBase: Permit: AE, CRUDN + Discovery, accessControlObjectDetails
    [Documentation]    Test ACPs of cseBase which are used by target container resource. Test only privileges with single
    ...    accessControlRule with accessControlOriginators set to AE-ID and accessControlOperations set
    ...    to CRUDN + Discovery operations. Used ACPs have set also accessControlObjectDetails
    ...    and tested requests meet all cryteria and are permitted.
    [Tags]    not-implemented    exclude
    TODO

1.01.22 ACP cseBase: Deny: AE, CRUDN + Discovery, accessControlObjectDetails
    [Documentation]    Test ACPs of cseBase which are used by target container resource. Test only privileges with single
    ...    accessControlRule with accessControlOriginators set to AE-ID and accessControlOperations set
    ...    to CRUDN + Discovery operations. Used ACPs have set also accessControlObjectDetails
    ...    and tested requests do not meet this cryteria and are denied.
    [Tags]    not-implemented    exclude
    TODO

1.01.23 ACP cseBase: Permit: AE, CRUDN + Discovery, accessControlAuthenticationFlag
    [Documentation]    Test ACPs of cseBase which are used by target container resource. Test only privileges with single
    ...    accessControlRule with accessControlOriginators set to AE-ID and accessControlOperations set
    ...    to CRUDN + Discovery operations. Used ACPs have set also accessControlAuthenticationFlag
    ...    and tested requests meet all cryteria and are permitted.
    [Tags]    not-implemented    exclude
    TODO

1.01.24 ACP cseBase: Deny: AE, CRUDN + Discovery, accessControlAuthenticationFlag
    [Documentation]    Test ACPs of cseBase which are used by target container resource. Test only privileges with single
    ...    accessControlRule with accessControlOriginators set to AE-ID and accessControlOperations set
    ...    to CRUDN + Discovery operations. Used ACPs have set also accessControlAuthenticationFlag
    ...    and tested requests do not meet this cryteria and are denied.
    [Tags]    not-implemented    exclude
    TODO

1.02.01 ACP cseBase: Permit: existing Group including originator, CRUD
    [Documentation]    Test ACP of cseBase which are used by target container resource. Test only privileges with single
    ...    accessControlRule with accessControlOriginators set to existing Group with the request originator
    ...    included and accessControlOperations set
    ...    to CRUD operations. Test CRUD requests which are permitted by ACP.
    [Tags]    not-implemented    exclude
    TODO

1.02.02 ACP cseBase: Deny: not existing Group including originator, CRUD
    [Documentation]    Test ACP of cseBase which are used by target container resource. Test only privileges with single
    ...    accessControlRule with accessControlOriginators set to not existing Group with the
    ...    request originator included and accessControlOperations set to CRUD operations.
    ...    Test CRUD requests which are denied by ACP.
    [Tags]    not-implemented    exclude
    TODO

1.02.03 ACP cseBase: Deny: existing Group not including originator, CRUD
    [Documentation]    Test ACP of cseBase which are used by target container resource. Test only privileges with single
    ...    accessControlRule with accessControlOriginators set to existing Group without the request
    ...    originator included and accessControlOperations set to CRUD operations. Test CRUD requests which
    ...    are denied by ACP.
    [Tags]    not-implemented    exclude
    TODO

1.02.04 ACP cseBase: Deny: existing Group including originator, other than request operations
    [Documentation]    Test ACP of cseBase which are used by target container resource. Test only privileges with single
    ...    accessControlRule with accessControlOriginators set to existing Group with the request originator
    ...    included and accessControlOperations set
    ...    to CRUD operations other than operation used in request so the requests are denied.
    [Tags]    not-implemented    exclude
    TODO

1.02.05 ACP cseBase: Permit: existing Group including originator, N
    [Documentation]    Test ACP of cseBase which are used by target container resource. Test only privileges with single
    ...    accessControlRule with accessControlOriginators set to existing Group with the request originator
    ...    included and accessControlOperations set to notify operation. Test notify requests which are
    ...    permitted by ACP.
    [Tags]    not-implemented    exclude
    TODO

1.02.06 ACP cseBase: Deny: not existing Group including originator, N
    [Documentation]    Test ACP of cseBase which are used by target container resource. Test only privileges with single
    ...    accessControlRule with accessControlOriginators set to not existing Group with the
    ...    request originator included and accessControlOperations set to notify operation.
    ...    Test notify requests which are denied by ACP.
    [Tags]    not-implemented    exclude
    TODO

1.02.07 ACP cseBase: Deny: existing Group not including originator, N
    [Documentation]    Test ACP of cseBase which are used by target container resource. Test only privileges with single
    ...    accessControlRule with accessControlOriginators set to existing Group without the request
    ...    originator included and accessControlOperations set to notify operation. Test notify requests which
    ...    are denied by ACP.
    [Tags]    not-implemented    exclude
    TODO

1.02.08 ACP cseBase: Deny: existing Group including originator, CRUD + Discovery
    [Documentation]    Test ACP of cseBase which are used by target container resource. Test only privileges with single
    ...    accessControlRule with accessControlOriginators set to existing Group with the request originator
    ...    included and accessControlOperations set
    ...    to CRUD + Discovery operations so the tested notification requests are denied.
    [Tags]    not-implemented    exclude
    TODO

1.02.09 ACP cseBase: Permit: existing Group including originator, Discovery
    [Documentation]    Test ACP of cseBase which are used by target container resource. Test only privileges with single
    ...    accessControlRule with accessControlOriginators set to existing Group with the request originator
    ...    included and accessControlOperations set to discovery operation. Test discovery requests which are
    ...    permitted by ACP.
    [Tags]    not-implemented    exclude
    TODO

1.02.10 ACP cseBase: Deny: not existing Group including originator, Discovery
    [Documentation]    Test ACP of cseBase which are used by target container resource. Test only privileges with single
    ...    accessControlRule with accessControlOriginators set to not existing Group with the
    ...    request originator included and accessControlOperations set to discovery operation.
    ...    Test discovery requests which are denied by ACP.
    [Tags]    not-implemented    exclude
    TODO

1.02.11 ACP cseBase: Deny: existing Group not including originator, Discovery
    [Documentation]    Test ACP of cseBase which are used by target container resource. Test only privileges with single
    ...    accessControlRule with accessControlOriginators set to existing Group without the request
    ...    originator included and accessControlOperations set to discovery operation. Test discovery requests which
    ...    are denied by ACP.
    [Tags]    not-implemented    exclude
    TODO

1.02.12 ACP cseBase: Deny: existing Group including originator, CRUDN
    [Documentation]    Test ACP of cseBase which are used by target container resource. Test only privileges with single
    ...    accessControlRule with accessControlOriginators set to existing Group with the request originator
    ...    included and accessControlOperations set
    ...    to CRUDN operations so the tested discovery requests are denied.
    [Tags]    not-implemented    exclude
    TODO

1.03.01 ACP cseBase: Permit: All, CRUD
    [Documentation]    Test ACPs of cseBase which are used by target container resource. Test only privileges with single
    ...    accessControlRule with accessControlOriginators set to All and accessControlOperations set to
    ...    CRUD operations. Test CRUD requests which are permitted by ACP.
    [Tags]    not-implemented    exclude
    TODO

1.03.02 ACP cseBase: Deny: All, other than REQ operations
    [Documentation]    Test ACPs of cseBase which are used by target container resource. Test only privileges with single
    ...    accessControlRule with accessControlOriginators set to All and accessControlOperations set to
    ...    all operations expect to the operation used in the request.
    ...    Test CRUD requests which are denied by ACP due to non-permitted operation.
    [Tags]    not-implemented    exclude
    TODO

1.03.03 ACP cseBase: Permit: All, N
    [Documentation]    Test ACPs of cseBase which are used by target container resource. Test only privileges with single
    ...    accessControlRule with accessControlOriginators set to All and accessControlOperations set
    ...    to N operation. Test the notification request which is permitted by ACP.
    [Tags]    not-implemented    exclude
    TODO

1.03.04 ACP cseBase: Deny: All, CRUD + Discovery
    [Documentation]    Test ACPs of cseBase which are used by target container resource. Test only privileges with single
    ...    accessControlRule with accessControlOriginators set to All and accessControlOperations set
    ...    to CRUD + Discovery operations. Test CRUD + Discovery requests which are denied by ACP because
    ...    the notify operation is not permitted.
    [Tags]    not-implemented    exclude
    TODO

1.03.05 ACP cseBase: Permit: All, Discovery
    [Documentation]    Test ACPs of cseBase which are used by target container resource. Test only privileges with single
    ...    accessControlRule with accessControlOriginators set to All and accessControlOperations set
    ...    to Discovery operation. Test the discovery request which is permitted by ACP.
    [Tags]    not-implemented    exclude
    TODO

1.03.06 ACP cseBase: Deny: All, CRUDN
    [Documentation]    Test ACPs of cseBase which are used by target container resource. Test only privileges with single
    ...    accessControlRule with accessControlOriginators set to All and accessControlOperations set
    ...    to CRUDN operations. Test discovery request which is denied by ACP because the discovery operation
    ...    is not permitted.
    [Tags]    not-implemented    exclude
    TODO

1.04 ACP cseBase: accessControlOriginators CSE
    [Documentation]    Implement the same scenario as in 1.01.01 - 1.01.09 but with accessControlOriginators set to
    ...    specific CSE-ID(s). Split into multiple TCs if needed.
    [Tags]    not-implemented    exclude
    TODO

1.05 ACP cseBase: accessControlOriginators role
    [Documentation]    Implement the same scenario as in 1.01.01 - 1.01.09 but with accessControlOriginators set to
    ...    specific role(s). Split into multiple TCs if needed.
    [Tags]    not-implemented    exclude
    TODO

1.06 ACP cseBase: accessControlOriginators domain
    [Documentation]    Implement the same scenario as in 1.01.01 - 1.01.09 but with accessControlOriginators set to
    ...    specific domain(s). Split into multiple TCs if needed.
    [Tags]    not-implemented    exclude
    TODO

2.00 ACP remoteCSE
    [Documentation]    Implement the same scenario as in 1.01.01 - 1.01.09 but with ACP resource created as child
    ...    resource of remoteCSE resource. Split into multiple TCs if needed.
    [Tags]    not-implemented    exclude
    TODO

3.00 ACP AE
    [Documentation]    Implement the same scenario as in 1.01.01 - 1.01.09 but with ACP resource created as child
    ...    resource of AE resource. Split into multiple TCs if needed.
    [Tags]    not-implemented    exclude
    TODO

4.01 ACP system default
    [Documentation]    Test multiple scenarios with resources with empty accessControlPolicyIDs attribute.
    ...    System default policy should be used.
    ...    Split into multiple TCs if needed.
    [Tags]    not-implemented    exclude
    TODO

5.01 ACP cseBase: resources without accessControlPolicyIDs
    [Documentation]    Test ACP procedures with resources without accessControlPolicyIDs attribute,
    ...    e.g.: Oldest, Latest, etc.
    ...    ACP IDs defined for parent resource should be used in such cases. Test also cases when also
    ...    parent resource doesn't have specified ACP IDs, system default ACP should be used.
    ...    Split into multiple TCs if needed.
    [Tags]    not-implemented    exclude
    TODO

6.01 ACP cseBase: announced resources
    [Documentation]    Test ACP procedures with announced resources.
    ...    Split into multiple TCs if needed.
    [Tags]    not-implemented    exclude
    TODO

*** Keywords ***
TODO
    Fail    "Not implemented"
