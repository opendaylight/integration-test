*** Settings ***
Documentation     Devstack setup checking
Suite Setup       Start Devstack setup
Suite Teardown    Stop Devstack
Resource          ../../../libraries/DevStackKeywords.robot

*** Test Cases ***
Create the devstack setup
    [Documenatation]   Toverify the setup
    Wait Until Keyword SucceedsStart     100s     10s     Devstack setup
