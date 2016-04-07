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
Library           String
Resource          SSHKeywords.robot

*** Variables ***
${JDKVERSION}     None
${JAVA_7_HOME_CENTOS}    /usr/lib/jvm/java-1.7.0
${JAVA_7_HOME_UBUNTU}    /usr/lib/jvm/java-7-openjdk-amd64
${JAVA_8_HOME_CENTOS}    /usr/lib/jvm/java-1.8.0
${JAVA_8_HOME_UBUNTU}    /usr/lib/jvm/java-8-openjdk-amd64
${NEXUS_FALLBACK_URL}    ${NEXUSURL_PREFIX}/content/repositories/opendaylight.snapshot

*** Keywords ***
Initialize_Artifact_Deployment_And_Usage
    [Arguments]    ${tools_system_connect}=True
    [Documentation]    Places search utility to ODL system, which will be needed for version detection.
    ...    By default also initialize a SSH connection to Tools system,
    ...    as following Keywords assume a working connection towards target system.
    # Connect to the ODL machine.
    ${odl}=    SSHKeywords.Open_Connection_To_ODL_System
    # Deploy the search tool.
    SSHLibrary.Put_File    ${CURDIR}/../../tools/deployment/search.sh
    SSHLibrary.Close_Connection
    # Optionally connect to the Tools System machine.
    BuiltIn.Return_From_Keyword_If    not (${tools_system_connect})    # the argument may be a convoluted Python expression
    SSHKeywords.Open_Connection_To_Tools_System

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
    [Arguments]    ${component}    ${artifact}    ${name_prefix}    ${name_suffix}=-executable.jar    ${fallback_url}=${NEXUS_FALLBACK_URL}
    [Documentation]    Deploy the specified artifact from Nexus to the cwd of the machine to which the active SSHLibrary connection points.
    ...    Must have ${BUNDLE_URL} variable set to the URL from which the
    ...    tested ODL distribution was downloaded and this place must be
    ...    inside a repository created by a standard distribution
    ...    construction job. If this is detected to ne be the case, fallback URL is used.
    ${urlbase}=    String.Fetch_From_Left    ${BUNDLE_URL}    /org/opendaylight
    # If the BUNDLE_URL points somewhere else (perhaps *patch-test* job in Jenkins),
    # ${urlbase} is the whole ${BUNDLE_URL}, in which case we use the ${fallback_url}
    ${urlbase}=    BuiltIn.Set_Variable_If    '${urlbase}' != '${BUNDLE_URL}'    ${urlbase}    ${fallback_url}
    ${version}    ${location}=    NexusKeywords__Detect_Version_To_Pull    ${component}
    # TODO: Use RequestsLibrary and String instead of curl and bash utilities?
    ${url}=    BuiltIn.Set_Variable    ${urlbase}/${location}/${artifact}/${version}
    ${namepart}=    SSHLibrary.Execute_Command    curl -L ${url}/maven-metadata.xml | grep value | head -n 1 | cut -d '>' -f 2 | cut -d '<' -f 1
    BuiltIn.Log    ${namepart}
    ${length}=    BuiltIn.Get_Length    ${namepart}
    ${namepart}=    BuiltIn.Set_Variable_If    ${length} == 0    ${version}    ${namepart}
    ${filename}=    BuiltIn.Set_Variable    ${name_prefix}${namepart}${name_suffix}
    BuiltIn.Log    ${filename}
    ${url}=    BuiltIn.Set_Variable    ${url}/${filename}
    ${response}    ${result}=    SSHLibrary.Execute_Command    wget -q -N ${url} 2>&1    return_rc=True
    BuiltIn.Log    ${response}
    BuiltIn.Run_Keyword_If    ${result} != 0    BuiltIn.Fail    Artifact "${artifact}" in component "${component}" could not be downloaded from ${url}
    [Return]    ${filename}

Deploy_Test_Tool
    [Arguments]    ${component}    ${artifact}    ${suffix}=executable
    [Documentation]    Deploy a test tool.
    ...    The test tools have naming convention of the form
    ...    "<repository_url>/some/dir/somewhere/<tool-name>/<tool-name>-<version-tag>-${suffix}.jar"
    ...    where "<tool-name>" is the name of the tool and "<version-tag>" is
    ...    the version tag that is digged out of the maven metadata. This
    ...    keyword calculates ${name_prefix} and ${name_suffix} for
    ...    "Deploy_Artifact" and then calls "Deploy_Artifact" to do the real
    ...    work of deploying the artifact.
    ${name_prefix}=    BuiltIn.Set_Variable    ${artifact}-
    ${name_suffix}=    BuiltIn.Set_Variable    -${suffix}.jar
    ${filename}=    Deploy_Artifact    ${component}    ${artifact}    ${name_prefix}    ${name_suffix}
    [Return]    ${filename}

