/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.neutronvpn;

import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.access.control.list.rev160218.AclBase;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.access.control.list.rev160218.Ipv4Acl;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.aclservice.rev160608.DirectionEgress;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.aclservice.rev160608.DirectionIngress;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.constants.rev150712.EthertypeV4;

public final class NeutronSecurityRuleConstants {

    private NeutronSecurityRuleConstants() {
        // private constructor to avoid instantiation of this class.
    }

    public static final Class DIRECTION_EGRESS = DirectionEgress.class;
    public static final Class DIRECTION_INGRESS = DirectionIngress.class;

    public static final Short PROTOCOL_ICMP = 1;
    public static final Short PROTOCOL_TCP = 6;
    public static final Short PROTOCOL_UDP = 17;
    public static final Short PROTOCOL_ICMPV6 = 58;

    public static final Class ETHERTYPE_IPV4 = EthertypeV4.class;

    public static final String IPV4_ALL_NETWORK = "0.0.0.0/0";
    public static final String IPV6_ALL_NETWORK = "::/0";

    // default acp type
    public static final Class<? extends AclBase> ACLTYPE = Ipv4Acl.class;

}
