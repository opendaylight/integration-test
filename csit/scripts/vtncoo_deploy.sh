#!/bin/bash
if [ ODL_STREAM == boron ]; then
    # Obtain current maven-metadata.xml of vtn coordinator distribution correct branch.
    # Acquire the Timestamp from maven metadata xml file
    cd /tmp
    VTNCOOBORONURL=https://nexus.opendaylight.org/content/repositories/opendaylight.snapshot/org/opendaylight/vtn/distribution.vtn-coordinator/6.3.0-SNAPSHOT
    wget ${VTNBORONURL}/maven-metadata.xml
    less maven-metadata.xml
    TIMESTAMPS=`xpath maven-metadata.xml "//snapshotVersion[extension='tar.bz2'][1]/value/text()" 2>/dev/null`
    echo TIMESTAMPS
    echo "VTN COORDINATOR timestamp is ${TIMESTAMPS}"
    VTNCOOBUNDLE="distribution.vtn-coordinator-${TIMESTAMP}.tar.bz2"
    wget ${VTNBORONURL}/${VTNCOOBUNDLE}
fi

