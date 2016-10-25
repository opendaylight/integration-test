*** Settings ***
Documentation     Nexus repository access keywords, and supporting Java and Maven handling.
...
...               Copyright (c) 2015,2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               This library encapsulates a bunch of somewhat complex and commonly used
...               Nexus operations into reusable keywords to make writing test suites easier.
...
...               Currently, Java version detection is incorporated so that Java tools can be run reliably.
...               Also, suport for installing and running Maven is added, as that needs the Java detection.
...               TODO: Move Java detection and Maven to a separate Resource, or rename this Resource.
Library           OperatingSystem
Library           SSHLibrary
Library           String
Library           XML
Library           Collections
Library           RequestsLibrary
Resource          ${CURDIR}/SSHKeywords.robot

*** Variables ***
${JDKVERSION}     None
${JAVA_7_HOME_CENTOS}    /usr/lib/jvm/java-1.7.0
${JAVA_7_HOME_UBUNTU}    /usr/lib/jvm/java-7-openjdk-amd64
${JAVA_8_HOME_CENTOS}    /usr/lib/jvm/java-1.8.0
${JAVA_8_HOME_UBUNTU}    /usr/lib/jvm/java-8-openjdk-amd64
${JAVA_OPTIONS}    -Xmx2560m    # Note that '-Xmx=3g' is wrong syntax. Also 3GB heap may not fit in 4GB RAM.
${JAVA_7_OPTIONS}    -Xmx2048m -XX:MaxPermSize=512m
${MAVEN_DEFAULT_OUTPUT_FILENAME}    default_maven.log
${MAVEN_OPTIONS}    -Pq -Djenkins
${MAVEN_REPOSITORY_PATH}    /tmp/r
${MAVEN_SETTINGS_URL}    https://raw.githubusercontent.com/opendaylight/odlparent/master/settings.xml
${MAVEN_VERSION}    3.3.9
${NEXUS_FALLBACK_URL}    ${NEXUSURL_PREFIX}/content/repositories/opendaylight.snapshot
${NEXUS_RELEASES_URL}    https://nexus.opendaylight.org/content/repositories/opendaylight.release/org/opendaylight/integration/distribution-karaf

*** Keywords ***
Initialize_Artifact_Deployment_And_Usage
    [Arguments]    ${tools_system_connect}=True
    [Documentation]    Places search utility to ODL system, which will be needed for version detection.
    ...    By default also initialize a SSH connection to Tools system,
    ...    as following Keywords assume a working connection towards target system.
    # Connect to the ODL machine.
    ${odl} =    SSHKeywords.Open_Connection_To_ODL_System
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
    ${itemlist} =    NexusKeywords__Get_Items_To_Look_At    ${component}
    ${current_ssh_connection} =    SSHLibrary.Get Connection
    SSHKeywords.Open_Connection_To_ODL_System
    ${version}    ${result} =    SSHLibrary.Execute_Command    sh search.sh ${WORKSPACE}/${BUNDLEFOLDER}/system ${itemlist}    return_rc=True
    SSHLibrary.Close_Connection
    SSHKeywords.Restore Current SSH Connection From Index    ${current_ssh_connection.index}
    BuiltIn.Log    ${version}
    BuiltIn.Run_Keyword_If    ${result}!=0    BuiltIn.Fail    Component "${component}" not found, cannot locate test tool
    ${version}    ${location} =    String.Split_String    ${version}    max_split=1
    [Return]    ${version}    ${location}

