*** Settings ***
Documentation       Nexus repository access keywords, and supporting Java and Maven handling.
...
...                 Copyright (c) 2015,2016 Cisco Systems, Inc. and others. All rights reserved.
...
...                 This program and the accompanying materials are made available under the
...                 terms of the Eclipse Public License v1.0 which accompanies this distribution,
...                 and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...                 This library encapsulates a bunch of somewhat complex and commonly used
...                 Nexus operations into reusable keywords to make writing test suites easier.
...
...                 Currently, Java version detection is incorporated so that Java tools can be run reliably.
...                 Also, suport for installing and running Maven is added, as that needs the Java detection.
...                 TODO: Move Java detection and Maven to a separate Resource, or rename this Resource.

Library             Collections
Library             OperatingSystem
Library             SSHLibrary
Library             String
Library             XML
Library             Collections
Library             RequestsLibrary
Resource            ${CURDIR}/CompareStream.robot
Resource            ${CURDIR}/SSHKeywords.robot
Resource            ${CURDIR}/Utils.robot


*** Variables ***
&{COMPONENT_MAPPING}
...                                 netconf=netconf-api
...                                 bgpcep=pcep-impl
...                                 carpeople=clustering-it-model
...                                 yangtools=yang-data-impl
...                                 bindingv1=mdsal-binding-generator-impl
...                                 odl-micro=odlmicro-impl
@{RELEASE_INTEGRATED_COMPONENTS}    mdsal    odlparent    yangtools    carpeople    netconf    bgpcep
${JDKVERSION}                       None
${JAVA_8_HOME_CENTOS}               /usr/lib/jvm/java-1.8.0
${JAVA_8_HOME_UBUNTU}               /usr/lib/jvm/java-8-openjdk-amd64
${JAVA_11_HOME_CENTOS}              /usr/lib/jvm/java-11-openjdk
${JAVA_11_HOME_UBUNTU}              /usr/lib/jvm/java-11-openjdk-amd64
${JAVA_17_HOME_CENTOS}              /usr/lib/jvm/java-17-openjdk
${JAVA_17_HOME_UBUNTU}              /usr/lib/jvm/java-17-openjdk-amd64
${JAVA_21_HOME_CENTOS}              /usr/lib/jvm/java-21-openjdk
${JAVA_21_HOME_UBUNTU}              /usr/lib/jvm/java-21-openjdk-amd64
# Note that '-Xmx=3g' is wrong syntax. Also 3GB heap may not fit in 4GB RAM.
${JAVA_OPTIONS}
...                                 -Xmx2560m
${MAVEN_DEFAULT_OUTPUT_FILENAME}    default_maven.log
${MAVEN_OPTIONS}                    -Pq -Djenkins
${MAVEN_REPOSITORY_PATH}            /tmp/r
${MAVEN_SETTINGS_URL}               https://raw.githubusercontent.com/opendaylight/odlparent/master/settings.xml
${MAVEN_VERSION}                    3.3.9
${NEXUS_FALLBACK_URL}               ${NEXUSURL_PREFIX}/content/repositories/opendaylight.snapshot
${NEXUS_RELEASE_BASE_URL}           https://nexus.opendaylight.org/content/repositories/opendaylight.release
${NEXUS_RELEASES_URL}               ${NEXUS_RELEASE_BASE_URL}/org/opendaylight/integration/karaf


*** Keywords ***
Initialize_Artifact_Deployment_And_Usage
    [Documentation]    Places search utility to ODL system, which will be needed for version detection.
    ...    By default also initialize a SSH connection to Tools system,
    ...    as following Keywords assume a working connection towards target system.
    [Arguments]    ${tools_system_connect}=True
    # Connect to the ODL machine.
    ${odl} =    SSHKeywords.Open_Connection_To_ODL_System
    # Deploy the search tool.
    SSHLibrary.Put_File    ${CURDIR}/../../tools/deployment/search.sh
    SSHLibrary.Close_Connection
    # Optionally connect to the Tools System machine.
    IF    not (${tools_system_connect})    RETURN
    SSHKeywords.Open_Connection_To_Tools_System

