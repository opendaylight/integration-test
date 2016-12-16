/*
 * Copyright (c) 2016 Red Hat, Inc. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.it;

import java.io.IOException;
import java.util.List;
import org.opendaylight.ovsdb.utils.mdsal.utils.MdsalUtils;
import org.opendaylight.ovsdb.utils.ovsdb.it.utils.DockerOvs;
import org.opendaylight.ovsdb.utils.southbound.utils.SouthboundUtils;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.Node;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class RealNetOvsImpl extends AbstractNetOvs {
    private static final Logger LOG = LoggerFactory.getLogger(RealNetOvsImpl.class);

    RealNetOvsImpl(final DockerOvs dockerOvs, final Boolean isUserSpace, final MdsalUtils mdsalUtils,
                   SouthboundUtils southboundUtils) {
        super(dockerOvs, isUserSpace, mdsalUtils, southboundUtils);
    }

    @Override
    public String createPort(int ovsInstance, Node bridgeNode, String networkName ,List<Uuid> securityGroupList)
            throws InterruptedException, IOException {
        PortInfo portInfo = buildPortInfo(0, networkName);

        NeutronPort neutronPort = new NeutronPort(mdsalUtils, getNetworkId(networkName));
        neutronPort.createPort(portInfo, "compute:None", null, true, securityGroupList);
        addTerminationPoint(portInfo, bridgeNode, "internal");
        putPortInfo(portInfo);

        return portInfo.name;
    }
}
