#!/bin/bash
echo "Downloading yang dependencies..."

DIRECTORY="odl-lispflowmapping-yang-files"

# odl-lispflowmapping-yang-files will contain all the yang files
# odl-lispflowmapping-yang-files/LispFlowMappingYANGBindings will
# contain all the binding files generated by pyangbind.
mkdir -p ${WORKSPACE}/$DIRECTORY

GITWEB_LISP="https://git.opendaylight.org/gerrit/gitweb?p=lispflowmapping.git;a=blob_plain;hb=refs/heads/${DISTROBRANCH}"
GITWEB_MDSAL="https://git.opendaylight.org/gerrit/gitweb?p=mdsal.git;a=blob_plain"

# Download yang-files in the VM on fly using curl before generating
# binding files.
curl "$GITWEB_LISP;f=mappingservice/lisp-proto/src/main/yang/odl-lisp-proto.yang" -o ${WORKSPACE}/$DIRECTORY/odl-lisp-proto.yang
curl "$GITWEB_LISP;f=mappingservice/lisp-proto/src/main/yang/odl-inet-binary-types.yang" -o ${WORKSPACE}/$DIRECTORY/odl-inet-binary-types.yang
curl "$GITWEB_LISP;f=mappingservice/api/src/main/yang/odl-mappingservice.yang" -o ${WORKSPACE}/$DIRECTORY/odl-mappingservice.yang
curl "$GITWEB_LISP;f=mappingservice/lisp-proto/src/main/yang/odl-lisp-address-types.yang" -o ${WORKSPACE}/$DIRECTORY/odl-lisp-address-types.yang

# ietf-{inet,yang}-types.yang folder renamed in Neon, and there is no stable/neon branch
if [ ${DISTROBRANCH} = "stable/oxygen" -o ${DISTROBRANCH} = "stable/fluorine" ]
then
    curl "$GITWEB_MDSAL;hb=refs/heads/${DISTROBRANCH};f=model/yang-ext/src/main/yang/yang-ext.yang" -o ${WORKSPACE}/$DIRECTORY/yang-ext.yang
    curl "$GITWEB_MDSAL;hb=refs/heads/${DISTROBRANCH};f=model/ietf/ietf-lisp-address-types/src/main/yang/ietf-lisp-address-types.yang" -o ${WORKSPACE}/$DIRECTORY/ietf-lisp-address-types.yang
    curl "$GITWEB_MDSAL;hb=refs/heads/${DISTROBRANCH};f=model/ietf/ietf-yang-types-20130715/src/main/yang/ietf-yang-types@2013-07-15.yang" -o ${WORKSPACE}/$DIRECTORY/ietf-yang-types.yang
    curl "$GITWEB_MDSAL;hb=refs/heads/${DISTROBRANCH};f=model/ietf/ietf-inet-types-2013-07-15/src/main/yang/ietf-inet-types@2013-07-15.yang" -o ${WORKSPACE}/$DIRECTORY/ietf-inet-types.yang
elif [ ${DISTROBRANCH} = "stable/neon" ]
then
    curl "$GITWEB_MDSAL;hb=refs/tags/v3.0.6;f=model/yang-ext/src/main/yang/yang-ext.yang" -o ${WORKSPACE}/$DIRECTORY/yang-ext.yang
    curl "$GITWEB_MDSAL;hb=refs/tags/v3.0.6;f=model/ietf/ietf-lisp-address-types/src/main/yang/ietf-lisp-address-types.yang" -o ${WORKSPACE}/$DIRECTORY/ietf-lisp-address-types.yang
    curl "$GITWEB_MDSAL;hb=refs/tags/v3.0.6;f=model/ietf/rfc6991-ietf-yang-types/src/main/yang/ietf-yang-types@2013-07-15.yang" -o ${WORKSPACE}/$DIRECTORY/ietf-yang-types.yang
    curl "$GITWEB_MDSAL;hb=refs/tags/v3.0.6;f=model/ietf/rfc6991-ietf-inet-types/src/main/yang/ietf-inet-types@2013-07-15.yang" -o ${WORKSPACE}/$DIRECTORY/ietf-inet-types.yang
else
    curl "$GITWEB_MDSAL;hb=refs/heads/${DISTROBRANCH};f=model/yang-ext/src/main/yang/yang-ext.yang" -o ${WORKSPACE}/$DIRECTORY/yang-ext.yang
    curl "$GITWEB_MDSAL;hb=refs/heads/${DISTROBRANCH};f=model/ietf/ietf-lisp-address-types/src/main/yang/ietf-lisp-address-types.yang" -o ${WORKSPACE}/$DIRECTORY/ietf-lisp-address-types.yang
    curl "$GITWEB_MDSAL;hb=refs/heads/${DISTROBRANCH};f=model/ietf/rfc6991-ietf-yang-types/src/main/yang/ietf-yang-types@2013-07-15.yang" -o ${WORKSPACE}/$DIRECTORY/ietf-yang-types.yang
    curl "$GITWEB_MDSAL;hb=refs/heads/${DISTROBRANCH};f=model/ietf/rfc6991-ietf-inet-types/src/main/yang/ietf-inet-types@2013-07-15.yang" -o ${WORKSPACE}/$DIRECTORY/ietf-inet-types.yang
fi

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
pyang --plugindir $PYBINDPLUGIN -f pybind --build-rpcs --split-class-dir ${WORKSPACE}/$DIRECTORY/LISPFlowMappingYANGBindings ./odl-mappingservice.yang

# Go back the main direcory
popd

echo "Yang Dependencies and bindings downloaded successfully in ${WORKSPACE}/$DIRECTORY"
