/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.vpnmanager.arp.responder;

public enum ArpResponderConstant {

    /**
     * ARP Responder table name
     * <P>
     * Value:<b>Arp_Responder_Table</b>
     */
    TABLE_NAME("Arp_Responder_Table"),
    /**
     * ARP Responder group table name
     * <P>
     * Value:<b>Arp_Responder_Group_Flow</b>
     */
    GROUP_FLOW_NAME("Arp_Responder_Group_Flow"),
    /**
     * ARP Responder Drop Flow name
     * <P>
     * Value:<b>Arp_Responder_Drop_Flow</b>
     */
    DROP_FLOW_NAME("Arp_Responder_Drop_Flow"),
    /**
     * ARP Responder Flow ID
     * <P>
     * Value:<b>Arp:tbl_{0}:lport_{1}:gw_{2}</b>
     * <ul><li>0: Table Id</li>
     * <li>1: LPort Tag</li>
     * <li>2: Gateway IP in String</li></ul>
     */
    FLOW_ID_FORMAT("Arp:tbl_{0}:lport_{1}:gw_{2}"),
    /**
     * Pool name from which group id to be generated
     * <P>
     * Value:<b>elan.ids.pool</b>
     */
    ELAN_ID_POOL_NAME("elan.ids.pool"),
    /**
     * Name of the group id for the pool entry
     * <p>
     * Value:<b>arp.responder.group.id</b>
     */
    ARP_RESPONDER_GROUP_ID("arp.responder.group.id");

    /**
     * enum value holder
     */
    private final String value;

    /**
     * Constructor with single argument
     *
     * @param value
     *            String enum value
     */
    ArpResponderConstant(final String value) {
        this.value = value;
    }

    /**
     * Get value for enum
     *
     * @return {@link #value}
     */
    public String value() {
        return this.value;
    }
}
