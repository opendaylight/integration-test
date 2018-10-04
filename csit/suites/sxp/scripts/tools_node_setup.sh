#!/bin/bash

TOOLS_WORK_DIR="/tmp"
wget "https://git.opendaylight.org/gerrit/gitweb?p=sxp.git;a=blob_plain;f=sxp-core/pom.xml;hb=refs/heads/master" -O "pom.xml"
SXP_VERSION=`xmllint --xpath '/*[local-name()="project"]/*[local-name()="parent"]/*[local-name()="version"]/text()' pom.xml`
NEXUS_URL=https://nexus.opendaylight.org/content/repositories/opendaylight.snapshot/org/opendaylight/sxp/sxp-karaf/${SXP_VERSION}
wget ${NEXUS_URL}/maven-metadata.xml -O maven-metadata.xml
REVISION=`awk -vRS="</value>" '{gsub(/.*<value.*>/,"");print}' maven-metadata.xml | sed -n 1p`
SXP_BUNDLE_URL=${NEXUS_URL}/sxp-karaf-${REVISION}.zip

echo "Extracting the new controller [${TOOLS_SYSTEM_IP}] with ODL: [${SXP_BUNDLE_URL}]"
ssh ${TOOLS_SYSTEM_IP}
ssh ${TOOLS_SYSTEM_IP} wget --progress=dot:mega ${SXP_BUNDLE_URL} -P ${TOOLS_WORK_DIR}
ssh ${TOOLS_SYSTEM_IP} unzip -q ${TOOLS_WORK_DIR}/sxp-karaf-${REVISION}.zip -d ${TOOLS_WORK_DIR}

echo "Set Java version"
if [ ${JDKVERSION} == 'openjdk8' ]; then
    TOOLS_DISTRO=`ssh ${TOOLS_SYSTEM_IP} "cat /etc/*-release | grep -i -c ubuntu"`
    if [ ${TOOLS_DISTRO} == '0' ]; then
        TOOLS_JAVA_HOME="/usr/lib/jvm/java-1.8.0"
    else
        TOOLS_JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64"
    fi
    ssh ${TOOLS_SYSTEM_IP} "sudo update-alternatives --install /usr/bin/java java ${TOOLS_JAVA_HOME}/bin/java 1"
    ssh ${TOOLS_SYSTEM_IP} "sudo update-alternatives --set java ${TOOLS_JAVA_HOME}/bin/java"
    echo "JDK default version ..."
    ssh ${TOOLS_SYSTEM_IP} "java -version"
fi

echo "Configuring the startup features..."
TOOLS_FEATURESCONF=${TOOLS_WORK_DIR}/sxp-karaf-${SXP_VERSION}/etc/org.apache.karaf.features.cfg
ssh ${TOOLS_SYSTEM_IP} "sed -r -i.old \"s/featuresBoot ?=.*/featuresBoot=config,standard,region,package,kar,ssh,management,${ACTUALFEATURES},odl-sxp-core,odl-sxp-controller/g\" ${TOOLS_FEATURESCONF}"

echo "Starting controller..."
ssh ${TOOLS_SYSTEM_IP} "${TOOLS_WORK_DIR}/sxp-karaf-${SXP_VERSION}/bin/start"

echo "Waiting for controller to come up..."
COUNT="0"
while true; do
    RESP=`nc -w3 ${TOOLS_SYSTEM_IP} 8181 && echo "UP" || echo "DOWN"`
    if [[ "${RESP}" == "UP" ]]; then
        echo Controller is UP
        break
    elif (( "$COUNT" > "600" )); then
        echo Timeout Controller DOWN
        exit 1
    else
        COUNT=$(( ${COUNT} + 1 ))
        sleep 1
        if [[ $(($COUNT % 5)) == 0 ]]; then
            echo already waited ${COUNT} seconds...
        fi
    fi
done
