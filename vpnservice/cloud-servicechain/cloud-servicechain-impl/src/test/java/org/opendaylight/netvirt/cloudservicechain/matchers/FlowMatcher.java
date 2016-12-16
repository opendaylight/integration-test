/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.cloudservicechain.matchers;

import org.apache.commons.lang3.StringUtils;
import org.mockito.ArgumentMatcher;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.inventory.rev130819.tables.table.Flow;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.types.rev131026.flow.Instructions;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.types.rev131026.flow.Match;

public class FlowMatcher extends ArgumentMatcher<Flow> {

    Flow expectedFlow;

    public FlowMatcher(Flow expectedFlow) {
        this.expectedFlow = expectedFlow;
    }

    public boolean sameMatch(Match match1, Match match2 ) {
        // TODO: implement this
        return true;
    }

    public boolean sameInstructions(Instructions instructions1, Instructions instructions2) {
        // TODO: implement this
        return true;
    }

    @Override
    public boolean matches(Object actualFlow) {
        if ( ! ( actualFlow instanceof Flow ) ) {
            return false;
        }
        Flow flow = (Flow) actualFlow;

        boolean result =
                flow.getId() != null && flow.getId().equals(expectedFlow.getId() )
                && flow.getTableId() == expectedFlow.getTableId()
                && StringUtils.equals(flow.getFlowName(), expectedFlow.getFlowName() )
                && sameInstructions(flow.getInstructions(), expectedFlow.getInstructions())
                && sameMatch(flow.getMatch(), expectedFlow.getMatch() );

        return result;
    }

}