NexusKeywords__Get_Items_To_Look_At
    [Documentation]    Get a list of items that might contain the version number that we are looking for.
    ...
    ...    &{COMPONENT_MAPPING} is the centralized place to maintain the mapping
    ...    from a stream independent component nickname to the list of artifact names to search for.
    [Arguments]    ${component}
    Collections.Dictionary_Should_Contain_Key
    ...    ${COMPONENT_MAPPING}
    ...    ${component}
    ...    Component not supported by NexusKeywords version detection: ${component}
    BuiltIn.Run_Keyword_And_Return    Collections.Get_From_Dictionary    ${COMPONENT_MAPPING}    ${component}

NexusKeywords__Detect_Version_To_Pull
    [Documentation]    Determine the exact Nexus directory to be used as a source for a particular test tool
    ...    Figure out what version of the tool needs to be pulled out of the
    ...    Nexus by looking at the version directory of the subsystem from
    ...    which the tool is being pulled. This code is REALLY UGLY but there
    ...    is no way around it until the bug
    ...    https://bugs.opendaylight.org/show_bug.cgi?id=5206 gets fixed.
    ...    I also don't want to depend on maven-metadata-local.xml and other
    ...    bits and pieces of ODL distribution which are not required for ODL
    ...    to function properly.
    [Arguments]    ${component}
    ${itemlist} =    NexusKeywords__Get_Items_To_Look_At    ${component}
    ${current_ssh_connection} =    SSHLibrary.Get Connection
    SSHKeywords.Open_Connection_To_ODL_System
    ${version}    ${result} =    SSHLibrary.Execute_Command
    ...    sh search.sh /home/odl/netconf-karaf-8.0.1-SNAPSHOT/system ${itemlist}
    ...    return_rc=True
    SSHLibrary.Close_Connection
    SSHKeywords.Restore Current SSH Connection From Index    ${current_ssh_connection.index}
    BuiltIn.Log    ${version}
    IF    ${result}!=0
        BuiltIn.Fail
        ...    Component "${component}": searching for "${itemlist}" found no version, cannot locate test tool.
    END
    ${version}    ${location} =    String.Split_String    ${version}    max_split=1
    RETURN    ${version}    ${location}

Deploy_From_Url
    [Documentation]    On active SSH conenction execute download ${url} command, log output, check RC and return file name.
    [Arguments]    ${url}
    ${filename} =    String.Fetch_From_Right    ${url}    /
    ${response}    ${result} =    SSHLibrary.Execute_Command    wget -q -N '${url}' 2>&1    return_rc=True
    BuiltIn.Log    ${response}
    IF    ${result} != 0
        BuiltIn.Fail    File ${filename} could not be downloaded from ${url}
    END
    RETURN    ${filename}

