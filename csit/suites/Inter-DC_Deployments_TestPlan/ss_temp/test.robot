*** Settings ***
Library           Collections
Library 	  String

*** Test Cases ***
CheckInvalidLogin
    ${value}    Set Variable    2200:2
    ${TextFileContent}    Get File    TestFile.txt
    Log To Console    ${TextFileContent}
#    Should Match Regexp    ${TextFileContent}    .*export-RT.*\\n.*${value}.*
#    Should Match Regexp    ${TextFileContent}    .*import-RT.*\\n.*${value}.*
#    #\\n"2200.*
