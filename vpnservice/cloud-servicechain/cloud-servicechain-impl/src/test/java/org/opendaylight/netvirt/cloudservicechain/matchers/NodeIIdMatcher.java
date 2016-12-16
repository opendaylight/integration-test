/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.cloudservicechain.matchers;

import java.util.List;

import org.mockito.ArgumentMatcher;
import org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.nodes.Node;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier.PathArgument;

public class NodeIIdMatcher extends ArgumentMatcher<InstanceIdentifier<Node>> {

    InstanceIdentifier<Node> expectedNodeIId;

    public NodeIIdMatcher(InstanceIdentifier<Node> expectedNodeIId) {
        this.expectedNodeIId = expectedNodeIId;
    }

    @Override
    public boolean matches(Object nodeIId) {

        if ( ! ( nodeIId instanceof InstanceIdentifier<?>) ) {
            return false;
        }
        boolean result = false;
        try {
            InstanceIdentifier<Node> actualNodeIId = (InstanceIdentifier<Node>) nodeIId;
            List<PathArgument> expectedNodeIIdPath = this.expectedNodeIId.getPath();
            List<PathArgument> actualNodeIIdPath = actualNodeIId.getPath();
            if ( expectedNodeIIdPath.size() != actualNodeIIdPath.size() ) {
                return false;
            }

            for ( int i = 0; i < expectedNodeIIdPath.size(); i++ ) {
                if ( expectedNodeIIdPath.get(i).compareTo(actualNodeIIdPath.get(i)) != 0 ) {
                    result = false;
                    break;
                }
            }

        } catch ( ClassCastException e ) {
            return false;
        }


        return result;
    }

}
