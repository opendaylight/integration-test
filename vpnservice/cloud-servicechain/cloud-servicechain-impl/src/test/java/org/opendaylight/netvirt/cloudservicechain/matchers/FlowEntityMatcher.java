/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.cloudservicechain.matchers;

import org.mockito.ArgumentMatcher;
import org.opendaylight.genius.mdsalutil.FlowEntity;
import org.opendaylight.genius.mdsalutil.InstructionInfo;
import org.opendaylight.genius.mdsalutil.MatchInfo;

public class FlowEntityMatcher extends ArgumentMatcher<FlowEntity> {

    FlowEntity expectedFlow;

    public FlowEntityMatcher(FlowEntity expectedFlow) {
        this.expectedFlow = expectedFlow;
    }

    public boolean sameMatch(MatchInfo match1, MatchInfo match2 ) {
        // TODO: implement this
        return true;
    }

    public boolean sameInstructions(InstructionInfo instructions1, InstructionInfo instructions2) {
        // TODO: implement this
        return true;
    }

    @Override
    public boolean matches(Object actualFlow) {
        if ( ! ( actualFlow instanceof FlowEntity ) ) {
            return false;
        }
        boolean result = true;
        FlowEntity flow = (FlowEntity) actualFlow;
//      flow.getId() != null && flow.getId().equals(expectedFlow.getId() )
//      && flow.getTableId() == expectedFlow.getTableId()
//      && StringUtils.equals(flow.getFlowName(), expectedFlow.getFlowName() )
//      && sameInstructions(flow.getInstructions(), expectedFlow.getInstructions())
//      && sameMatch(flow.getMatch(), expectedFlow.getMatch() );
        return result;
    }

}
