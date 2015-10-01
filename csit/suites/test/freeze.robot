*** Settings ***
Documentation     Not a test, it just logs versions of installed Python modules.
...               Useful when library documentation mentions version-specific behavior.
Library           OperatingSystem

*** Test Cases ***
Freeze
    ${versions} =    OperatingSystem.Run    pip freeze
    BuiltIn.Log    ${versions}
