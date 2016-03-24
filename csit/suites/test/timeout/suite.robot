*** Settings ***
Documentation    A simple example how to use [Timeout] and have [Teardown] succeed.

*** Test Cases ***
Baz
    Bar

*** Keywords ***
Tear
    BuiltIn.Log_To_Console    Timeout excepted successfully!

Foo
    [Timeout]    1s
    BuiltIn.Sleep    2s

Bar
    [Timeout]    NONE
    Foo
    [Teardown]    Tear
