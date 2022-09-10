*** Settings ***
Documentation       Test suite to Plot JVM Resources

Resource            ${CURDIR}/../../libraries/CheckJVMResource.robot


*** Test Cases ***
Create JVM Plots
    BuiltIn.Run Keyword And Ignore Error    CheckJVMResource.Create JVM Plots
