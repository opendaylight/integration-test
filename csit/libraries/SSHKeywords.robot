*** Settings ***
Documentation     Keywords for operations executed on remote machines through SSH.
...
...               Copyright (c) 2015 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               All keywords defined here operate on currently active
...               SSHLibrary connection, unless noted otherwise in the
...               documentation of the keyword.
Library           SSHLibrary

*** Variables ***
${directory_for_schemas}    schemas

*** Keywords ***
SSHKeywords__Deploy_Additional_Schemas
    [Arguments]    ${schemas}
    [Documentation]    Internal keyword for Install_And_Start_TestTool
    ...    Needed to have this in a separate keyword because Robot does not
    ...    support conditional assignments to a local variable. This deploys
    ...    the additional schemas if any and returns a command line argument
    ...    to be added to the testtool commandline to tell it to load them.
    # Make sure there is no schemas directory on the remote machine. A
    # previous test suite might have left some debris there and that might
    # lead to spurious failures, so it is better to make sure we start with a
    # clean slate. Additionally when the caller did not specify any
    # additional schemas for testtool, we want to make extra sure none are
    # used.
    ${response}=    SSHLibrary.Execute_Command    rm -rf ${directory_for_schemas}
    BuiltIn.Log    ${response}
    # Drop out of the keyword, returning no command line argument when there
    # are no additional schemas to deploy.
    BuiltIn.Return_From_Keyword_If    '${schemas}' == 'none'    ${EMPTY}
    # Deploy the additional schemas into a standard directory on the remote
    # machine and construct a command line argument pointing to that
    # directory from the point of view of the process running on that
    # machine.
    SSHLibrary.Put_Directory    ${schemas}    destination=./${directory_for_schemas}
    [Return]    --schemas-dir \$HOME/${directory_for_schemas}

Install_And_Start_Testtool
    [Arguments]    ${device-count}=10    ${debug}=true    ${schemas}=none
    [Documentation]    Install and run testtool.
    # Install test tool on the machine.
    ${urlbase}=    BuiltIn.Set_Variable    ${NEXUSURL_PREFIX}/content/repositories/opendaylight.snapshot/org/opendaylight/netconf/netconf-testtool
    ${version}=    SSHLibrary.Execute_Command    curl ${urlbase}/maven-metadata.xml | grep '<version>' | cut -d '>' -f 2 | cut -d '<' -f 1
    BuiltIn.Log    ${version}
    ${namepart}=    SSHLibrary.Execute_Command    curl ${urlbase}/${version}/maven-metadata.xml | grep value | head -n 1 | cut -d '>' -f 2 | cut -d '<' -f 1
    BuiltIn.Log    ${namepart}
    BuiltIn.Set_Suite_Variable    ${filename}    netconf-testtool-${namepart}-executable.jar
    BuiltIn.Log    ${filename}
    ${response}=    SSHLibrary.Execute_Command    curl ${urlbase}/${version}/${filename} >${filename}
    BuiltIn.Log    ${response}
    ${schemas_option}=    SSHKeywords__Deploy_Additional_Schemas    ${schemas}
    # Start the testtool
    SSHLibrary.Write    java -Xmx1G -XX:MaxPermSize=256M -jar ${filename} --device-count ${device-count} --debug ${debug} ${schemas_option} >testtool.log 2>&1

Stop_Testtool
    [Documentation]    Stop testtool and download its log.
    Utils.Write_Bare_Ctrl_C
    # TODO: Replace with WUKS checking that there are no more Java processes.
    # TODO: If that WUKS fails, send kill -9 to the Java process(es) (killall
    #    might not be there so this can get tricky). Maybe sending Ctrl-Z
    #    and then "kill -9 %1" would do the trick.
    BuiltIn.Sleep    5s
    SSHLibrary.Get_File    testtool.log
