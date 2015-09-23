*** Settings ***
Documentation     Test suite for the OpenDaylight OpenFlow statistics manager
Suite Setup       Start Suite
Suite Teardown    Stop Suite
Library           SSHLibrary
Resource           ../../../../libraries/Utils.robot


*** Variables ***
${start}          sudo mn --controller=remote,ip=${CONTROLLER} --topo tree,1 --switch ovsk,protocols=OpenFlow13
