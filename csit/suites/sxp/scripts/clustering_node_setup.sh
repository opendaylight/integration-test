#!/bin/bash
WORK_DIR="/tmp"

echo "Extracting the new controller... [${TOOLS_SYSTEM_IP}]"
ssh ${TOOLS_SYSTEM_IP} wget --progress=dot:mega ${ACTUALBUNDLEURL} -P ${WORK_DIR}
ssh ${TOOLS_SYSTEM_IP} unzip -q ${WORK_DIR}/${BUNDLE} -d ${WORK_DIR}

echo "Configuring the startup features..."
FEATURESCONF=${WORK_DIR}/${BUNDLEFOLDER}/etc/org.apache.karaf.features.cfg
CUSTOMPROP=${WORK_DIR}/${BUNDLEFOLDER}/etc/custom.properties
ssh ${TOOLS_SYSTEM_IP} "sed -ie \"s/featuresBoot=.*/featuresBoot=config,standard,region,package,kar,ssh,management,${ACTUALFEATURES}/g\" \${FEATURESCONF}"
ssh ${TOOLS_SYSTEM_IP} "sed -ie \"s%mvn:org.opendaylight.integration/features-integration-index/${BUNDLEVERSION}/xml/features%mvn:org.opendaylight.integration/features-integration-index/${BUNDLEVERSION}/xml/features,mvn:org.opendaylight.integration/features-integration-test/${BUNDLEVERSION}/xml/features,mvn:org.apache.karaf.decanter/apache-karaf-decanter/1.0.0/xml/features%g\" \${FEATURESCONF}"
ssh ${TOOLS_SYSTEM_IP} "cat \${FEATURESCONF}"

echo "Starting controller..."
ssh ${TOOLS_SYSTEM_IP} /tmp/${BUNDLEFOLDER}/bin/start