Deploy_Artifact
    [Documentation]    Deploy the specified artifact from Nexus to the cwd of the machine to which the active SSHLibrary connection points.
    ...    ${component} is a name part of an artifact present in system/ of ODl installation with the same version as ${artifact} should have.
    ...    Must have ${BUNDLE_URL} variable set to the URL from which the
    ...    tested ODL distribution was downloaded and this place must be
    ...    inside a repository created by a standard distribution
    ...    construction job. If this is detected to ne be the case, fallback URL is used.
    ...    If ${explicit_url} is non-empty, Deploy_From_Utrl is called instead.
    ...    TODO: Allow deploying to a specific directory, we have SSHKeywords.Execute_Command_At_Cwd_Should_Pass now.
    [Arguments]    ${component}    ${artifact}    ${name_prefix}=${artifact}-    ${name_suffix}=-executable.jar    ${fallback_url}=${NEXUS_FALLBACK_URL}    ${explicit_url}=${EMPTY}    ${build_version}=${EMPTY}    ${build_location}=${EMPTY}
    BuiltIn.Run_Keyword_And_Return_If    """${explicit_url}""" != ""    Deploy_From_Url    ${explicit_url}
    ${urlbase} =    String.Fetch_From_Left    ${BUNDLE_URL}    /org/opendaylight
    # If the BUNDLE_URL points somewhere else (perhaps *patch-test* job in Jenkins),
    # ${urlbase} is the whole ${BUNDLE_URL}, in which case we use the ${fallback_url}
    # If we are working with a "release integrated" project, we always will want to look for
    # a released version, not in the snapshots
    ${urlbase} =    BuiltIn.Set_Variable_If    '${urlbase}' != '${BUNDLE_URL}'    ${urlbase}    ${fallback_url}
    CompareStream.Run_Keyword_If_At_Most_Magnesium
    ...    Collections.Remove_Values_From_List
    ...    ${RELEASE_INTEGRATED_COMPONENTS}
    ...    carpeople
    CompareStream.Run_Keyword_If_At_Most_Aluminium
    ...    Collections.Remove_Values_From_List
    ...    ${RELEASE_INTEGRATED_COMPONENTS}
    ...    netconf
    CompareStream.Run_Keyword_If_At_Most_Silicon
    ...    Collections.Remove_Values_From_List
    ...    ${RELEASE_INTEGRATED_COMPONENTS}
    ...    bgpcep
    IF    '${build_version}'=='${EMPTY}'
        ${version}    ${location} =    NexusKeywords__Detect_Version_To_Pull    ${component}
    ELSE
        ${version}    ${location} =    BuiltIn.Set_Variable    ${build_version}    ${build_location}
    END
    IF    'SNAPSHOT' in '${version}'
        Collections.Remove_Values_From_List    ${RELEASE_INTEGRATED_COMPONENTS}    netconf    bgpcep
    END
    # check if the bundle url is pointing to a staging artifact
    # when we are pointing at a staged artifact we need to use the staging repo instead of release/snapshot artifacts
    ${is_staged} =    BuiltIn.Set_Variable_If
    ...    "opendaylight.release" not in '${urlbase}' and "opendaylight.snapshot" not in '${urlbase}'
    ...    "TRUE"
    ...    "FALSE"
    # if we have a staged artifact we need to use the urlbase given to us in the job params
    ${is_mri_component} =    BuiltIn.Set_Variable_If
    ...    '${component}' in ${RELEASE_INTEGRATED_COMPONENTS}
    ...    "TRUE"
    ...    "FALSE"
    ${urlbase} =    BuiltIn.Set_Variable_If
    ...    ${is_mri_component} == "TRUE" and ${is_staged} == "FALSE"
    ...    ${NEXUS_RELEASE_BASE_URL}
    ...    ${urlbase}
    # TODO: Use RequestsLibrary and String instead of curl and bash utilities?
    ${url} =    BuiltIn.Set_Variable    ${urlbase}/${location}/${artifact}/${version}
    # TODO: Review SSHKeywords for current best keywords to call.
    SSHKeywords.Open_Connection_To_ODL_System
    ${metadata} =    SSHKeywords.Execute_Command_Should_Pass    curl -L ${url}/maven-metadata.xml
    ${status}    ${namepart} =    BuiltIn.Run_Keyword_And_Ignore_Error
    ...    SSHKeywords.Execute_Command_Should_Pass
    ...    echo "${metadata}" | grep value | head -n 1 | cut -d '>' -f 2 | cut -d '<' -f 1
    ...    stderr_must_be_empty=${True}
    ${length} =    BuiltIn.Get_Length    ${namepart}
    ${namepart} =    BuiltIn.Set_Variable_If    "${status}" != "PASS" or ${length} == 0    ${version}    ${namepart}
    ${filename} =    BuiltIn.Set_Variable    ${name_prefix}${namepart}${name_suffix}
    BuiltIn.Log    ${filename}
    ${url} =    BuiltIn.Set_Variable    ${url}/${filename}
    ${response}    ${result} =    SSHLibrary.Execute_Command    wget -q -N '${url}' 2>&1    return_rc=True
    BuiltIn.Log    ${response}
    IF    ${result} == 0    RETURN    ${filename}
    # staged autorelease for non-mri project might not contain the artifact we need so we need to fallback to grabbing it from the release repo
    ${release_url} =    String.Replace_String_Using_Regexp    ${url}    autorelease-[0-9]{4}    opendaylight.release
    ${response}    ${result} =    SSHLibrary.Execute_Command    wget -q -N '${release_url}' 2>&1    return_rc=True
    IF    ${result} != 0
        BuiltIn.Fail
        ...    Artifact "${artifact}" in component "${component}" could not be downloaded from ${release_url} nor ${url}
    END
    RETURN    ${filename}

