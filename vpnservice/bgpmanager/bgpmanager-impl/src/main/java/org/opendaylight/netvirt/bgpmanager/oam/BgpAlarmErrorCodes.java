/*
 * Copyright (c) 2015 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.bgpmanager.oam;

import java.util.HashMap;
import java.util.Map;

/**
 * Created by echiapt on 7/27/2015.
 */
public enum BgpAlarmErrorCodes {
    CEASE_MAX_PREFIX            (1, "BgpMaxPrefixesFailure"),
    CEASE_PEER_UNCONFIG         (3, "BgpPeerUnconfigFailure") ,
    CEASE_CONNECT_REJECT        (5, "BgpConnRejectFailure"),
    CEASE_COLLISION_RESOLUTION  (7, "BgpCollisionResolutionFailure"),
    CEASE_OUT_OF_RESOURCE       (8, "BgpOutOfResourcesFailure"),
    ERROR_IGNORE                (-1,"UnknownErr");

    private final int error;
    private final String alarmType;

    BgpAlarmErrorCodes(int error, String alarmType) {
        this.error = error;
        this.alarmType = alarmType;
    }

    private static final Map<Integer, BgpAlarmErrorCodes> intToTypeMap = new HashMap<Integer, BgpAlarmErrorCodes>();
    static {
        for (BgpAlarmErrorCodes type : BgpAlarmErrorCodes.values()) {
            intToTypeMap.put(type.error, type);
        }

    }

    public String getAlarmType() {
        return this.alarmType;
    }

    public static BgpAlarmErrorCodes checkErrorSubcode(int i) {
        BgpAlarmErrorCodes type = intToTypeMap.get(Integer.valueOf(i));
        if (type == null)
            return BgpAlarmErrorCodes.ERROR_IGNORE;
        return type;
    }
}
