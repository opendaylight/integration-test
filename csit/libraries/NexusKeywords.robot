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
Library           String
Resource          SSHKeywords.robot

*** Keywords ***
Initialize_Artifact_Deployment_And_Usage
    [Documentation]    Initialize Nexus artifact deployment and usage
    ...    Create and activate a connection to the tools system and perform
    ...    additional configuration to allow the remaining keywords to deploy
    ...    and use artifacts from Nexus on the tools system.
    # Connect to the ODL machine
    ${odl}=    SSHKeywords.Open_Connection_To_ODL_System
    # Deploy the search tool.
    SSHLibrary.Put_File    ${CURDIR}/../../tools/deployment/search.sh
    SSHLibrary.Close_Connection
    # Connect to the Tools System machine
    ${tools}=    SSHKeywords.Open_Connection_To_Tools_System
    BuiltIn.Set_Suite_Variable    ${SSHKeywords__tools_system_connection}    ${tools}

NexusKeywords__Get_Items_To_Look_At
    [Arguments]    ${component}
    [Documentation]    Get a list of items that might contain the version number that we are looking for.
    BuiltIn.Return_From_Keyword_If    '${component}' == 'bgpcep'    pcep-impl
    [Return]    ${component}-impl

NexusKeywords__Detect_Version_To_Pull
    [Arguments]    ${component}
    [Documentation]    Determine the exact Nexus directory to be used as a source for a particular test tool
    ...    Figure out what version of the tool needs to be pulled out of the
    ...    Nexus by looking at the version directory of the subsystem from
    ...    which the tool is being pulled. This code is REALLY UGLY but there
    ...    is no way around it until the bug
    ...    https://bugs.opendaylight.org/show_bug.cgi?id=5206 gets fixed.
    ...    I also don't want to depend on maven-metadata-local.xml and other
    ...    bits and pieces of ODL distribution which are not required for ODL
    ...    to function properly.
    ${itemlist}=    NexusKeywords__Get_Items_To_Look_At    ${component}
    ${current_ssh_connection}=    SSHLibrary.Get Connection
    SSHKeywords.Open_Connection_To_ODL_System
    ${version}    ${result}=    SSHLibrary.Execute_Command    sh search.sh ${WORKSPACE}/${BUNDLEFOLDER}/system ${itemlist}    return_rc=True
    SSHLibrary.Close_Connection
    Restore Current SSH Connection From Index    ${current_ssh_connection.index}
    BuiltIn.Log    ${version}
    BuiltIn.Run_Keyword_If    ${result}!=0    BuiltIn.Fail    Component "${component}" not found, cannot locate test tool
    ${version}    ${location}=    String.Split_String    ${version}    max_split=1
    [Return]    ${version}    ${location}

Deploy_Artifact
    [Arguments]    ${component}    ${artifact}    ${name_prefix}    ${name_suffix}=-executable.jar    ${type}=snapshot
    [Documentation]    Deploy the specified artifact from Nexus to the cwd of the machine to which the active SSHLibrary connection points.
    ${urlbase}=    BuiltIn.Set_Variable    ${NEXUSURL_PREFIX}/content/repositories/opendaylight.${type}
    ${version}    ${location}=    NexusKeywords__Detect_Version_To_Pull    ${component}
    # TODO: Use RequestsLibrary and String instead of curl and bash utilities?
    ${url}=    BuiltIn.Set_Variable    ${urlbase}/${location}/${artifact}/${version}
    ${namepart}=    SSHLibrary.Execute_Command    curl ${url}/maven-metadata.xml | grep value | head -n 1 | cut -d '>' -f 2 | cut -d '<' -f 1
    BuiltIn.Log    ${namepart}
    ${length}=    BuiltIn.Get_Length    ${namepart}
    BuiltIn.Run_Keyword_If    ${length} == 0    BuiltIn.Fail    Artifact "${artifact}" not found in component "${component}"
    ${filename}=    BuiltIn.Set_Variable    ${name_prefix}${namepart}${name_suffix}
    BuiltIn.Log    ${filename}
    ${url}=    BuiltIn.Set_Variable    ${url}/${filename}
    ${response}    ${result}=    SSHLibrary.Execute_Command    wget -q -N ${url} 2>&1    return_rc=True
    BuiltIn.Log    ${response}
    BuiltIn.Run_Keyword_If    ${result} != 0    BuiltIn.Fail    Artifact "${artifact}" in component "${component}" could not be downloaded from ${url}
    [Return]    ${filename}

Deploy_Test_Tool
    [Arguments]    ${component}    ${artifact}    ${suffix}=executable    ${type}=snapshot
    [Documentation]    Deploy a test tool.
    ...    The test tools have naming convention of the form
    ...    "${type}/some/dir/somewhere/<tool-name>/<tool-name>-<version-tag>-${suffix}.jar"
    ...    where "<tool-name>" is the name of the tool and "<version-tag>" is
    ...    the version tag that is digged out of the maven metadata. This
    ...    keyword calculates ${name_prefix} and ${name_suffix} for
    ...    "Deploy_Artifact" and then calls "Deploy_Artifact" to do the real
    ...    work of deploying the artifact.
    ${name_prefix}=    BuiltIn.Set_Variable    ${artifact}-
    ${name_suffix}=    BuiltIn.Set_Variable    -${suffix}.jar
    ${filename}=    Deploy_Artifact    ${component}    ${artifact}    ${name_prefix}    ${name_suffix}    ${type}
    [Return]    ${filename}
