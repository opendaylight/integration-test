#!/bin/bash
echo "Downloading yang dependencies..."
SDIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DIRECTORY="odl-lispflowmapping-yang-files"

if [ ! -d "$DIRECTORY" ]; then
    mkdir $DIRECTORY
    curl 'https://git.opendaylight.org/gerrit/gitweb?p=lispflowmapping.git;a=blob_plain;f=mappingservice/lisp-proto/src/main/yang/ietf-lisp-address-types.yang;hb=HEAD' -o $SDIR/odl-lispflowmapping-yang-files/ietf-lisp-address-types.yang
    curl 'https://git.opendaylight.org/gerrit/gitweb?p=lispflowmapping.git;a=blob_plain;f=mappingservice/lisp-proto/src/main/yang/odl-lisp-proto.yang;hb=HEAD' -o $SDIR/odl-lispflowmapping-yang-files/odl-lisp-proto.yang
    curl 'https://git.opendaylight.org/gerrit/gitweb?p=lispflowmapping.git;a=blob_plain;f=mappingservice/lisp-proto/src/main/yang/odl-inet-binary-types.yang;hb=HEAD' -o $SDIR/odl-lispflowmapping-yang-files/odl-inet-binary-types.yang
    curl 'https://git.opendaylight.org/gerrit/gitweb?p=lispflowmapping.git;a=blob_plain;f=mappingservice/lisp-proto/src/main/yang/odl-lisp-address-types.yang;hb=HEAD' -o $SDIR/odl-lispflowmapping-yang-files/odl-lisp-address-types.yang
    curl 'https://git.opendaylight.org/gerrit/gitweb?p=mdsal.git;a=blob_plain;f=model/ietf/ietf-yang-types/src/main/yang/ietf-yang-types.yang;hb=HEAD' -o $SDIR/odl-lispflowmapping-yang-files/ietf-yang-types.yang
    curl 'https://git.opendaylight.org/gerrit/gitweb?p=mdsal.git;a=blob_plain;f=model/ietf/ietf-inet-types/src/main/yang/ietf-inet-types.yang;hb=HEAD' -o $SDIR/odl-lispflowmapping-yang-files/ietf-inet-types.yang
fi

echo "Yang dependencies downloaded successfully in ./odl-lispflowmapping-yang-files folder"

echo "Currently bits are not supported in pyangbind plugin so applying the bits patch to generate pyangbind bindings"
echo "Download bits patch..."

cd $DIRECTORY

curl https://raw.githubusercontent.com/ashishk1994/ODL_TEST/master/bits_container.patch -o bits_container.patch
patch -i bits_container.patch
echo "Patch applied successfully!"

echo "Generating python binding files..."
PYBINDPLUGIN=`/usr/bin/env python -c 'import pyangbind; import os; print "%s/plugin" % os.path.dirname(pyangbind.__file__)'`
pyang --plugindir $PYBINDPLUGIN -f pybind -o ../LISPFlowMappingYANGBindings.py ./odl-lisp-proto.yang

cd ../

echo "Bindings successfully generated!"
