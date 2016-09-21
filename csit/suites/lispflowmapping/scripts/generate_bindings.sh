#!/bin/bash
# Activate robotframework virtualenv
# ${ROBOT_VENV} comes from the include-raw-integration-install-robotframework.sh
# script.
source ${ROBOT_VENV}/bin/activate

echo "Downloading yang dependencies..."

DIRECTORY="odl-lispflowmapping-yang-files"

# odl-lispflowmapping-yang-files will contain all the yang files
# odl-lispflowmapping-yang-files/LispFlowMappingYANGBindings will
# contain all the binding files generated by pyangbind.
mkdir -p ${WORKSPACE}/$DIRECTORY

GITWEB_LISP="https://git.opendaylight.org/gerrit/gitweb?p=lispflowmapping.git;a=blob_plain;hb=refs/heads/${BRANCH}"
GITWEB_MDSAL="https://git.opendaylight.org/gerrit/gitweb?p=mdsal.git;a=blob_plain;hb=refs/heads/${BRANCH}"
GITWEB_CONTROLLER="https://git.opendaylight.org/gerrit/gitweb?p=controller.git;a=blob_plain;hb=refs/heads/${BRANCH}"

# Download yang-files in the VM on fly using curl before generating
# binding files.
curl "$GITWEB_LISP;f=mappingservice/lisp-proto/src/main/yang/ietf-lisp-address-types.yang" -o ${WORKSPACE}/$DIRECTORY/ietf-lisp-address-types.yang
curl "$GITWEB_LISP;f=mappingservice/lisp-proto/src/main/yang/odl-lisp-proto.yang" -o ${WORKSPACE}/$DIRECTORY/odl-lisp-proto.yang
curl "$GITWEB_LISP;f=mappingservice/api/src/main/yang/odl-mappingservice.yang" -o ${WORKSPACE}/$DIRECTORY/odl-mappingservice.yang

# Currently there is dependency revisions inconsistency in beryllium
# for ietf-yang-types and ietf-inet-types
if [ ${BRANCH} = "stable/beryllium" ]
then
    curl "$GITWEB_MDSAL;f=model/ietf/ietf-yang-types/src/main/yang/ietf-yang-types.yang" -o ${WORKSPACE}/$DIRECTORY/ietf-yang-types.yang
    curl "$GITWEB_MDSAL;f=model/ietf/ietf-inet-types/src/main/yang/ietf-inet-types.yang" -o ${WORKSPACE}/$DIRECTORY/ietf-inet-types.yang
else
    curl "$GITWEB_LISP;f=mappingservice/lisp-proto/src/main/yang/odl-lisp-address-types.yang" -o ${WORKSPACE}/$DIRECTORY/odl-lisp-address-types.yang
    curl "$GITWEB_LISP;f=mappingservice/lisp-proto/src/main/yang/odl-inet-binary-types.yang" -o ${WORKSPACE}/$DIRECTORY/odl-inet-binary-types.yang
    curl "$GITWEB_MDSAL;f=model/ietf/ietf-yang-types-20130715/src/main/yang/ietf-yang-types@2013-07-15.yang" -o ${WORKSPACE}/$DIRECTORY/ietf-yang-types.yang
    curl "$GITWEB_MDSAL;f=model/ietf/ietf-inet-types-2013-07-15/src/main/yang/ietf-inet-types@2013-07-15.yang" -o ${WORKSPACE}/$DIRECTORY/ietf-inet-types.yang
fi

curl "$GITWEB_MDSAL;f=model/yang-ext/src/main/yang/yang-ext.yang" -o ${WORKSPACE}/$DIRECTORY/yang-ext.yang
curl "$GITWEB_CONTROLLER;f=opendaylight/config/config-api/src/main/yang/config.yang" -o ${WORKSPACE}/$DIRECTORY/config.yang

# Copy bits patch to yang file directory
cp ${WORKSPACE}/test/csit/suites/lispflowmapping/scripts/bits.patch ${WORKSPACE}/$DIRECTORY

# Go to odl-lispflowmapping-yang-files directory
pushd ${WORKSPACE}/$DIRECTORY

# Currently bits are not supported in pyangbind plugin so
# We need to apply patch to generate pyangbind bindings
# Successfully.
patch -i bits.patch && echo 'Patch applied successfully!'

# Generate binding files using pyangbind
PYBINDPLUGIN=`/usr/bin/env python -c 'import pyangbind; import os; print "%s/plugin" % os.path.dirname(pyangbind.__file__)'`
echo $PYBINDPLUGIN
echo "pyang version"
pyang --version

ls -la

sleep 20

pyang ./ietf-inet-types.yang

ls -la $PYBINDPLUGIN

sleep 20

pyang --plugindir $PYBINDPLUGIN -f pybind --build-rpcs --split-class-dir ./LISPFlowMappingYANGBindings    ./ietf-inet-types.yang

sleep 20

# Go back the main direcory
popd

echo "Yang Dependencies and bindings downloaded successfully in ${WORKSPACE}/$DIRECTORY"