Deploy_Artifact
    [Arguments]    ${component}    ${artifact}    ${name_prefix}    ${name_suffix}=-executable.jar    ${fallback_url}=${NEXUS_FALLBACK_URL}
    [Documentation]    Deploy the specified artifact from Nexus to the cwd of the machine to which the active SSHLibrary connection points.
    ...    Must have ${BUNDLE_URL} variable set to the URL from which the
    ...    tested ODL distribution was downloaded and this place must be
    ...    inside a repository created by a standard distribution
    ...    construction job. If this is detected to ne be the case, fallback URL is used.
    ${urlbase} =    String.Fetch_From_Left    ${BUNDLE_URL}    /org/opendaylight
    # If the BUNDLE_URL points somewhere else (perhaps *patch-test* job in Jenkins),
    # ${urlbase} is the whole ${BUNDLE_URL}, in which case we use the ${fallback_url}
    ${urlbase} =    BuiltIn.Set_Variable_If    '${urlbase}' != '${BUNDLE_URL}'    ${urlbase}    ${fallback_url}
    ${version}    ${location} =    NexusKeywords__Detect_Version_To_Pull    ${component}
    # TODO: Use RequestsLibrary and String instead of curl and bash utilities?
    ${url} =    BuiltIn.Set_Variable    ${urlbase}/${location}/${artifact}/${version}
    ${metadata}=    SSHKeywords.Execute_Command_Should_Pass    curl -L ${url}/maven-metadata.xml
    ${namepart}=    SSHKeywords.Execute_Command_Should_Pass    echo "${metadata}" | grep value | head -n 1 | cut -d '>' -f 2 | cut -d '<' -f 1    stderr_must_be_empty=${True}
    ${length} =    BuiltIn.Get_Length    ${namepart}
    ${namepart} =    BuiltIn.Set_Variable_If    ${length} == 0    ${version}    ${namepart}
    ${filename} =    BuiltIn.Set_Variable    ${name_prefix}${namepart}${name_suffix}
    BuiltIn.Log    ${filename}
    ${url} =    BuiltIn.Set_Variable    ${url}/${filename}
    ${response}    ${result} =    SSHLibrary.Execute_Command    wget -q -N ${url} 2>&1    return_rc=True
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
    ${name_prefix} =    BuiltIn.Set_Variable    ${artifact}-
    ${name_suffix} =    BuiltIn.Set_Variable    -${suffix}.jar
    ${filename} =    Deploy_Artifact    ${component}    ${artifact}    ${name_prefix}    ${name_suffix}
    [Return]    ${filename}

Compose_Dilemma_Filepath
    [Arguments]    ${default_path}    ${specific_path}
    [Documentation]    Query active SSH connection, return specific path if it exists else default path.
    ${out}    ${rc} =    SSHLibrary.Execute_Command    ls -lA ${specific_path} 2>&1    return_rc=True
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
    ${out}    ${rc} =    SSHLibrary.Execute_Command    java -version 2>&1    return_rc=True
    BuiltIn.Return_From_Keyword_If    ${rc} == 0    java
    # Query the virtual machine for the JAVA_HOME environment variable and
    # use it to assemble a (hopefully) working command. If that worked out,
    # return the result.
    ${java} =    SSHLibrary.Execute_Command    echo \$JAVA_HOME/bin/java 2>&1
    ${out}    ${rc} =    SSHLibrary.Execute_Command    ${java} -version 2>&1    return_rc=True
    BuiltIn.Return_From_Keyword_If    ${rc} == 0    ${java}
    # There are bizzare test environment setups where the (correct) JAVA_HOME
    # is set in the VM where Robot is running but not in the VM where the
    # tools are supposed to run (usually because these two are really one
    # and the same system and idiosyncracies of BASH prevent easy injection
    # of the JAVA_HOME environment variable into a place where connections
    # made by SSHLibrary would pick it up). So try to use that value to
    # create a java command and check that it works.
    ${JAVA_HOME} =    OperatingSystem.Get_Environment_Variable    JAVA_HOME    ${EMPTY}
    ${java} =    BuiltIn.Set_Variable_If    """${JAVA_HOME}"""!=""    ${JAVA_HOME}/bin/java    false
    ${out}    ${rc} =    SSHLibrary.Execute_Command    ${java} -version 2>&1    return_rc=True
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
    ${base_command} =    Compose_Base_Java_Command    openjdk=${openjdk}
    ${full_command} =    BuiltIn.Set_Variable    ${base_command} ${options}
    BuiltIn.Log    ${full_command}
    [Return]    ${full_command}

Compose_Java_Home
    [Arguments]    ${openjdk}=${JDKVERSION}
    [Documentation]    Compose base java command and strip trailing "/bin/java".
    ${java_command} =    Compose_Base_Java_Command
    ${java_home}    ${bin}    ${java} =    String.Split_String_From_Right    ${java_command}    separator=/    max_split=2
    [Return]    ${java_home}

