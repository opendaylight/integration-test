*** Settings ***
Documentation     Test suite for L2switch's Flow Programming using mininet OF13
Suite Setup       Start Suite
Suite Teardown    Stop Suite
Library           SSHLibrary
Resource          ../../../libraries/Utils.txt

*** Variables ***
${start}          sudo mn --controller=remote,ip=${CONTROLLER} --topo=tree,2 --switch ovsk,protocols=OpenFlow13
