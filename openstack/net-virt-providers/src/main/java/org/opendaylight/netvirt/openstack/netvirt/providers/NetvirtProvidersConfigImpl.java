/*
 * Copyright (c) 2016 Red Hat, Inc. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.openstack.netvirt.providers;

import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.ThreadFactory;

import com.google.common.util.concurrent.ThreadFactoryBuilder;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.DataChangeListener;
import org.opendaylight.controller.md.sal.common.api.data.AsyncDataBroker;
import org.opendaylight.controller.md.sal.common.api.data.AsyncDataChangeEvent;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.netvirt.utils.mdsal.utils.MdsalUtils;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.netvirt.providers.config.rev160109.NetvirtProvidersConfig;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.netvirt.providers.config.rev160109.NetvirtProvidersConfigBuilder;
import org.opendaylight.yangtools.concepts.ListenerRegistration;
import org.opendaylight.yangtools.yang.binding.DataObject;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.osgi.framework.BundleContext;
import org.osgi.framework.ServiceReference;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class NetvirtProvidersConfigImpl implements AutoCloseable, ConfigInterface, DataChangeListener {
    private static final Logger LOG = LoggerFactory.getLogger(NetvirtProvidersConfigImpl.class);
    private final DataBroker dataBroker;
    private final ListenerRegistration<DataChangeListener> registration;
    private static final ThreadFactory threadFactory = new ThreadFactoryBuilder()
        .setNameFormat("NV-ProviderCfg-%d").build();
    private final ExecutorService executorService = Executors.newFixedThreadPool(1, threadFactory);
    private final MdsalUtils mdsalUtils;

    public NetvirtProvidersConfigImpl(final DataBroker dataBroker, final short tableOffset) {
        this.dataBroker = dataBroker;
        mdsalUtils = new MdsalUtils(dataBroker);

        InstanceIdentifier<NetvirtProvidersConfig> path =
                InstanceIdentifier.builder(NetvirtProvidersConfig.class).build();
        registration = dataBroker.registerDataChangeListener(LogicalDatastoreType.CONFIGURATION, path, this,
                AsyncDataBroker.DataChangeScope.SUBTREE);

        NetvirtProvidersConfigBuilder netvirtProvidersConfigBuilder = new NetvirtProvidersConfigBuilder();
        NetvirtProvidersConfig netvirtProvidersConfig =
                mdsalUtils.read(LogicalDatastoreType.CONFIGURATION, path);
        if (netvirtProvidersConfig != null) {
            netvirtProvidersConfigBuilder = new NetvirtProvidersConfigBuilder(netvirtProvidersConfig);
        }
        if (netvirtProvidersConfigBuilder.getTableOffset() == null) {
            netvirtProvidersConfigBuilder.setTableOffset(tableOffset);
        }
        boolean result = mdsalUtils.merge(LogicalDatastoreType.CONFIGURATION, path,
                netvirtProvidersConfigBuilder.build());

        LOG.info("NetvirtProvidersConfigImpl: dataBroker= {}, registration= {}, tableOffset= {}, result= {}",
                dataBroker, registration, tableOffset, result);
    }

    @Override
    public void close() throws Exception {
        registration.close();
        executorService.shutdown();
    }

    @Override
    public void onDataChanged(final AsyncDataChangeEvent<InstanceIdentifier<?>, DataObject> asyncDataChangeEvent) {
        executorService.submit(new Runnable() {

            @Override
            public void run() {
                LOG.info("onDataChanged: {}", asyncDataChangeEvent);
                processConfigCreate(asyncDataChangeEvent);
                processConfigUpdate(asyncDataChangeEvent);
            }
        });
    }

    private void processConfigCreate(AsyncDataChangeEvent<InstanceIdentifier<?>, DataObject> changes) {
        for (Map.Entry<InstanceIdentifier<?>, DataObject> entry : changes.getCreatedData().entrySet()) {
            if (entry.getValue() instanceof NetvirtProvidersConfig) {
                NetvirtProvidersConfig netvirtProvidersConfig = (NetvirtProvidersConfig) entry.getValue();
                applyConfig(netvirtProvidersConfig);
            }
        }
    }

    private void processConfigUpdate(AsyncDataChangeEvent<InstanceIdentifier<?>, DataObject> changes) {
        for (Map.Entry<InstanceIdentifier<?>, DataObject> entry : changes.getUpdatedData().entrySet()) {
            if (entry.getValue() instanceof NetvirtProvidersConfig) {
                LOG.info("processConfigUpdate: {}", entry);
                NetvirtProvidersConfig netvirtProvidersConfig = (NetvirtProvidersConfig) entry.getValue();
                applyConfig(netvirtProvidersConfig);
            }
        }
    }

    private void applyConfig(NetvirtProvidersConfig netvirtProvidersConfig) {
        LOG.info("processConfigUpdate: {}", netvirtProvidersConfig);
        if (netvirtProvidersConfig.getTableOffset() != null) {
            NetvirtProvidersProvider.setTableOffset(netvirtProvidersConfig.getTableOffset());
        }
        if (netvirtProvidersConfig.getSecurityGroupTcpIdleTimeout() != null) {
            NetvirtProvidersProvider.setSecurityGroupTcpIdleTimeout(netvirtProvidersConfig.getSecurityGroupTcpIdleTimeout());
        }
        if (netvirtProvidersConfig.getSecurityGroupTcpHardTimeout() != null) {
            NetvirtProvidersProvider.setSecurityGroupTcpHardTimeout(netvirtProvidersConfig.getSecurityGroupTcpHardTimeout());
        }
        if (netvirtProvidersConfig.getSecurityGroupTcpFinIdleTimeout() != null) {
            NetvirtProvidersProvider.setSecurityGroupTcpFinIdleTimeout(netvirtProvidersConfig.getSecurityGroupTcpFinIdleTimeout());
        }
        if (netvirtProvidersConfig.getSecurityGroupTcpFinHardTimeout() != null) {
            NetvirtProvidersProvider.setSecurityGroupTcpFinHardTimeout(netvirtProvidersConfig.getSecurityGroupTcpFinHardTimeout());
        }
        if (netvirtProvidersConfig.getSecurityGroupUdpIdleTimeout() != null) {
            NetvirtProvidersProvider.setSecurityGroupUdpIdleTimeout(netvirtProvidersConfig.getSecurityGroupUdpIdleTimeout());
        }
        if (netvirtProvidersConfig.getSecurityGroupUdpHardTimeout() != null) {
            NetvirtProvidersProvider.setSecurityGroupUdpHardTimeout(netvirtProvidersConfig.getSecurityGroupUdpHardTimeout());
        }
        if (netvirtProvidersConfig.getSecurityGroupDefaultIdleTimeout() != null) {
            NetvirtProvidersProvider.setSecurityGroupDefaultIdleTimeout(netvirtProvidersConfig.getSecurityGroupDefaultIdleTimeout());
        }
        if (netvirtProvidersConfig.getSecurityGroupDefaultHardTimeout() != null) {
            NetvirtProvidersProvider.setSecurityGroupDefaultHardTimeout(netvirtProvidersConfig.getSecurityGroupDefaultHardTimeout());
        }
    }

    @Override
    public void setDependencies(BundleContext bundleContext, ServiceReference serviceReference) {

    }

    @Override
    public void setDependencies(Object impl) {

    }
}
