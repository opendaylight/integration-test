*** Settings ***
Documentation       Test suite for OpenFlow Groups and Meters

Library             SSHLibrary
Resource            ../../../libraries/Utils.robot
Variables           ../../../variables/Variables.py

Suite Setup         Start Mininet
Suite Teardown      Stop Mininet


*** Variables ***
${start}    sudo mn --controller=remote,ip=${ODL_SYSTEM_IP} --topo tree,1 --switch user
