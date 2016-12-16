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
import org.opendaylight.netvirt.vpnmanager.populator.intfc.VpnPopulator;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.vrfentries.VrfEntry;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.adjacency.list.Adjacency;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.xml.crypto.Data;
import java.util.Arrays;

public class L3vpnPopulator implements VpnPopulator {
    protected VpnInterfaceManager context; //TODO (KIRAN) : Context needs to be abstract entitiy/interface implemented by classes of type Context(Managers/Listeners in our case)
    protected String rd;
    protected Adjacency nextHop;
    protected String nextHopIp;
    protected VrfEntry.EncapType encapType;
    private static final Logger LOG = LoggerFactory.getLogger(L3vpnPopulator.class);

    protected L3vpnPopulator(VpnInterfaceManager context, String rd, Adjacency nextHop, String nextHopIp) {
        this.context = context;
        this.rd = rd;
        this.nextHop = nextHop;
        this.nextHopIp = nextHopIp;
    }

    @Override
    public void populateFib(DataBroker broker, WriteTransaction writeCfgTxn, WriteTransaction writeOperTxn) {
    }

    protected void addPrefixToBGP(String rd, String macAddress, String prefix, String nextHopIp,
                                  VrfEntry.EncapType encapType, long label, long l3vni, String gatewayMac,
                                  DataBroker broker, WriteTransaction writeConfigTxn) {
        try {
            LOG.info("ADD: Adding Fib entry rd {} prefix {} nextHop {} label {}", rd, prefix, nextHopIp, label);
            context.getFibManager().addOrUpdateFibEntry(broker, rd, macAddress, prefix, Arrays.asList(nextHopIp), encapType, (int)label,
                    l3vni, gatewayMac, RouteOrigin.STATIC, writeConfigTxn);
            context.getBgpManager().advertisePrefix(rd, macAddress, prefix, Arrays.asList(nextHopIp),
                    encapType, (int)label, l3vni, gatewayMac);
            LOG.info("ADD: Added Fib entry rd {} prefix {} nextHop {} label {}", rd, prefix, nextHopIp, label);
        } catch(Exception e) {
            LOG.error("Add prefix failed", e);
        }
    }
}
