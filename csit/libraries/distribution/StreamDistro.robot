*** Settings ***
Documentation     Distribution testing: generate stream-dependent values.
...           
...               Copyright (c) 2017 Cisco Systems, Inc. and others. All rights reserved.
...           
...               This program and the accompanying materials are made available under the
...               terms of the Eclipse Public License v1.0 which accompanies this distribution,
...               and is available at http://www.eclipse.org/legal/epl-v10.html
...           
...           
...               As newer ODL versions are released, some values evolve from previously hardcoded constants.
...               This Resource contains keywords for optaining the correct value for currently testes stream.
Library           Collections
Resource          ${CURDIR}/../CompareStream.robot

*** Keywords ***
Compose_Zip_Filename_Prefix
    [Documentation]    Return "karaf" if at least Nitrogen, else return "distribution-karaf".
    BuiltIn.Run_Keyword_And_Return    CompareStream.Set_Variable_If_At_Least_Nitrogen    karaf    distribution-karaf

Compose_Test_Feature_Repo_Name
    [Documentation]    Return "features-test" if at least Nitrogen, else return "features-integration-test".
    BuiltIn.Run_Keyword_And_Return    CompareStream.Set_Variable_If_At_Least_Nitrogen    features-test    features-integration-test
