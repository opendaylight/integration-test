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
import org.opendaylight.netvirt.fibmanager.api.RouteOrigin;
import org.opendaylight.netvirt.vpnmanager.VpnInterfaceManager;
import org.opendaylight.netvirt.vpnmanager.VpnUtil;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.vrfentries.VrfEntry;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.adjacency.list.Adjacency;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.op.data.VpnInstanceOpDataEntry;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.math.BigInteger;
import java.util.Arrays;
import java.util.List;

public class L3vpnOverMplsGrePopulator extends L3vpnPopulator {
    private String vpnName;
    private String interfaceName;
    private BigInteger dpnId;
    private static final Logger LOG = LoggerFactory.getLogger(L3vpnOverMplsGrePopulator.class);

    public L3vpnOverMplsGrePopulator(VpnInterfaceManager context, String rd, Adjacency nextHop, String nextHopIp, String vpnName, String interfaceName, BigInteger dpnId) {
        super(context, rd, nextHop, nextHopIp);
        this.vpnName = vpnName;
        this.interfaceName = interfaceName;
        this.dpnId = dpnId;
        this.encapType = VrfEntry.EncapType.Mplsgre;
    }

    @Override
    public void populateFib(DataBroker broker, WriteTransaction writeConfigTxn, WriteTransaction writeOperTxn) {
        long label = nextHop.getLabel();
        List<VpnInstanceOpDataEntry> vpnsToImportRoute = context.getVpnsImportingMyRoute(vpnName);
        long vpnId = VpnUtil.getVpnId(broker, vpnName);
        if (rd != null) {
            context.addToLabelMapper(label, dpnId, nextHop.getIpAddress(), Arrays.asList(nextHopIp), vpnId,
                    interfaceName, null,false, rd, writeOperTxn);
<<<<<<< HEAD
            addPrefixToBGP(rd, nextHop.getIpAddress(), nextHopIp, encapType, label,
                    0, null, null, broker, writeConfigTxn);
=======
            addPrefixToBGP(rd, null /*macAddress*/, nextHop.getIpAddress(), nextHopIp, encapType, label,
                    0 /*l3vni*/, null /*gatewayMacAddress*/, broker, writeConfigTxn);
>>>>>>> 501b5dd9525a54e133e562f05841257a3ee678d2
            //TODO: ERT - check for VPNs importing my route
            for (VpnInstanceOpDataEntry vpn : vpnsToImportRoute) {
                String vpnRd = vpn.getVrfId();
                if (vpnRd != null) {
                    LOG.debug("Exporting route with rd {} prefix {} nexthop {} label {} to VPN {}", vpnRd, nextHop.getIpAddress(), nextHopIp, label, vpn);
                    context.getFibManager().addOrUpdateFibEntry(broker, vpnRd, null /*macAddress*/, nextHop.getIpAddress(), Arrays.asList(nextHopIp), encapType,
                            (int) label, 0 /*l3vni*/, null /*gatewayMacAddress*/, RouteOrigin.SELF_IMPORTED, writeConfigTxn);
                }
            }
        } else {
            // ### add FIB route directly
            context.getFibManager().addOrUpdateFibEntry(broker, vpnName, null /*macAddress*/, nextHop.getIpAddress(), Arrays.asList(nextHopIp), encapType,
                    (int) label, 0 /*l3vni*/, null /*gatewayMacAddress*/, RouteOrigin.STATIC, writeConfigTxn);
        }
    }

}
