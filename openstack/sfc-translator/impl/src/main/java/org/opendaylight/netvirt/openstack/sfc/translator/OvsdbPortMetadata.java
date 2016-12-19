/*
 * Copyright (c) 2016 Brocade Communications Systems, Inc. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.openstack.sfc.translator;

import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.rev150105.OvsdbBridgeAugmentation;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.rev150105.OvsdbNodeAugmentation;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.rev150105.OvsdbTerminationPointAugmentation;

public class OvsdbPortMetadata {
    private OvsdbTerminationPointAugmentation ovsdbPort;
    private OvsdbNodeAugmentation ovsdbNode;
    private OvsdbBridgeAugmentation ovsdbBridgeNode;

    public OvsdbPortMetadata() {

    }

    public OvsdbBridgeAugmentation getOvsdbBridgeNode() {
        return ovsdbBridgeNode;
    }

    public void setOvsdbBridgeNode(OvsdbBridgeAugmentation ovsdbBridgeNode) {
        this.ovsdbBridgeNode = ovsdbBridgeNode;
    }

    public OvsdbNodeAugmentation getOvsdbNode() {
        return ovsdbNode;
    }

    public void setOvsdbNode(OvsdbNodeAugmentation ovsdbNode) {
        this.ovsdbNode = ovsdbNode;
    }

    public OvsdbTerminationPointAugmentation getOvsdbPort() {
        return ovsdbPort;
    }

    public void setOvsdbPort(OvsdbTerminationPointAugmentation ovsdbPort) {
        this.ovsdbPort = ovsdbPort;
    }
}
