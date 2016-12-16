/*
 * Copyright (c) 2016 Red Hat, Inc. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.it;

import java.util.UUID;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.ovsdb.utils.mdsal.utils.MdsalUtils;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.l3.rev150712.routers.attributes.Routers;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.l3.rev150712.routers.attributes.routers.Router;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.l3.rev150712.routers.attributes.routers.RouterBuilder;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;

public class NeutronRouter {
    private final MdsalUtils mdsalUtils;
    private final String routerId;
    private final String tenantId;
    private Router router;

    NeutronRouter(final MdsalUtils mdsalUtils) {
        this.mdsalUtils = mdsalUtils;
        tenantId = UUID.randomUUID().toString();
        routerId = UUID.randomUUID().toString();
    }

    String getRouterId() {
        return routerId;
    }

    void createRouter(final String name) {
        router = new RouterBuilder()
                .setName(name)
                .setUuid(new Uuid(routerId))
                .setTenantId(new Uuid(tenantId))
                .setAdminStateUp(true)
                .setStatus("ACTIVE")
                .build();

        mdsalUtils.put(LogicalDatastoreType.CONFIGURATION, InstanceIdentifier
                .create(org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.rev150712.Neutron.class)
                .child(Routers.class).child(Router.class, router.getKey()), router);
    }

    void deleteRouter() {
        if (router == null) {
            return;
        }

        mdsalUtils.delete(LogicalDatastoreType.CONFIGURATION, InstanceIdentifier
                .create(org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.rev150712.Neutron.class)
                .child(Routers.class).child(Router.class, router.getKey()));
    }
}
