*** Settings ***
Documentation     Keywords relating to Netconf in the controller (such as mounting, deleting etc)
Library           String
Library           OperatingSystem
Library           ../../libraries/RequestsLibrary.py

*** Variables ***
${CONTROLLER}     127.0.0.1
${RESTCONFPORT}    8181
${USER}           root
${PWD}            pwd
${MININET}        127.0.0.1
${MININET_USER}    mininet
${MININET_PASSWD}    rsa_id
${LINUX_PROMPT}    ]#
${installdir}     /tmp/${BUNDLEFOLDER}
${startcommand}    ${installdir}/bin/start
${startport}      17830
${ttnumberofdevices}    10000
${batchsize}      4000
${ttlocation}     /tmp/netconf-testtool
${ttstartcommand}    java -Dorg.apache.sshd.registerBouncyCastle=false -Xmx2G -XX:MaxPermSize=256M -jar ${ttlocation}/netconf-testtool-0.3.0-SNAPSHOT-executable.jar --ssh true --generate-configs-batch-size ${batchsize} --exi false --generate-config-connection-timeout 10000000 --generate-config-address ${MININET} --device-count ${ttnumberofdevices} --distribution-folder ${ttdistribution} --starting-port ${startport} --debug false
${ttdistribution}    /tmp/opendaylight
${featurepath}    /system/org/opendaylight/controller/
${devicestolerance}    5
${Timestamps}     ${EMPTY}
${tuple}          ${EMPTY}
${error}          ${EMPTY}
${delta}          ${EMPTY}
${missing}        ${EMPTY}
${Partialtimestamps}    ${EMPTY}
@{Timestamps}
@{Partialtimestamps}
@{Replycodes}
${Mountpoints}    0
${Maxdevices}     0
${Replycodes}     ${EMPTY}
