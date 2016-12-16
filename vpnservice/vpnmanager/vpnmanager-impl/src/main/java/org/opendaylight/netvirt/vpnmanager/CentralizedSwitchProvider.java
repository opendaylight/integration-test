/*
 * Copyright (c) 2016 Hewlett Packard Enterprise, Co. and others. All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.vpnmanager;

import java.math.BigInteger;

import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.netvirt.vpnmanager.api.ICentralizedSwitchProvider;

public class CentralizedSwitchProvider implements ICentralizedSwitchProvider {

    private final DataBroker dataBroker;

    public CentralizedSwitchProvider(DataBroker dataBroker) {
        this.dataBroker = dataBroker;
    }

    @Override
    public BigInteger getPrimarySwitchForRouter(String routerName) {
        return VpnUtil.getPrimarySwitchForRouter(dataBroker, routerName);
    }

}
