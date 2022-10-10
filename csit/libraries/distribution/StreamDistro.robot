*** Settings ***
Documentation       Distribution testing: generate stream-dependent values.
...
...                 Copyright (c) 2017 Cisco Systems, Inc. and others. All rights reserved.
...
...                 This program and the accompanying materials are made available under the
...                 terms of the Eclipse Public License v1.0 which accompanies this distribution,
...                 and is available at http://www.eclipse.org/legal/epl-v10.html
...
...
...                 As newer ODL versions are released, some values evolve from previously hardcoded constants.
...                 This Resource contains keywords for optaining the correct value for currently testes stream.

Library             Collections


*** Keywords ***
Compose_Zip_Filename_Prefix
    [Documentation]    Return "karaf"
    RETURN    karaf

Compose_Test_Feature_Repo_Name
    [Documentation]    Return "features-test"
    RETURN    features-test
