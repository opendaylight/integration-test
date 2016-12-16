/*
 * Copyright (c) 2016 Red Hat, Inc. and others. All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.aclservice;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;
import javax.inject.Inject;
import javax.inject.Singleton;
import org.opendaylight.netvirt.aclservice.api.AclServiceListener;
import org.opendaylight.netvirt.aclservice.api.AclServiceManager;
import org.opendaylight.netvirt.aclservice.api.utils.AclInterface;
import org.opendaylight.netvirt.aclservice.utils.AclConstants;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.access.control.list.rev160218.access.lists.acl.access.list.entries.Ace;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.CreateIdPoolInput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.CreateIdPoolInputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.IdManagerService;
import org.opendaylight.yangtools.yang.common.RpcResult;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Singleton
public class AclServiceManagerImpl implements AclServiceManager {

    private static final Logger LOG = LoggerFactory.getLogger(AclServiceManagerImpl.class);

    private final IdManagerService idManager;

    private final List<AclServiceListener> aclServiceListeners = new ArrayList<>();

    @Inject
    public AclServiceManagerImpl(final AclServiceImplFactory factory, final IdManagerService idManager) {
        this.idManager = idManager;
        LOG.info("ACL Service Initiated, idManager = {}", idManager);
        createIdPool();

        addAclServiceListner(factory.createIngressAclServiceImpl());
        addAclServiceListner(factory.createEgressAclServiceImpl());

        LOG.info("ACL Service Initiated");
    }

    @Override
    public void addAclServiceListner(AclServiceListener aclServiceListner) {
        aclServiceListeners.add(aclServiceListner);
    }

    @Override
    public void removeAclServiceListner(AclServiceListener aclServiceListner) {
        aclServiceListeners.remove(aclServiceListner);
    }

    @Override
    public void notify(AclInterface port, AclInterface oldPort, Action action) {
        for (AclServiceListener aclServiceListener : aclServiceListeners) {
            boolean result = false;
            if (action == Action.ADD) {
                result = aclServiceListener.applyAcl(port);
            } else if (action == Action.UPDATE) {
                result = aclServiceListener.updateAcl(oldPort, port);
            } else if (action == Action.REMOVE) {
                result = aclServiceListener.removeAcl(port);
            }
            if (result) {
                LOG.debug("Acl action {} invoking listener {} succeeded", action,
                    aclServiceListener.getClass().getName());
            } else {
                LOG.warn("Acl action {} invoking listener {} failed", action, aclServiceListener.getClass().getName());
            }
        }
    }

    @Override
    public void notifyAce(AclInterface port, Action action, String aclName, Ace ace) {
        for (AclServiceListener aclServiceListener : aclServiceListeners) {
            LOG.debug("Ace action {} invoking class {}", action, aclServiceListener.getClass().getName());
            if (action == Action.ADD) {
                aclServiceListener.applyAce(port, aclName, ace);
            } else if (action == Action.REMOVE) {
                aclServiceListener.removeAce(port, aclName, ace);
            }
        }
    }

    /**
     * Creates the id pool.
     */
    private void createIdPool() {
        CreateIdPoolInput createPool = new CreateIdPoolInputBuilder()
                .setPoolName(AclConstants.ACL_FLOW_PRIORITY_POOL_NAME).setLow(AclConstants.ACL_FLOW_PRIORITY_POOL_START)
                .setHigh(AclConstants.ACL_FLOW_PRIORITY_POOL_END).build();
        try {
            Future<RpcResult<Void>> result = idManager.createIdPool(createPool);
            if ((result != null) && (result.get().isSuccessful())) {
                LOG.debug("Created IdPool for {}", AclConstants.ACL_FLOW_PRIORITY_POOL_NAME);
            }
        } catch (InterruptedException | ExecutionException e) {
            LOG.error("Failed to create ID pool for ACL flow priority", e);
            throw new RuntimeException("Failed to create ID pool for ACL flow priority", e);
        }
    }

}
