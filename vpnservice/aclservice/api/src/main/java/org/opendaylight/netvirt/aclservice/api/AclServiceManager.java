/*
 * Copyright (c) 2016 Red Hat, Inc. and others. All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.aclservice.api;

import org.opendaylight.netvirt.aclservice.api.utils.AclInterface;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.access.control.list.rev160218.access.lists.acl.access.list.entries.Ace;

public interface AclServiceManager {

    enum Action {
        ADD,
        UPDATE,
        REMOVE
    }

    enum MatchCriteria {
        MATCH_SOURCE,
        MATCH_DESTINATION
    }

    void addAclServiceListner(AclServiceListener aclServiceListner);

    void removeAclServiceListner(AclServiceListener aclServiceListner);

    void notify(AclInterface port, AclInterface oldPort, Action action);

    void notifyAce(AclInterface port, Action action, String aclName, Ace ace);
}