Install_Maven_Bare
    [Arguments]    ${maven_version}=3.3.9    ${openjdk}=${JDKVERSION}
    [Documentation]    Download and unpack Maven, prepare launch command with proper Java version and download settings file.
    ...    This Keyword requires an active SSH connection to target machine.
    ...    This Keyword sets global variables, so that suites can reuse existing installation.
    ...    This Keyword can only place Maven (and settings) to remote current working directory.
    ...    This Keyword does not perform any initial or final cleanup.
    # Avoid multiple initialization by several downstream libraries.
    ${installed_version} =    BuiltIn.Get_Variable_Value    \${Maven__installed_version}    None
    BuiltIn.Return_From_Keyword_If    """${installed_version}""" == """${maven_version}"""
    BuiltIn.Set_Global_Variable    \${Maven__installed_version}    ${maven_version}
    BuiltIn.Set_Global_Variable    \${maven_directory}    apache-maven-${maven_version}
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -rf '${maven_directory}'
    ${maven_archive_filename} =    BuiltIn.Set_Variable    ${maven_directory}-bin.tar.gz
    ${maven_download_url} =    BuiltIn.Set_Variable    http://www-us.apache.org/dist/maven/maven-3/${maven_version}/binaries/${maven_archive_filename}
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    wget -N '${maven_download_url}'    stderr_must_be_empty=False
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    tar xvf '${maven_archive_filename}'
    ${java_home} =    NexusKeywords.Compose_Java_Home    openjdk=${openjdk}
    ${java_actual_options} =    BuiltIn.Set_Variable_If    """${openjdk}""" == "openjdk7"    ${JAVA_7_OPTIONS}    ${JAVA_OPTIONS}
    BuiltIn.Set_Global_Variable    \${maven_bash_command}    export JAVA_HOME='${java_home}' && export MAVEN_OPTS='${java_actual_options}' && ./${maven_directory}/bin/mvn
    # TODO: Get settings files from Jenkins settings provider, somehow.
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    wget '${MAVEN_SETTINGS_URL}' -O settings.xml    stderr_must_be_empty=False

Install_Maven
    [Arguments]    ${maven_version}=3.3.9    ${openjdk}=${JDKVERSION}    ${branch}=${EMPTY}    ${patches}=${EMPTY}
    [Documentation]    Install Maven.
    ...    Depending on arguments, perform a multipatch build to populate local Maven repository with patched artifacts.
    Install_Maven_Bare    maven_version=${maven_version}    openjdk=${openjdk}
    BuiltIn.Return_From_Keyword_If    """${patches}""" == ""    No post-install build requested.
    BuiltIn.Run_Keyword_If    """${branch}""" == ""    BuiltIn.Fail    BRANCH needs to be specified for multipatch builds.
    ${script_name} =    BuiltIn.Set_Variable    include-raw-integration-multipatch-distribution-test.sh
    ${script_url} =    BuiltIn.Set_Variable    https://raw.githubusercontent.com/opendaylight/releng-builder/master/jjb/integration/${script_name}
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    wget -N '${script_url}'    stderr_must_be_empty=False
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    export WORKSPACE='${WORKSPACE}' && export BRANCH='${branch}' && export PATCHES_TO_BUILD='${patches}' && bash '${script_name}'    stderr_must_be_empty=False
    Run_Maven    pom_file=${WORKSPACE}/patch_tester/pom.xml

Run_Maven
    [Arguments]    ${pom_file}=pom.xml    ${log_file}=${MAVEN_DEFAULT_OUTPUT_FILENAME}
    [Documentation]    Determine arguments to use and call mvn command against given pom file.
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    mkdir -p '${MAVEN_REPOSITORY_PATH}'
    ${maven_repository_options} =    BuiltIn.Set_Variable    -Dmaven.repo.local=${MAVEN_REPOSITORY_PATH} -Dorg.ops4j.pax.url.mvn.localRepository=${MAVEN_REPOSITORY_PATH}
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    ${maven_bash_command} clean install dependency:tree -V -B -DoutputFile=dependency_tree.log -s './settings.xml' -f '${pom_file}' ${MAVEN_OPTIONS} ${maven_repository_options} > '${log_file}'

