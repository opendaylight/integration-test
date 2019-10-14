*** Settings ***
Documentation     Resource for preparing various sets of Yang files to be used in testing.
...
...               Copyright (c) 2016 Cisco Systems, Inc. and others. All rights reserved.
...
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...               Keywords in this Resource assume there is an active SSH connection
...               to system where a particular set of Yang files is to be created.
...               The keywords will change current working directory used by SSHKeywords.
...
...               Currently only one set is supported, called Static.
...               The set will not change in future
...               and it does not include files which lead to binding v1 bugs.
...
...               TODO: Do we want to support Windoes path separators?
Resource          ${CURDIR}/SSHKeywords.robot

*** Keywords ***
Static_Set_As_Src
    [Arguments]    ${root_dir}=.
    [Documentation]    Cleanup possibly leftover directories (src and target), clone git repos and remove unwanted paths.
    SSHKeywords.Set_Cwd    ${root_dir}
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -rf target src
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    mkdir -p src/main
    SSHKeywords.Set_Cwd    ${root_dir}/src/main
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    git clone https://github.com/YangModels/yang    stderr_must_be_empty=False
    SSHKeywords.Set_Cwd    ${root_dir}/src/main/yang
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -rf .git
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -rf tools
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -rf experimental
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    git clone https://github.com/openconfig/public    stderr_must_be_empty=False
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    mv -v public openconfig
    SSHKeywords.Set_Cwd    ${root_dir}/src/main/yang/openconfig
    SSHKeywords.Execute_Command_At_Cwd_Should_Pass    rm -rf .git
    SSHKeywords.Set_Cwd    ${root_dir}/src/main/yang
