#!/bin/bash
interface=$(ifconfig -a | grep eth0 | cut -d' ' -f 1)
if [[ $# -eq 1 ]]
then
    echo $1
    tcpdump -XX -n -i `ifconfig -a | grep eth0 | cut -d' ' -f 1` > $1
else
    tcpdump -XX -n -i `ifconfig -a | grep eth0 | cut -d' ' -f 1` > ${interface}_tcpdump.txt
fi
