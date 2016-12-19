/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.vpnmanager.populator.impl;

import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.WriteTransaction;
import org.opendaylight.netvirt.vpnmanager.VpnInterfaceManager;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.vrfentries.VrfEntry;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.adjacency.list.Adjacency;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class L3vpnOverVxlanPopulator extends L3vpnPopulator {
    protected Long l3vni;
    protected String gatewayMac;
    private static final Logger LOG = LoggerFactory.getLogger(L3vpnOverVxlanPopulator.class);

    public L3vpnOverVxlanPopulator(VpnInterfaceManager context, String rd, Adjacency nextHop, String nextHopIp, Long l3vni, String gatewayMac) {
        super(context, rd, nextHop, nextHopIp);
        this.l3vni = l3vni;
        this.gatewayMac = gatewayMac;
        this.encapType = VrfEntry.EncapType.Vxlan;
    }

    @Override
    public void populateFib(DataBroker broker, WriteTransaction writeConfigTxn, WriteTransaction writeOperTxn) {
        if (rd != null) {
<<<<<<< HEAD
            addPrefixToBGP(rd, nextHop.getIpAddress(), nextHopIp, encapType, 0,
                    Long.valueOf(l3vni), nextHop.getMacAddress(), gatewayMac, broker, writeConfigTxn);
=======
            addPrefixToBGP(rd, nextHop.getMacAddress(), nextHop.getIpAddress(), nextHopIp, encapType, 0 /*label*/,
                    Long.valueOf(l3vni), gatewayMac, broker, writeConfigTxn);
>>>>>>> 501b5dd9525a54e133e562f05841257a3ee678d2
        } else {
            LOG.error("Internal VPN for L3 Over VxLAN is not supported. Aborting.");
            return;
        }
    }
}