Deploy_Test_Tool
    [Documentation]    Deploy a test tool.
    ...    The test tools have naming convention of the form
    ...    "<repository_url>/some/dir/somewhere/<tool-name>/<tool-name>-<version-tag>-${suffix}.jar"
    ...    where "<tool-name>" is the name of the tool and "<version-tag>" is
    ...    the version tag that is digged out of the maven metadata. This
    ...    keyword calculates ${name_prefix} and ${name_suffix} for
    ...    "Deploy_Artifact" and then calls "Deploy_Artifact" to do the real
    ...    work of deploying the artifact.
    [Arguments]    ${component}    ${artifact}    ${suffix}=executable    ${fallback_url}=${NEXUS_FALLBACK_URL}    ${explicit_url}=${EMPTY}    ${build_version}=${EMPTY}    ${build_location}=${EMPTY}
    ${name_prefix} =    BuiltIn.Set_Variable    ${artifact}-
    ${extension} =    BuiltIn.Set_Variable_If    '${component}'=='odl-micro'    tar    jar
    ${name_suffix} =    BuiltIn.Set_Variable_If    "${suffix}" != ""    -${suffix}.${extension}    .${extension}
    ${filename} =    Deploy_Artifact
    ...    ${component}
    ...    ${artifact}
    ...    ${name_prefix}
    ...    ${name_suffix}
    ...    ${fallback_url}
    ...    ${explicit_url}
    ...    ${build_version}
    ...    ${build_location}
    RETURN    ${filename}

Install_And_Start_Java_Artifact
    [Documentation]    Deploy the artifact, assign name for log file, figure out java command, write the command to active SSH connection and return the log name.
    ...    This keyword does not examine whether the artifact was started successfully or whether is still running upon return.
    [Arguments]    ${component}    ${artifact}    ${suffix}=executable    ${tool_options}=${EMPTY}    ${java_options}=${EMPTY}    ${openjdk}=${JDKVERSION}
    ...    ${fallback_url}=${NEXUS_FALLBACK_URL}    ${explicit_url}=${EMPTY}
    # TODO: Unify this keyword with what NexusKeywords.Install_And_Start_Testtool does.
    ${actual_java_options} =    BuiltIn.Set_Variable_If
    ...    """${java_options}""" != ""
    ...    ${java_options}
    ...    ${JAVA_OPTIONS}
    ${filename} =    Deploy_Test_Tool    ${component}    ${artifact}    ${suffix}    ${fallback_url}    ${explicit_url}
    ${command} =    Compose_Full_Java_Command    ${actual_java_options} -jar ${filename} ${tool_options}
    ${logfile} =    Utils.Get_Log_File_Name    ${artifact}
    SSHLibrary.Write    ${command} >${logfile} 2>&1
    RETURN    ${logfile}

Compose_Dilemma_Filepath
    [Documentation]    Query active SSH connection, return specific path if it exists else default path.
    [Arguments]    ${default_path}    ${specific_path}
    ${out}    ${rc} =    SSHLibrary.Execute_Command    ls -lA ${specific_path} 2>&1    return_rc=True
    IF    ${rc} == 0    RETURN    ${specific_path}
    RETURN    ${default_path}