Get_ODL_Versions_From_Nexus
    [Documentation]    Returns name of last release found on nexus and list of all versions.
    RequestsLibrary.Create_Session    nexus    ${NEXUS_RELEASES_URL}    verify=${TRUE}
    ${uri}=    BuiltIn.Set_Variable    maven-metadata.xml
    ${response}=    RequestsLibrary.Get_Request    nexus    ${uri}
    BuiltIn.Log    ${response.text}
    ${root}=    XML.Parse_XML    ${response.text}
    ${element}=    XML.Get_Element    ${root}    versioning/latest
    ${latest}=    BuiltIn.Set_Variable    ${element.text}
    BuiltIn.Log    ${latest}
    @{elements}=    XML.Get_Elements    ${root}    .//version
    ${versions}=    BuiltIn.Create_List
    :FOR    ${element}    IN    @{elements}
    \    Collections.Append_To_List    ${versions}    ${element.text}
    Collections.Sort_List    ${versions}
    BuiltIn.Log_Many    @{versions}
    [Return]    ${latest}    @{versions}

Get_Latest_ODL_Release_From_Nexus
    [Documentation]    Returns name of last release found on nexus
    ${latest}  @{versions}=    Get_ODL_Versions_From_Nexus
    [Return]    ${latest}

Get_Latest_ODL_Stream_Release
    [Documentation]    Returns name for last release for specified stream.
    [Arguments]    ${stream}=latest
    ${latest}  @{versions}=    Get_ODL_Versions_From_Nexus
    BuiltIn.Return_From_Keyword_If    '${stream}'=='latest'    ${latest}
    ${latest_version}=    BuiltIn.Set_Variable    xxx
    :FOR    ${version}    IN    @{versions}
    \    ${latest_version}=    BuiltIn.Set_Variable_If    '${stream}'.title() in '${version}'    ${version}    ${latest_version}
    BuiltIn.Run_Keyword_If    '${latest_version}'=='xxx'    BuiltIn.Fail    Could not find latest release for stream ${stream}
    BuiltIn.Log    ${latest_version}
    [Return]    ${latest_version}

Get_Latest_ODL_Stream_Release_URL
    [Documentation]    Returns URL for last release for specified stream. Default format is .zip.
    [Arguments]    ${stream}=latest    ${format}=.zip
    ${latest_version}=    Get_Latest_ODL_Stream_Release    ${stream}
    ${url}=    BuiltIn.Set_Variable    ${NEXUS_RELEASES_URL}/${latest_version}/distribution-karaf-${latest_version}${format}
    BuiltIn.Log    ${url}
    [Return]   ${url}

Get_Latest_ODL_Previous_Stream_Release
    [Documentation]    Returns name for last release for previous stream of specified stream.
    ...    Note: If specified stream is not found on nexus, then it is taken as new one (not released yet).
    ...    So in this case, latest release version is return.
    [Arguments]    ${stream}=${ODL_STREAM}
    ${latest}  @{versions}=    Get_ODL_Versions_From_Nexus
    ${latest_version}=    BuiltIn.Set_Variable    xxx
    :FOR    ${version}    IN    @{versions}
    \    BuiltIn.Exit_For_Loop_If    '${stream}'.title() in '${version}'
    \    ${latest_version}=    BuiltIn.Set_Variable    ${version}
    BuiltIn.Run_Keyword_If    '${latest_version}'=='xxx'    BuiltIn.Fail    Could not find latest previous release for stream ${stream}
    BuiltIn.Log    ${latest_version}
    [Return]    ${latest_version}

Get_Latest_ODL_Previous_Stream_Release_URL
    [Documentation]    Returns URL for last release for previous stream of specified stream. Default format is .zip.
    [Arguments]    ${stream}=${ODL_STREAM}    ${format}=.zip
    ${latest_version}=    Get_Latest_ODL_Previous_Stream_Release    ${stream}
    ${url}=    BuiltIn.Set_Variable    ${NEXUS_RELEASES_URL}/${latest_version}/distribution-karaf-${latest_version}${format}
    BuiltIn.Log    ${url}
    [Return]   ${url}

