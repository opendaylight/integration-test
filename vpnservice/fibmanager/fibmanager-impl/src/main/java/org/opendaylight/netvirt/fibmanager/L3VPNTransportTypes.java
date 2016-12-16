/*
 * Copyright (c) 2015 - 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.fibmanager;

import org.opendaylight.genius.itm.globals.ITMConstants;
import java.util.HashMap;
import java.util.Map;


public enum L3VPNTransportTypes {
    VxLAN   (ITMConstants.TUNNEL_TYPE_VXLAN),
    GRE     (ITMConstants.TUNNEL_TYPE_GRE),
    Invalid (ITMConstants.TUNNEL_TYPE_INVALID);

    private String transportType;

    L3VPNTransportTypes (String type) {
        transportType = type;
    }
    public void setL3VPNTransportTypes(String transportType) {
        this.transportType = transportType;
    }

    private static final Map<String, L3VPNTransportTypes> strToTypeMap = new HashMap<String, L3VPNTransportTypes>();
    static {
        for (L3VPNTransportTypes type : L3VPNTransportTypes.values()) {
            strToTypeMap.put(type.transportType, type);
        }
    }

    public String getTransportType() {
        return this.transportType;
    }

    public static L3VPNTransportTypes validateTransportType(String transportType) {
        L3VPNTransportTypes type = strToTypeMap.get(transportType);
        if (type == null)
            return L3VPNTransportTypes.Invalid;
        return type;
    }
}