Compose_Base_Java_Command
    [Documentation]    Return string suitable for launching Java programs over SSHLibrary, depending on JRE version needed.
    ...    This requires that the SSH connection on which the command is going to be used is active as it is needed for querying files.
    ...    Commands composed for one SSH connection shall not be reused on other SSH connections as the two connections may have different Java setups.
    ...    Not directly related to Nexus, but versioned Java tools may need this.
    [Arguments]    ${openjdk}=${JDKVERSION}
    # Check whether the user set the override and return it if yes.
    BuiltIn.Run_Keyword_And_Return_If
    ...    """${openjdk}""" == "openjdk8"
    ...    Compose_Dilemma_Filepath
    ...    ${JAVA_8_HOME_CENTOS}/bin/java
    ...    ${JAVA_8_HOME_UBUNTU}/bin/java
    BuiltIn.Run_Keyword_And_Return_If
    ...    """${openjdk}""" == "openjdk11"
    ...    Compose_Dilemma_Filepath
    ...    ${JAVA_11_HOME_CENTOS}/bin/java
    ...    ${JAVA_11_HOME_UBUNTU}/bin/java
    BuiltIn.Run_Keyword_And_Return_If
    ...    """${openjdk}""" == "openjdk17"
    ...    Compose_Dilemma_Filepath
    ...    ${JAVA_17_HOME_CENTOS}/bin/java
    ...    ${JAVA_17_HOME_UBUNTU}/bin/java
    BuiltIn.Run_Keyword_And_Return_If
    ...    """${openjdk}""" == "openjdk21"
    ...    Compose_Dilemma_Filepath
    ...    ${JAVA_21_HOME_CENTOS}/bin/java
    ...    ${JAVA_21_HOME_UBUNTU}/bin/java
    # Attempt to call plain "java" command directly. If it works, return it.
    ${out}    ${rc} =    SSHLibrary.Execute_Command    java -version 2>&1    return_rc=True
    IF    ${rc} == 0    RETURN    java
    # Query the virtual machine for the JAVA_HOME environment variable and
    # use it to assemble a (hopefully) working command. If that worked out,
    # return the result.
    ${java} =    SSHLibrary.Execute_Command    echo $JAVA_HOME/bin/java 2>&1
    ${out}    ${rc} =    SSHLibrary.Execute_Command    ${java} -version 2>&1    return_rc=True
    IF    ${rc} == 0    RETURN    ${java}
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
    IF    ${rc} == 0    RETURN    ${java}
    # Nothing works, most likely java is not installed at all on the target
    # machine or it is hopelesly lost. Bail out with a helpful message
    # telling the user how to make it accessible for the script.
    BuiltIn.Fail
    ...    Unable to find Java; specify \${JDKVERSION}, put it to your PATH or set JAVA_HOME environment variable.

Compose_Full_Java_Command
    [Documentation]    Return full Bash command to run Java with given options.
    ...    This requires that the SSH connection on which the command is going to be used is active as it is needed for querying files.
    ...    The options may include JVM options, application command line arguments, Bash redirects and other constructs.
    [Arguments]    ${options}    ${openjdk}=${JDKVERSION}
    ${base_command} =    Compose_Base_Java_Command    openjdk=${openjdk}
    ${full_command} =    BuiltIn.Set_Variable    ${base_command} ${options}
    BuiltIn.Log    ${full_command}
    RETURN    ${full_command}

Compose_Java_Home
    [Documentation]    Compose base java command and strip trailing "/bin/java".
    [Arguments]    ${openjdk}=${JDKVERSION}
    ${java_command} =    Compose_Base_Java_Command
    ${java_home}    ${bin}    ${java} =    String.Split_String_From_Right
    ...    ${java_command}
    ...    separator=/
    ...    max_split=2
    RETURN    ${java_home}

