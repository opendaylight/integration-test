/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.vpnmanager;

import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.vpn.interfaces.VpnInterface;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;

public class UpdateData {
    private InstanceIdentifier<VpnInterface> identifier;
    private VpnInterface original;
    private VpnInterface update;

    protected UpdateData(InstanceIdentifier<VpnInterface> identifier, VpnInterface original, VpnInterface update) {
        this.identifier = identifier;
        this.original = original;
        this.update = update;
    }

    protected InstanceIdentifier getIdentifier() {
        return identifier;
    }

    protected VpnInterface getOriginal() {
        return original;
    }

    protected VpnInterface getUpdate() {
        return update;
    }
}