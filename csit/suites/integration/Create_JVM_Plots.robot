*** Settings ***
Documentation     Test suite to Plot JVM Resources
Resource          ${CURDIR}/../../../libraries/CheckJVMResource.robot

*** Test Cases ***
Create JVM Plots
    CheckJVMResource.Create JVM Plots
