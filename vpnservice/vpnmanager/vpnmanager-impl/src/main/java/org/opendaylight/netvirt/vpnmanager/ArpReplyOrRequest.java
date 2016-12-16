/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.vpnmanager;

import org.opendaylight.genius.mdsalutil.NwConstants;

public enum ArpReplyOrRequest {
    REQUEST("ARP-REQUEST"), REPLY("ARP-REPLY");

    private String name;

    ArpReplyOrRequest(String name) {
        this.name = name;
    }

    public String getName() {
        return this.name;
    }

    public int getArpOperation(){
        int arpOperation = (name == ArpReplyOrRequest.REQUEST.getName() ? NwConstants.ARP_REQUEST : NwConstants.ARP_REPLY);
        return arpOperation;
    }
    public int calculateConsistentHashCode() {
        if (this.name != null) {
            return this.name.hashCode();
        } else {
            return 0;
        }
    }
}
