*** Settings ***
Documentation     Keywords wrapping controller's cluster-admin yang model rpcs.
...
...               This is just an initial skeleton implementation, calls are debugged. Multiple
...               changes will follow as suites will be implemented.
...               This suite should be preferably merged before any suite to avoid conflicting
...               situations while suites will be implementing.
...
...               Copyright (c) 2017 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
Library           XML
Resource          ${CURDIR}/ClusterManagement.robot
Resource          ${CURDIR}/TemplatedRequests.robot

*** Variables ***
${RPC_DIR}        ${CURDIR}/../variables/mdsal/clusteradmin
${MAKE_LEADER_LOCAL_DIR}    ${RPC_DIR}/bmake_leader_local

*** Keywords ***
Make_Leader_Local
    [Arguments]    ${member_index}    ${shard_name}    ${shard_type}
    [Documentation]    TODO: more desctiptive comment than: Invoke become-module-leader rpc.
    ${session} =    ClusterManagement.Resolve_Http_Session_For_Member    member_index=${member_index}
    &{mapping}    BuiltIn.Create_Dictionary    SHARD_NAME=${shard_name}   SHARD_TYPE=${shard_type}
    ${text} =    TemplatedRequests.Post_As_Xml_Templated    ${MAKE_LEADER_LOCAL_DIR}    mapping=${mapping}    session=${session}
