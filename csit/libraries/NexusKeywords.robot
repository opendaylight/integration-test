*** Settings ***
Documentation     Nexus repository access keywords.
...
...               Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               This library encapsulates a bunch of somewhat complex and commonly used
...               netconf operations into reusable keywords to make writing netconf
...               test suites easier.
Library           SSHLibrary

*** Keywords ***
NexusKeywords__Get_Version_From_Metadata
    ${version}=    SSHLibrary.Execute_Command    cat metadata.xml | grep latest | cut -d '>' -f 2 | cut -d '<' -f 1
    BuiltIn.Log    ${version}
    BuiltIn.Return_From_Keyword_If    '${version}' != ''    ${version}
    ${version}=    SSHLibrary.Execute_Command    cat metadata.xml | grep '<version>' | sort | tail -n 1 | cut -d '>' -f 2 | cut -d '<' -f 1
    BuiltIn.Return_From_Keyword_If    '${version}' != ''    ${version}
    BuiltIn.Fail    Unrecognized metadata format, cannot determine the location of the requested artifact.

Deploy_Artifact
    [Arguments]    ${directory}    ${artifact}    ${type_suffix}=executable    ${type}=snapshot
    [Documentation]    Deploy the specified artifact from Nexus to the cwd of the machine to which the active SSHLibrary connection points.
    ${urlbase}=    BuiltIn.Set_Variable    ${NEXUSURL_PREFIX}/content/repositories/opendaylight.${type}/org/opendaylight/${directory}
    ${response}=    SSHLibrary.Execute_Command    curl ${urlbase}/maven-metadata.xml >metadata.xml
    BuiltIn.Log    ${response}
    # TODO: Use RequestsLibrary and String instead of curl and bash utilities?
    ${version}=    NexusKeywords__Get_Version_From_Metadata
    ${namepart}=    SSHLibrary.Execute_Command    curl ${urlbase}/${version}/maven-metadata.xml | grep value | head -n 1 | cut -d '>' -f 2 | cut -d '<' -f 1
    BuiltIn.Log    ${namepart}
    ${type_suffix}=    BuiltIn.Set_Variable_If    '${type_suffix}'==''    ${EMPTY}    -${type_suffix}
    ${filename}=    BuiltIn.Set_Variable    ${artifact}-${namepart}${type_suffix}.jar
    BuiltIn.Log    ${filename}
    ${response}=    SSHLibrary.Execute_Command    wget -q -N ${urlbase}/${version}/${filename} 2>&1
    BuiltIn.Log    ${response}
    [Return]    ${filename}