Install_Maven_Bare
    [Documentation]    Download and unpack Maven, prepare launch command with proper Java version and download settings file.
    ...    This Keyword requires an active SSH connection to target machine.
    ...    This Keyword sets global variables, so that suites can reuse existing installation.
    ...    This Keyword can only place Maven (and settings) to remote current working directory.
    ...    This Keyword does not perform any initial or final cleanup.
    [Arguments]    ${maven_version}=3.3.9    ${openjdk}=${JDKVERSION}
    # Avoid multiple initialization by several downstream libraries.
    ${installed_version} =    BuiltIn.Get_Variable_Value    \${Maven__installed_version}    None
    IF    """${installed_version}""" == """${maven_version}"""    RETURN
    BuiltIn.Set_Global_Variable    \${Maven__installed_version}    ${maven_version}
    BuiltIn.Set_Global_Variable    \${maven_directory}    apache-maven-${maven_version}
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -rf '${maven_directory}'
    ${maven_archive_filename} =    BuiltIn.Set_Variable    ${maven_directory}-bin.tar.gz
    ${maven_download_url} =    BuiltIn.Set_Variable
    ...    http://www-us.apache.org/dist/maven/maven-3/${maven_version}/binaries/${maven_archive_filename}
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    wget -N '${maven_download_url}'    stderr_must_be_empty=False
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    tar xvf '${maven_archive_filename}'
    ${java_home} =    NexusKeywords.Compose_Java_Home    openjdk=${openjdk}
    BuiltIn.Set_Global_Variable
    ...    \${maven_bash_command}
    ...    export JAVA_HOME='${java_home}' && export MAVEN_OPTS='${JAVA_OPTIONS}' && ./${maven_directory}/bin/mvn
    # TODO: Get settings files from Jenkins settings provider, somehow.
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    wget '${MAVEN_SETTINGS_URL}' -O settings.xml
    ...    stderr_must_be_empty=False

Install_Maven
    [Documentation]    Install Maven.
    ...    Depending on arguments, perform a multipatch build to populate local Maven repository with patched artifacts.
    [Arguments]    ${maven_version}=3.3.9    ${openjdk}=${JDKVERSION}    ${branch}=${EMPTY}    ${patches}=${EMPTY}
    Install_Maven_Bare    maven_version=${maven_version}    openjdk=${openjdk}
    IF    """${patches}""" == ""    RETURN    No post-install build requested.
    IF    """${branch}""" == ""
        BuiltIn.Fail    BRANCH needs to be specified for multipatch builds.
    END
    ${script_name} =    BuiltIn.Set_Variable    include-raw-integration-multipatch-distribution-test.sh
    ${script_url} =    BuiltIn.Set_Variable
    ...    https://raw.githubusercontent.com/opendaylight/releng-builder/master/jjb/integration/${script_name}
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    wget -N '${script_url}'    stderr_must_be_empty=False
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    export WORKSPACE='${WORKSPACE}' && export BRANCH='${branch}' && export PATCHES_TO_BUILD='${patches}' && bash '${script_name}'
    ...    stderr_must_be_empty=False
    Run_Maven    pom_file=${WORKSPACE}/patch_tester/pom.xml

Run_Maven
    [Documentation]    Determine arguments to use and call mvn command against given pom file.
    [Arguments]    ${pom_file}=pom.xml    ${log_file}=${MAVEN_DEFAULT_OUTPUT_FILENAME}
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    mkdir -p '${MAVEN_REPOSITORY_PATH}'
    ${maven_repository_options} =    BuiltIn.Set_Variable
    ...    -Dmaven.repo.local=${MAVEN_REPOSITORY_PATH} -Dorg.ops4j.pax.url.mvn.localRepository=${MAVEN_REPOSITORY_PATH}
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass
    ...    ${maven_bash_command} clean install dependency:tree -V -B -DoutputFile=dependency_tree.log -s './settings.xml' -f '${pom_file}' ${MAVEN_OPTIONS} ${maven_repository_options} > '${log_file}'

Get_ODL_Versions_From_Nexus
    [Documentation]    Returns name of last release found on nexus and list of all versions.
    RequestsLibrary.Create_Session    nexus    ${NEXUS_RELEASES_URL}    verify=${TRUE}
    ${uri} =    BuiltIn.Set_Variable    maven-metadata.xml
    ${response} =    RequestsLibrary.GET On Session    nexus    url=${uri}
    BuiltIn.Log    ${response.text}
    ${root} =    XML.Parse_XML    ${response.text}
    ${element} =    XML.Get_Element    ${root}    versioning/latest
    ${latest} =    BuiltIn.Set_Variable    ${element.text}
    BuiltIn.Log    ${latest}
    @{elements} =    XML.Get_Elements    ${root}    .//version
    ${versions} =    BuiltIn.Create_List
    FOR    ${element}    IN    @{elements}
        Collections.Append_To_List    ${versions}    ${element.text}
    END
    Collections.Sort_List    ${versions}
    BuiltIn.Log_Many    @{versions}
    RETURN    ${latest}    @{versions}

