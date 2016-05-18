#!/bin/bash
echo "Downloading yang dependencies..."

DIRECTORY="odl-lispflowmapping-yang-files"

DOWNLOAD_CMD="mkdir -p /tmp/$DIRECTORY"

DOWNLOAD_CMD="$DOWNLOAD_CMD;curl 'https://git.opendaylight.org/gerrit/gitweb?p=lispflowmapping.git;a=blob_plain;f=mappingservice/lisp-proto/src/main/yang/ietf-lisp-address-types.yang;hb=HEAD' -o /tmp/$DIRECTORY/ietf-lisp-address-types.yang"
DOWNLOAD_CMD="$DOWNLOAD_CMD;curl 'https://git.opendaylight.org/gerrit/gitweb?p=lispflowmapping.git;a=blob_plain;f=mappingservice/lisp-proto/src/main/yang/odl-lisp-proto.yang;hb=HEAD' -o /tmp/$DIRECTORY/odl-lisp-proto.yang"
DOWNLOAD_CMD="$DOWNLOAD_CMD;curl 'https://git.opendaylight.org/gerrit/gitweb?p=lispflowmapping.git;a=blob_plain;f=mappingservice/lisp-proto/src/main/yang/odl-inet-binary-types.yang;hb=HEAD' -o /tmp/$DIRECTORY/odl-inet-binary-types.yang"
DOWNLOAD_CMD="$DOWNLOAD_CMD;curl 'https://git.opendaylight.org/gerrit/gitweb?p=lispflowmapping.git;a=blob_plain;f=mappingservice/api/src/main/yang/odl-mappingservice.yang;hb=HEAD' -o /tmp/$DIRECTORY/odl-mappingservice.yang"
DOWNLOAD_CMD="$DOWNLOAD_CMD;curl 'https://git.opendaylight.org/gerrit/gitweb?p=lispflowmapping.git;a=blob_plain;f=mappingservice/lisp-proto/src/main/yang/odl-lisp-address-types.yang;hb=HEAD' -o /tmp/$DIRECTORY/odl-lisp-address-types.yang"
DOWNLOAD_CMD="$DOWNLOAD_CMD;curl 'https://git.opendaylight.org/gerrit/gitweb?p=mdsal.git;a=blob_plain;f=model/ietf/ietf-yang-types/src/main/yang/ietf-yang-types.yang;hb=HEAD' -o /tmp/$DIRECTORY/ietf-yang-types.yang"
DOWNLOAD_CMD="$DOWNLOAD_CMD;curl 'https://git.opendaylight.org/gerrit/gitweb?p=mdsal.git;a=blob_plain;f=model/ietf/ietf-inet-types/src/main/yang/ietf-inet-types.yang;hb=HEAD' -o /tmp/$DIRECTORY/ietf-inet-types.yang"
DOWNLOAD_CMD="$DOWNLOAD_CMD;curl 'https://git.opendaylight.org/gerrit/gitweb?p=mdsal.git;a=blob_plain;f=model/yang-ext/src/main/yang/yang-ext.yang;hb=HEAD' -o /tmp/$DIRECTORY/yang-ext.yang"
DOWNLOAD_CMD="$DOWNLOAD_CMD;curl 'https://git.opendaylight.org/gerrit/gitweb?p=controller.git;a=blob_plain;f=opendaylight/config/config-api/src/main/yang/config.yang;hb=HEAD' -o /tmp/$DIRECTORY/config.yang"



DOWNLOAD_CMD="$DOWNLOAD_CMD;cd /tmp/$DIRECTORY;curl https://raw.githubusercontent.com/ashishk1994/ODL_TEST/master/bits.patch -o bits.patch;patch -i bits.patch && echo 'Patch applied successfully!'"
DOWNLOAD_CMD="$DOWNLOAD_CMD;PYBINDPLUGIN=\`/usr/bin/env python -c 'import pyangbind; import os; print \"%s/plugin\" % os.path.dirname(pyangbind.__file__)'\`"
DOWNLOAD_CMD="$DOWNLOAD_CMD;pyang --plugindir \$PYBINDPLUGIN -f pybind --build-rpcs --split-class-dir /tmp/$DIRECTORY/LISPFlowMappingYANGBindings ./odl-mappingservice.yang"
DOWNLOAD_CMD="$DOWNLOAD_CMD;cd ../"

echo "$DOWNLOAD_CMD"

ssh {$ODL_SYSTEM_IP} "$DOWNLOAD_CMD"

echo "Yang dependencies downloaded successfully in /tmp/$DIRECTORY"
echo "Currently bits are not supported in pyangbind plugin so applying the bits patch to generate pyangbind bindings"
echo "Bindings successfully generated!"
