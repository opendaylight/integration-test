*** Settings ***
Documentation     Test suite for usecpluginaaa
Suite Setup      Issue Command On Karaf Console    ${cmd}     ${ODL_SYSTEM_IP}    ${KARAF_SHELL_PORT}    5

Library           SSHLibrary
Library           String

Library           Process
Library           Collections


Resource           ../../../libraries/KarafKeywords.robot
Variables         ../../../variables/Variables.py


*** Variables ***
${cmd}            log:set DEBUG org.opendaylight.aaa.shiro.filters



