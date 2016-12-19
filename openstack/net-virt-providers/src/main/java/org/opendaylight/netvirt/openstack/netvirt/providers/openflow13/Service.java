/*
 * Copyright (c) 2014 - 2016 Red Hat, Inc. and others. All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.openstack.netvirt.providers.openflow13;

import java.util.Comparator;

public enum Service {

    CLASSIFIER ((short) 0, "Classifier"),
    GATEWAY_RESOLVER((short) 0, "External Network Gateway Resolver"),
    DIRECTOR ((short) 10, "Director"),
    SFC_CLASSIFIER ((short) 10, "SFC Classifier"),
    ARP_RESPONDER ((short) 20, "Distributed ARP Responder"),
    INBOUND_NAT ((short) 30, "DNAT for inbound floating-ip traffic"),
    RESUBMIT_ACL_SERVICE ((short) 31, "Resubmit service for Learn ACL"),
    ACL_LEARN_SERVICE ((short) 39, "ACL Learn Service"),
    EGRESS_ACL ((short) 40, "Egress Acces-control"),
    LOAD_BALANCER ((short) 50, "Distributed LBaaS"),
    ROUTING ((short) 60, "Distributed Virtual Routing (DVR)"),
    ICMP_ECHO ((short) 70, "Distributed ICMP Echo Responder"),
    L3_FORWARDING ((short) 70, "Layer 3 forwarding/lookup service"),
    L2_REWRITE ((short) 80, "Layer2 rewrite service"),
    INGRESS_ACL ((short) 90, "Ingress Acces-control"),
    OUTBOUND_NAT ((short) 100, "DNAT for outbound floating-ip traffic"),
    L2_LEARN ((short) 105, "Layer2 mac remote tep learning"),
    L2_FORWARDING ((short) 110, "Layer2 mac,vlan based forwarding");

    short table;
    String description;

    Service(short table, String description)  {
        this.table = table;
        this.description = description;
    }

    public short getTable() {
        return table;
    }

    public String getDescription() {
        return description;
    }

    public static Comparator<Service> insertComparator = new Comparator<Service>() {

        @Override
        public int compare(Service service1, Service service2) {
            return service1.getTable() - service2.getTable();
        }
    };
}
