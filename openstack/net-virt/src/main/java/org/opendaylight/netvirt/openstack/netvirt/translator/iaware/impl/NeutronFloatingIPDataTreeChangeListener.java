/*
 * Copyright © 2015, 2016 Brocade Communications Systems, Inc. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.openstack.netvirt.translator.iaware.impl;

import java.util.Collection;
import javax.annotation.Nonnull;
import javax.annotation.PostConstruct;
import org.opendaylight.controller.md.sal.binding.api.ClusteredDataTreeChangeListener;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.DataTreeChangeListener;
import org.opendaylight.controller.md.sal.binding.api.DataTreeIdentifier;
import org.opendaylight.controller.md.sal.binding.api.DataTreeModification;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.netvirt.openstack.netvirt.translator.NeutronFloatingIP;
import org.opendaylight.netvirt.openstack.netvirt.translator.iaware.INeutronFloatingIPAware;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.l3.rev150712.floatingips.attributes.Floatingips;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.l3.rev150712.floatingips.attributes.floatingips.Floatingip;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.rev150712.Neutron;
import org.opendaylight.yangtools.concepts.ListenerRegistration;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class NeutronFloatingIPDataTreeChangeListener
        implements ClusteredDataTreeChangeListener<Floatingip>, AutoCloseable {
    private static final Logger LOG = LoggerFactory.getLogger(NeutronFloatingIPDataTreeChangeListener.class);

    private final DataBroker dataBroker;
    private ListenerRegistration<DataTreeChangeListener<Floatingip>> registration;

    public NeutronFloatingIPDataTreeChangeListener(DataBroker dataBroker) {
        this.dataBroker = dataBroker;
    }

    @PostConstruct
    public void init() {
        InstanceIdentifier<Floatingip> path = InstanceIdentifier
                .create(Neutron.class)
                .child(Floatingips.class)
                .child(Floatingip.class);
        LOG.debug("Register listener for Neutron FloatingIp model data changes");
        registration = dataBroker.registerDataTreeChangeListener(
                new DataTreeIdentifier<>(LogicalDatastoreType.CONFIGURATION, path), this);
    }

    @Override
    public void onDataTreeChanged(@Nonnull Collection<DataTreeModification<Floatingip>> changes) {
        LOG.trace("Data changes : {}", changes);

        Object[] subscribers = NeutronIAwareUtil.getInstances(INeutronFloatingIPAware.class, this);
        createFloatingIP(changes, subscribers);
        updateFloatingIP(changes, subscribers);
        deleteFloatingIP(changes, subscribers);
    }

    private void createFloatingIP(
            @Nonnull Collection<DataTreeModification<Floatingip>> changes,
            Object[] subscribers) {
        for (DataTreeModification<Floatingip> change : changes) {
            if (change.getRootNode().getDataAfter() != null && change.getRootNode().getDataBefore() == null) {
                NeutronFloatingIP floatingIp = fromMd(change.getRootNode().getDataAfter());
                for (Object entry : subscribers) {
                    INeutronFloatingIPAware subscriber = (INeutronFloatingIPAware) entry;
                    subscriber.neutronFloatingIPCreated(floatingIp);
                }
            }
        }
    }

    private void updateFloatingIP(
            @Nonnull Collection<DataTreeModification<Floatingip>> changes,
            Object[] subscribers) {
        for (DataTreeModification<Floatingip> change : changes) {
            if (change.getRootNode().getDataAfter() != null && change.getRootNode().getDataBefore() != null) {
                NeutronFloatingIP floatingIp = fromMd(change.getRootNode().getDataAfter());
                for (Object entry : subscribers) {
                    INeutronFloatingIPAware subscriber = (INeutronFloatingIPAware) entry;
                    subscriber.neutronFloatingIPUpdated(floatingIp);
                }
            }
        }
    }

    private void deleteFloatingIP(
            @Nonnull Collection<DataTreeModification<Floatingip>> changes,
            Object[] subscribers) {
        for (DataTreeModification<Floatingip> change : changes) {
            if (change.getRootNode().getDataAfter() == null && change.getRootNode().getDataBefore() != null) {
                NeutronFloatingIP floatingIp = fromMd(change.getRootNode().getDataBefore());
                for (Object entry : subscribers) {
                    INeutronFloatingIPAware subscriber = (INeutronFloatingIPAware) entry;
                    subscriber.neutronFloatingIPDeleted(floatingIp);
                }
            }
        }
    }

    /*
     * This method is borrowed from NeutronFloatingIPInterface.java class of Neutron Northbound class.
     * We will be utilizing similar code from other classes from the same package of neutron project.
     */
    private NeutronFloatingIP fromMd(Floatingip fip) {
        NeutronFloatingIP result = new NeutronFloatingIP();
        result.setID(fip.getUuid().getValue());
        if (fip.getFloatingNetworkId() != null) {
            result.setFloatingNetworkUUID(fip.getFloatingNetworkId().getValue());
        }
        if (fip.getPortId() != null) {
            result.setPortUUID(fip.getPortId().getValue());
        }
        if (fip.getFixedIpAddress() != null) {
            result.setFixedIPAddress(String.valueOf(fip.getFixedIpAddress().getValue()));
        }
        if (fip.getFloatingIpAddress() != null) {
            result.setFloatingIPAddress(String.valueOf(fip.getFloatingIpAddress().getValue()));
        }
        if (fip.getTenantId() != null) {
            result.setTenantUUID(fip.getTenantId().getValue());
        }
        if (fip.getRouterId() != null) {
            result.setRouterUUID(fip.getRouterId().getValue());
        }
        result.setStatus(fip.getStatus());
        return result;
    }

    @Override
    public void close() {
        registration.close();
    }
}
