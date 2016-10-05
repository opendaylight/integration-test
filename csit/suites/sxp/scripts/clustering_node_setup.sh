#!/bin/bash

echo "Download and start Karaf in ${TOOLS_SYSTEM_IP}"
echo "Extracting the new controller..."
ssh ${TOOLS_SYSTEM_IP} cd /tmp && \
                        wget --progress=dot:mega ${ACTUALBUNDLEURL} && \
                        unzip -q /tmp/${BUNDLE}
ssh ${TOOLS_SYSTEM_IP} ls /tmp

echo "Configuring the startup features..."
ssh ${TOOLS_SYSTEM_IP} sed -ie "s/featuresBoot=.*/featuresBoot=config,standard,region,package,kar,ssh,management,${ACTUALFEATURES}/g" \${FEATURESCONF}
ssh ${TOOLS_SYSTEM_IP} sed -ie "s%mvn:org.opendaylight.integration/features-integration-index/${BUNDLEVERSION}/xml/features%mvn:org.opendaylight.integration/features-integration-index/${BUNDLEVERSION}/xml/features,mvn:org.opendaylight.integration/features-integration-test/${BUNDLEVERSION}/xml/features,mvn:org.apache.karaf.decanter/apache-karaf-decanter/1.0.0/xml/features%g" \${FEATURESCONF}

echo "Starting controller..."
ssh ${TOOLS_SYSTEM_IP} /tmp/${BUNDLEFOLDER}/bin/start