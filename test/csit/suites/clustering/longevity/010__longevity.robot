*** Settings ***
Documentation     Test suite for Longevity test of cluster datastore
Library           ../../../../libraries/CrudLibrary.py

*** Variables ***


*** Test Cases ***
Run Tests in Loop for Specified Time
    [Documentation]    Run CRUD operation from nodes for specified time
  Testlongevity  ${DURATION}  ${PORT}  ${IP1}  ${IP2}  ${IP3}
