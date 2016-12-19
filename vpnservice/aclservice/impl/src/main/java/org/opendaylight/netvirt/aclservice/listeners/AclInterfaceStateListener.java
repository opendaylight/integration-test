/*
 * Copyright (c) 2016 Red Hat, Inc. and others. All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.aclservice.listeners;

import java.util.List;
import javax.annotation.PostConstruct;
import javax.inject.Inject;
import javax.inject.Singleton;
import org.opendaylight.controller.md.sal.binding.api.ClusteredDataTreeChangeListener;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.datastoreutils.AsyncDataTreeChangeListenerBase;
import org.opendaylight.netvirt.aclservice.api.AclServiceManager;
import org.opendaylight.netvirt.aclservice.api.AclServiceManager.Action;
import org.opendaylight.netvirt.aclservice.api.utils.AclInterface;
import org.opendaylight.netvirt.aclservice.api.utils.AclInterfaceCacheUtil;
import org.opendaylight.netvirt.aclservice.utils.AclClusterUtil;
import org.opendaylight.netvirt.aclservice.utils.AclDataUtil;
import org.opendaylight.netvirt.aclservice.utils.AclServiceUtils;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.Uri;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.InterfacesState;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.state.Interface;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.TopologyId;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Singleton
public class AclInterfaceStateListener extends AsyncDataTreeChangeListenerBase<Interface,
        AclInterfaceStateListener> implements ClusteredDataTreeChangeListener<Interface>, AutoCloseable {

    private static final Logger LOG = LoggerFactory.getLogger(AclInterfaceStateListener.class);

    /** Our registration. */
    public static final TopologyId OVSDB_TOPOLOGY_ID = new TopologyId(new Uri("ovsdb:1"));
    public static final String EXTERNAL_ID_INTERFACE_ID = "iface-id";

    private final AclServiceManager aclServiceManger;
    private final AclClusterUtil aclClusterUtil;
    private final DataBroker dataBroker;
    private final AclDataUtil aclDataUtil;

    @Inject
    public AclInterfaceStateListener(AclServiceManager aclServiceManger, AclClusterUtil aclClusterUtil,
            DataBroker dataBroker, AclDataUtil aclDataUtil) {
        super(Interface.class, AclInterfaceStateListener.class);
        this.aclServiceManger = aclServiceManger;
        this.aclClusterUtil = aclClusterUtil;
        this.dataBroker = dataBroker;
        this.aclDataUtil = aclDataUtil;
    }

    @Override
    @PostConstruct
    public void init() {
        LOG.info("{} start", getClass().getSimpleName());
        registerListener(LogicalDatastoreType.OPERATIONAL, dataBroker);
    }

    @Override
    protected InstanceIdentifier<Interface> getWildCardPath() {
        return InstanceIdentifier.create(InterfacesState.class).child(Interface.class);
    }

    @Override
    protected void remove(InstanceIdentifier<Interface> key, Interface dataObjectModification) {
        AclInterfaceCacheUtil.removeAclInterfaceFromCache(dataObjectModification.getName());
    }

    @Override
    protected void update(InstanceIdentifier<Interface> key, Interface dataObjectModificationBefore,
                          Interface dataObjectModificationAfter) {
        /*
         * The update is not of interest as the attributes populated from this listener will not change.
         * The northbound updates are handled in AclInterfaceListener.
         */
    }

    @Override
    protected void add(InstanceIdentifier<Interface> key, Interface dataObjectModification) {
        AclInterface aclInterface = updateAclInterfaceCache(dataObjectModification);
        if (AclServiceUtils.isOfInterest(aclInterface)) {
            List<Uuid> aclList = aclInterface.getSecurityGroups();
            if (aclList != null) {
                aclDataUtil.addAclInterfaceMap(aclList, aclInterface);
            }
            if (aclClusterUtil.isEntityOwner()) {
                aclServiceManger.notify(aclInterface, null, Action.ADD);
            }
        }
    }

    @Override
    protected AclInterfaceStateListener getDataTreeChangeListener() {
        return AclInterfaceStateListener.this;
    }

    private AclInterface updateAclInterfaceCache(Interface dataObjectModification) {
        String interfaceId = dataObjectModification.getName();
        AclInterface aclInterface = AclInterfaceCacheUtil.getAclInterfaceFromCache(interfaceId);
        if (aclInterface == null) {
            aclInterface = new AclInterface();
            AclInterfaceCacheUtil.addAclInterfaceToCache(interfaceId, aclInterface);
        }
        aclInterface.setDpId(AclServiceUtils.getDpIdFromIterfaceState(dataObjectModification));
        aclInterface.setLPortTag(dataObjectModification.getIfIndex());
        aclInterface.setIsMarkedForDelete(false);
        return aclInterface;
    }
}
