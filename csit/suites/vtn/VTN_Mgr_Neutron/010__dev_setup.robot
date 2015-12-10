*** Settings ***
Documentation     Devstack setup checking
Suite Setup       Devstacksetup
Suite Teardown    Stop Devstack
Resource          ../../../libraries/DevStackKeywords.robot

*** Test Cases ***
Create the devstak setup
    [Documentation]    Toverfiy the setup success are not
    Devstacksetup 
