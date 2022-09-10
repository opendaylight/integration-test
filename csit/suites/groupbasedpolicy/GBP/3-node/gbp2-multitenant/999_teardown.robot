*** Settings ***
Library         SSHLibrary
Resource        ../../../../../libraries/Utils.robot
Resource        ../../../../../libraries/GBP/ConnUtils.robot
Variables       ../../../../../variables/Variables.py
Resource        ../Variables.robot
Resource        ../GBP_3node.robot

Default Tags    multi-tenant    teardown    multi-tenant-teardown


*** Variables ***
${timeout}      10s


*** Test Cases ***
Teardown Suite
    Log    Teardown suite in gbp1
    FOR    ${GBP}    IN    @{GBPs}
        GBP_3node.Teardown Node    ${GBP}    ${CURDIR}    timeout=${timeout}
    END