Get_Latest_ODL_Release_From_Nexus
    [Documentation]    Returns name of last release found on nexus
    ${latest}    @{versions} =    Get_ODL_Versions_From_Nexus
    RETURN    ${latest}

Get_Latest_ODL_Stream_Release
    [Documentation]    Returns name for last release for specified stream.
    [Arguments]    ${stream}=latest
    ${latest}    @{versions} =    Get_ODL_Versions_From_Nexus
    IF    '${stream}'=='latest'    RETURN    ${latest}
    ${latest_version} =    BuiltIn.Set_Variable    xxx
    FOR    ${version}    IN    @{versions}
        ${latest_version} =    BuiltIn.Set_Variable_If
        ...    '${stream}'.title() in '${version}'
        ...    ${version}
        ...    ${latest_version}
    END
    IF    '${latest_version}'=='xxx'
        BuiltIn.Fail    Could not find latest release for stream ${stream}
    END
    BuiltIn.Log    ${latest_version}
    RETURN    ${latest_version}

Get_Latest_ODL_Stream_Release_URL
    [Documentation]    Returns URL for last release for specified stream. Default format is .zip.
    [Arguments]    ${stream}=latest    ${format}=.zip
    ${latest_version} =    Get_Latest_ODL_Stream_Release    ${stream}
    ${url} =    BuiltIn.Set_Variable    ${NEXUS_RELEASES_URL}/${latest_version}/karaf-${latest_version}${format}
    BuiltIn.Log    ${url}
    RETURN    ${url}

Get_Latest_ODL_Previous_Stream_Release
    [Documentation]    Returns name for last release for previous stream of specified stream.
    ...    Note: If specified stream is not found on nexus, then it is taken as new one (not released yet).
    ...    So in this case, latest release version is return.
    ...
    ...    NOTE: the below logic is stripping the initial 0. values from the 0.x.x version string that is
    ...    the current (and future) version numbering scheme. There is always a leading 0. to the version
    ...    strings and stripping it makes is easier to do int comparison to find the largest version in the
    ...    list. Comparing as strings does not work. There are some python libs like distutils.version
    ...    or packaging that can do a better job comparing versions, but since ODL version numbering is simple
    ...    at this point, this convention will suffice. The leading 0. will be added back after the the latest
    ...    version is found from the list. The CompareStream.robot library keeps a mapping of major version
    ...    numbers to the global variable ${ODL_STREAM} so that is used to ensure we get a major version that is
    ...    older than the current running major version.
    [Arguments]    ${stream}=${ODL_STREAM}
    ${latest}    @{versions} =    Get_ODL_Versions_From_Nexus
    ${current_version} =    BuiltIn.Set_Variable    ${Stream_dict}[${ODL_STREAM}].0
    ${latest_version} =    BuiltIn.Set_Variable    0.0
    FOR    ${version}    IN    @{versions}
        ${version} =    String.Replace String Using Regexp    ${version}    ^0\.    ${EMPTY}
        ${latest_version} =    Set Variable If
        ...    ${version} > ${latest_version} and ${version} < ${current_version}
        ...    ${version}
        ...    ${latest_version}
    END
    ${latest_version} =    Set Variable    0.${latest_version}
    IF    '${latest_version}'=='0.0.0'
        BuiltIn.Fail    Could not find latest previous release for stream ${stream}
    END
    BuiltIn.Log    ${latest_version}
    RETURN    ${latest_version}

Get_Latest_ODL_Previous_Stream_Release_URL
    [Documentation]    Returns URL for last release for previous stream of specified stream. Default format is .zip.
    [Arguments]    ${stream}=${ODL_STREAM}    ${format}=.zip
    ${latest_version} =    Get_Latest_ODL_Previous_Stream_Release    ${stream}
    ${url} =    BuiltIn.Set_Variable    ${NEXUS_RELEASES_URL}/${latest_version}/karaf-${latest_version}${format}
    BuiltIn.Log    ${url}
    RETURN    ${url}
