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
Library           OperatingSystem
Library           SSHLibrary
Resource          SSHKeywords.robot

*** Keywords ***
Initialize_Artifact_Deployment_And_Usage
    [Documentation]    Initialize Nexus artifact deployment and usage
    ...    Create and activate a connection to the tools system and perform
    ...    additional configuration to allow the remaining keywords to deploy
    ...    and use artifacts from Nexus on the tools system.
    # Connect to the ODL machine
    ${odl}=    SSHKeywords.Open_Connection_To_ODL_System
    BuiltIn.Set_Suite_Variable    ${SSHKeywords__odl_system_connection}    ${odl}
    # Construct a tool that searches the specified directory and emits the
    # first subdirectory it finds there. Using 'find' for this task is not
    # easy because it randomly keeps finding and reporting stuff like "."
    # (depending on various properties of the environment) and it took me
    # much less time to code this solution than to figure out how to make
    # "find" behave as I want in a portable way ...
    SSHLibrary.Write    tee >search.sh
    SSHLibrary.Write    exec 2>&1
    SSHLibrary.Write    set -e
    SSHLibrary.Write    cd ${WORKSPACE}/${BUNDLEFOLDER}/system/org/opendaylight/$1
    SSHLibrary.Write    for File in *; do
    SSHLibrary.Write    if test -d $File; then
    SSHLibrary.Write    echo $File
    SSHLibrary.Write    break
    SSHLibrary.Write    fi
    SSHLibrary.Write    done
    Utils.Write_Bare_Ctrl_D
    # Connect to the Tools System machine
    ${tools}=    SSHKeywords.Open_Connection_To_Tools_System
    BuiltIn.Set_Suite_Variable    ${SSHKeywords__tools_system_connection}    ${tools}

NexusKeywords__Switch_To_ODL_System_Connection
    SSHLibrary.Switch_Connection    ${SSHKeywords__odl_system_connection}

NexusKeywords__Switch_To_Tools_System_Connection
    SSHLibrary.Switch_Connection    ${SSHKeywords__tools_system_connection}

NexusKeywords__Get_Directory_To_Look_At
    [Arguments]    ${component}
    BuiltIn.Return_From_Keyword_If    '${component}' == 'netconf'    netconf-ssh
    BuiltIn.Return_From_Keyword_If    '${component}' == 'bgpcep'    util
    BuiltIn.Fatal_Error    Test tools from component "${component}" are not supported. See https://bugs.opendaylight.org/show_bug.cgi?id=5206 for more details about why.

NexusKeywords__Detect_Version_To_Pull
    [Arguments]    ${directory}
    [Documentation]    Determine the exact Nexus directory to be used as a source for a particular test tool
    ...    Figure out what version of the tool needs to be pulled out of the
    ...    Nexus by looking at the version directory of the subsystem from
    ...    which the tool is being pulled. This code is REALLY UGLY but there
    ...    is no way around it until the bug
    ...    https://bugs.opendaylight.org/show_bug.cgi?id=5206 gets fixed.
    ...    I also don't want to depend on maven-metadata-local.xml and other
    ...    bits and pieces of ODL distribution which are not required for ODL
    ...    to function properly.
    ${directory}=    OperatingSystem.Run    dirname ${directory}
    ${check_place}=    NexusKeywords__Get_Directory_To_Look_At    ${directory}
    ${place}=    BuiltIn.Set_Variable    ${directory}/${check_place}
    NexusKeywords__Switch_To_ODL_System_Connection
    ${version}    ${result}=    SSHLibrary.Execute_Command    sh search.sh ${place}    return_rc=True
    BuiltIn.Log    ${version}
    NexusKeywords__Switch_To_Tools_System_Connection
    ${length}=    BuiltIn.Get_Length    ${version}
    BuiltIn.Run_Keyword_If    ${length} == 0 or ${result}!=0    BuiltIn.Fatal_Error    Component "${directory}" not found, cannot locate test tool
    [Return]    ${version}

Deploy_Artifact
    [Arguments]    ${directory}    ${name_prefix}    ${name_suffix}=-executable.jar    ${type}=snapshot
    [Documentation]    Deploy the specified artifact from Nexus to the cwd of the machine to which the active SSHLibrary connection points.
    ${urlbase}=    BuiltIn.Set_Variable    ${NEXUSURL_PREFIX}/content/repositories/opendaylight.${type}/org/opendaylight/${directory}
    ${version}=    NexusKeywords__Detect_Version_To_Pull    ${directory}
    # TODO: Use RequestsLibrary and String instead of curl and bash utilities?
    ${namepart}=    SSHLibrary.Execute_Command    curl ${urlbase}/${version}/maven-metadata.xml | grep value | head -n 1 | cut -d '>' -f 2 | cut -d '<' -f 1
    BuiltIn.Log    ${namepart}
    ${filename}=    BuiltIn.Set_Variable    ${name_prefix}${namepart}${name_suffix}
    BuiltIn.Log    ${filename}
    ${response}=    SSHLibrary.Execute_Command    wget -q -N ${urlbase}/${version}/${filename} 2>&1
    BuiltIn.Log    ${response}
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
