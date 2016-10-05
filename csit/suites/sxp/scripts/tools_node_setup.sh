#!/bin/bash
WORK_DIR="/tmp"

echo "Extracting the new controller... [${TOOLS_SYSTEM_IP}]"
ssh ${TOOLS_SYSTEM_IP} wget --progress=dot:mega ${ACTUALBUNDLEURL} -P ${WORK_DIR}
ssh ${TOOLS_SYSTEM_IP} unzip -q ${WORK_DIR}/${BUNDLE} -d ${WORK_DIR}

echo "Set Java version"
if [ ${JDKVERSION} == 'openjdk8' ]; then
    DISTRO=`ssh ${TOOLS_SYSTEM_IP} "cat /etc/*-release | grep -i -c ubuntu"`
    if [ ${DISTRO} == '0' ]; then
        JAVA_HOME="/usr/lib/jvm/java-1.8.0"
    else
        JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64"
    fi
    ssh ${TOOLS_SYSTEM_IP} "sudo update-alternatives --install /usr/bin/java java ${JAVA_HOME}/bin/java 1"
    ssh ${TOOLS_SYSTEM_IP} "sudo update-alternatives --set java ${JAVA_HOME}/bin/java"
    echo "JDK default version ..."
    ssh ${TOOLS_SYSTEM_IP} "java -version"
fi

echo "Starting controller..."
ssh ${TOOLS_SYSTEM_IP} "${WORK_DIR}/${BUNDLEFOLDER}/bin/start"

echo "Waiting for controller to come up..."
COUNT="0"
while true; do
    RESP=`nc -w3 ${TOOLS_SYSTEM_IP} 8181 && echo "UP" || echo "DOWN"`
    ssh ${TOOLS_SYSTEM_IP} "${WORK_DIR}/${BUNDLEFOLDER}/bin/status"
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