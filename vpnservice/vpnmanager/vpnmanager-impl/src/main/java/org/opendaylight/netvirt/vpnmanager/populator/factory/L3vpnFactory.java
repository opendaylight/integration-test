/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.vpnmanager.populator.factory;

import org.opendaylight.netvirt.vpnmanager.VpnInterfaceManager;
import org.opendaylight.netvirt.vpnmanager.populator.impl.L3vpnOverMplsGrePopulator;
import org.opendaylight.netvirt.vpnmanager.populator.impl.L3vpnOverVxlanPopulator;
import org.opendaylight.netvirt.vpnmanager.populator.input.L3vpnInput;
import org.opendaylight.netvirt.vpnmanager.populator.intfc.VpnPopulator;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.vrfentries.VrfEntry;

public class L3vpnFactory {
    private L3vpnFactory() {

    }

    public static VpnPopulator getL3vpnPopulator(VrfEntry.EncapType encapType, L3vpnInput input, VpnInterfaceManager context) {
        if (encapType.equals(VrfEntry.EncapType.Vxlan)) {
            return new L3vpnOverVxlanPopulator(context, input.getRd(), input.getNextHop(), input.getNextHopIp(), input.getL3vni(), input.getGatewayMac());
        } else {
            return new L3vpnOverMplsGrePopulator(context, input.getRd(), input.getNextHop(), input.getNextHopIp(), input.getVpnName(), input.getInterfaceName(), input.getDpnId());
        }
    }
}
