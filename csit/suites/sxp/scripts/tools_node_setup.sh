#!/bin/bash
TOOLS_WORK_DIR="/tmp"

echo "Extracting the new controller... [${TOOLS_SYSTEM_IP}]"
ssh ${TOOLS_SYSTEM_IP} wget --progress=dot:mega ${ACTUALBUNDLEURL} -P ${TOOLS_WORK_DIR}
ssh ${TOOLS_SYSTEM_IP} unzip -q ${TOOLS_WORK_DIR}/${BUNDLE} -d ${TOOLS_WORK_DIR}

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
TOOLS_FEATURESCONF=${TOOLS_WORK_DIR}/${BUNDLEFOLDER}/etc/org.apache.karaf.features.cfg
ssh ${TOOLS_SYSTEM_IP} "sed -ie \"s/featuresBoot=.*/featuresBoot=config,standard,region,package,kar,ssh,management,${ACTUALFEATURES}/g\" ${TOOLS_FEATURESCONF}"

echo "Starting controller..."
ssh ${TOOLS_SYSTEM_IP} "${TOOLS_WORK_DIR}/${BUNDLEFOLDER}/bin/start"

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
        COUNT=$(( ${COUNT} + 5 ))
        sleep 5
        echo waiting ${COUNT} secs...
    fi
done