/*
 * Copyright (c) 2016 Red Hat, Inc. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.openstack.netvirt.providers.openflow13;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNull;

import org.junit.Before;
import org.junit.Test;

public class PipelineOrchestratorTest {
    PipelineOrchestrator orchestrator;
    @Before
    public void initialize() {
        orchestrator = new PipelineOrchestratorImpl();
    }

    @Test
    public void testPipeline() {
        assertEquals(orchestrator.getNextServiceInPipeline(Service.CLASSIFIER), Service.ARP_RESPONDER);
        assertEquals(orchestrator.getNextServiceInPipeline(Service.ARP_RESPONDER), Service.INBOUND_NAT);
        assertEquals(orchestrator.getNextServiceInPipeline(Service.INBOUND_NAT), Service.RESUBMIT_ACL_SERVICE);
        assertEquals(orchestrator.getNextServiceInPipeline(Service.RESUBMIT_ACL_SERVICE), Service.ACL_LEARN_SERVICE);
        assertEquals(orchestrator.getNextServiceInPipeline(Service.ACL_LEARN_SERVICE), Service.EGRESS_ACL);
        assertEquals(orchestrator.getNextServiceInPipeline(Service.EGRESS_ACL), Service.LOAD_BALANCER);
        assertEquals(orchestrator.getNextServiceInPipeline(Service.LOAD_BALANCER), Service.ROUTING);
        assertEquals(orchestrator.getNextServiceInPipeline(Service.ROUTING), Service.L3_FORWARDING);
        assertEquals(orchestrator.getNextServiceInPipeline(Service.L3_FORWARDING), Service.L2_REWRITE);
        assertEquals(orchestrator.getNextServiceInPipeline(Service.L2_REWRITE), Service.INGRESS_ACL);
        assertEquals(orchestrator.getNextServiceInPipeline(Service.INGRESS_ACL), Service.OUTBOUND_NAT);
        assertEquals(orchestrator.getNextServiceInPipeline(Service.OUTBOUND_NAT), Service.L2_LEARN);
        assertEquals(orchestrator.getNextServiceInPipeline(Service.L2_LEARN), Service.L2_FORWARDING);
        assertNull(orchestrator.getNextServiceInPipeline(Service.L2_FORWARDING));
    }
}
