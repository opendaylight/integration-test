*** Settings ***
Suite Setup       RequestsLibrary.Create_Session    session    http://${ODL_SYSTEM_IP}:${RESTCONFPORT}    auth=${AUTH}    headers=${HEADERS_YANG_JSON}
Suite Teardown
Library           RequestsLibrary
Resource          ../../../libraries/BierTeResource.robot
