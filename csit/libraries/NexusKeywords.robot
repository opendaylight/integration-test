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
Resource          SSHKeywords.robot

*** Keywords ***
Initialize_Artifact_Deployment_And_Usage
    [Documentation]    Initialize Nexus artifact deployment and usage
    ...    Create and activate a connection to the tools system and perform
    ...    additional configuration to allow the remaining keywords to deploy
    ...    and use artifacts from Nexus on the tools system.
    SSHKeywords.Open_Connection_To_Tools_System

NexusKeywords__Get_Version_From_Metadata
    ${version}=    SSHLibrary.Execute_Command    cat metadata.xml | grep latest | cut -d '>' -f 2 | cut -d '<' -f 1
    BuiltIn.Log    ${version}
    BuiltIn.Return_From_Keyword_If    '${version}' != ''    ${version}
    ${version}=    SSHLibrary.Execute_Command    cat metadata.xml | grep '<version>' | sort | tail -n 1 | cut -d '>' -f 2 | cut -d '<' -f 1
    BuiltIn.Return_From_Keyword_If    '${version}' != ''    ${version}
    BuiltIn.Fail    Unrecognized metadata format, cannot determine the location of the requested artifact.

Deploy_Artifact
    [Arguments]    ${directory}    ${name_prefix}    ${name_suffix}=-executable.jar    ${type}=snapshot
    [Documentation]    Deploy the specified artifact from Nexus to the cwd of the machine to which the active SSHLibrary connection points.
    ${urlbase}=    BuiltIn.Set_Variable    ${NEXUSURL_PREFIX}/content/repositories/opendaylight.${type}/org/opendaylight/${directory}
    ${response}=    SSHLibrary.Execute_Command    curl ${urlbase}/maven-metadata.xml >metadata.xml
    BuiltIn.Log    ${response}
    # TODO: Use RequestsLibrary and String instead of curl and bash utilities?
    ${version}=    NexusKeywords__Get_Version_From_Metadata
    ${namepart}=    SSHLibrary.Execute_Command    curl ${urlbase}/${version}/maven-metadata.xml | grep value | head -n 1 | cut -d '>' -f 2 | cut -d '<' -f 1
    BuiltIn.Log    ${namepart}
    ${length}=    BuiltIn.Get_Length    ${namepart}
    BuiltIn.Run_Keyword_If    ${length} == 0    BuiltIn.Fatal_Error    Artifact "${name_prefix}" not found
    ${filename}=    BuiltIn.Set_Variable    ${name_prefix}${namepart}${name_suffix}
    BuiltIn.Log    ${filename}
    ${url}=    BuiltIn.Set_Variable    ${urlbase}/${version}/${filename}
    ${response}    ${result}=    SSHLibrary.Execute_Command    wget -q -N ${url} 2>&1    return_rc=True
    BuiltIn.Log    ${response}
    BuiltIn.Run_Keyword_If    ${result} != 0    BuiltIn.Fatal_Error    Artifact "${name_prefix}" could not be downloaded from ${url}
    [Return]    ${filename}

Deploy_Test_Tool
    [Arguments]    ${name}    ${suffix}=executable    ${type}=snapshot
    [Documentation]    Deploy a test tool.
    ...    The test tools have naming convention of the form
    ...    "${type}/some/dir/somewhere/<tool-name>/<tool-name>-<version-tag>-${suffix}.jar"
    ...    where "<tool-name>" is the name of the tool and "<version-tag>" is
    ...    the version tag that is digged out of the maven metadata. This
    ...    keyword calculates ${name_prefix} and ${name_suffix} for
    ...    "Deploy_Artifact" and then calls "Deploy_Artifact" to do the real
    ...    work of deploying the artifact.
    ${name_part}=    BuiltIn.Evaluate    '${name}'.split("/").pop()
    ${name_prefix}=    BuiltIn.Set_Variable    ${name_part}-
    ${name_suffix}=    BuiltIn.Set_Variable    -${suffix}.jar
    ${filename}=    Deploy_Artifact    ${name}    ${name_prefix}    ${name_suffix}    ${type}
    [Return]    ${filename}