Compose_Dilemma_Filepath
    [Arguments]    ${default_path}    ${specific_path}
    [Documentation]    Query active SSH connection, return specific path if it exists else default path.
    ${out}    ${rc}=    SSHLibrary.Execute_Command    ls -lA ${specific_path} 2>&1    return_rc=True
    BuiltIn.Return_From_Keyword_If    ${rc} == 0    ${specific_path}
    BuiltIn.Return_From_Keyword    ${default_path}

Compose_Base_Java_Command
    [Arguments]    ${openjdk}=${JDKVERSION}
    [Documentation]    Return string suitable for launching Java programs over SSHLibrary, depending on JRE version needed.
    ...    This requires that the SSH connection on which the command is going to be used is active as it is needed for querying files.
    ...    Commands composed for one SSH connection shall not be reused on other SSH connections as the two connections may have different Java setups.
    ...    Not directly related to Nexus, but versioned Java tools may need this.
    # Check whether the user set the override and return it if yes.
    BuiltIn.Run_Keyword_And_Return_If    """${openjdk}""" == "openjdk8"    Compose_Dilemma_Filepath    ${JAVA_8_HOME_CENTOS}/bin/java    ${JAVA_8_HOME_UBUNTU}/bin/java
    BuiltIn.Run_Keyword_And_Return_If    """${openjdk}""" == "openjdk7"    Compose_Dilemma_Filepath    ${JAVA_7_HOME_CENTOS}/bin/java    ${JAVA_7_HOME_UBUNTU}/bin/java
    # Attempt to call plain "java" command directly. If it works, return it.
    ${out}    ${rc}=    SSHLibrary.Execute_Command    java -version 2>&1    return_rc=True
    BuiltIn.Return_From_Keyword_If    ${rc} == 0    java
    # Query the virtual machine for the JAVA_HOME environment variable and
    # use it to assemble a (hopefully) working command. If that worked out,
    # return the result.
    ${java}=    SSHLibrary.Execute_Command    echo \$JAVA_HOME/bin/java 2>&1
    ${out}    ${rc}=    SSHLibrary.Execute_Command    ${java} -version 2>&1    return_rc=True
    BuiltIn.Return_From_Keyword_If    ${rc} == 0    ${java}
    # There are bizzare test environment setups where the (correct) JAVA_HOME
    # is set in the VM where Robot is running but not in the VM where the
    # tools are supposed to run (usually because these two are really one
    # and the same system and idiosyncracies of BASH prevent easy injection
    # of the JAVA_HOME environment variable into a place where connections
    # made by SSHLibrary would pick it up). So try to use that value to
    # create a java command and check that it works.
    ${JAVA_HOME}=    OperatingSystem.Get_Environment_Variable    JAVA_HOME    ${EMPTY}
    ${java}=    BuiltIn.Set_Variable_If    """${JAVA_HOME}"""!=""    ${JAVA_HOME}/bin/java    false
    ${out}    ${rc}=    SSHLibrary.Execute_Command    ${java} -version 2>&1    return_rc=True
    BuiltIn.Return_From_Keyword_If    ${rc} == 0    ${java}
    # Nothing works, most likely java is not installed at all on the target
    # machine or it is hopelesly lost. Bail out with a helpful message
    # telling the user how to make it accessible for the script.
    BuiltIn.Fail    Unable to find Java; specify \${JDKVERSION}, put it to your PATH or set JAVA_HOME environment variable.

Compose_Full_Java_Command
    [Arguments]    ${options}    ${openjdk}=${JDKVERSION}
    [Documentation]    Return full Bash command to run Java with given options.
    ...    This requires that the SSH connection on which the command is going to be used is active as it is needed for querying files.
    ...    The options may include JVM options, application command line arguments, Bash redirects and other constructs.
    ${base_command}=    Compose_Base_Java_Command    openjdk=${openjdk}
    ${full_command}=    BuiltIn.Set_Variable    ${base_command} ${options}
    BuiltIn.Log    ${full_command}
    [Return]    ${full_command}
