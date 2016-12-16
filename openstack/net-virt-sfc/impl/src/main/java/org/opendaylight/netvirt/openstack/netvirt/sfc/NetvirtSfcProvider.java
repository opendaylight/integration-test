/*
 * Copyright © 2015, 2016 Dell, Inc. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.openstack.netvirt.sfc;

import com.google.common.base.Preconditions;
import java.util.Dictionary;
import java.util.Hashtable;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.netvirt.openstack.netvirt.api.Constants;
import org.opendaylight.netvirt.openstack.netvirt.providers.openflow13.AbstractServiceInstance;
import org.opendaylight.netvirt.openstack.netvirt.providers.openflow13.OF13Provider;
import org.opendaylight.netvirt.openstack.netvirt.providers.openflow13.Service;
import org.opendaylight.netvirt.openstack.netvirt.sfc.standalone.openflow13.NetvirtSfcStandaloneOF13Provider;
import org.opendaylight.netvirt.openstack.netvirt.sfc.standalone.openflow13.services.SfcClassifierService;
import org.opendaylight.netvirt.openstack.netvirt.sfc.workaround.NetvirtSfcWorkaroundOF13Provider;
import org.opendaylight.netvirt.utils.mdsal.utils.MdsalUtils;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.netvirt.sfc.impl.config.rev160517.NetvirtSfcConfig;
import org.osgi.framework.BundleContext;
import org.osgi.framework.ServiceRegistration;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class NetvirtSfcProvider implements AutoCloseable {
    private static final Logger LOG = LoggerFactory.getLogger(NetvirtSfcProvider.class);

    private AutoCloseable aclListener;
    private AutoCloseable classifierListener;
    private AutoCloseable rspListener;

    private final Boolean addSfFlows;
    private final String of13Provider;

    private final DataBroker dataBroker;
    private final BundleContext bundleContext;

    private ServiceRegistration<?> reg;

    public NetvirtSfcProvider(final DataBroker dataBroker, final NetvirtSfcConfig netvirtSfcConfig, final BundleContext bundleContext) {
        LOG.info("NetvirtSfcProvider started");
        this.dataBroker = dataBroker;
        this.addSfFlows = Preconditions.checkNotNull(netvirtSfcConfig.isAddsflows(), "AddsFlow must be configured");
        this.of13Provider = Preconditions.checkNotNull(netvirtSfcConfig.getOf13provider(), " Provider type must be configured");
        this.bundleContext = bundleContext;
    }

    public void start() {
        LOG.info("NetvirtSfcProvider Session Initiated");

        MdsalUtils mdsalUtils = new MdsalUtils(dataBroker);
        SfcUtils sfcUtils = new SfcUtils(mdsalUtils);

        // Allocate provider based on config
        INetvirtSfcOF13Provider provider;
        if (of13Provider.equals("standalone")) {
            provider = new NetvirtSfcStandaloneOF13Provider(dataBroker);
        } else {
            provider = new NetvirtSfcWorkaroundOF13Provider(dataBroker, mdsalUtils, sfcUtils, addSfFlows);
        }
        aclListener = new NetvirtSfcAclListener(provider, dataBroker);
        classifierListener = new NetvirtSfcClassifierListener(provider, dataBroker);
        rspListener = new RspListener(provider, dataBroker);

        addToPipeline(provider);
        provider.setDependencies(null);
    }

    @Override
    public void close() throws Exception {
        LOG.info("NetvirtSfcProvider Closed");
        if (aclListener != null) {
            aclListener.close();
        }
        if (classifierListener != null) {
            classifierListener.close();
        }
        if (rspListener != null) {
            rspListener.close();
        }
        if (reg != null) {
            reg.unregister();
        }
    }

    private void addToPipeline(INetvirtSfcOF13Provider provider) {
        if (provider instanceof NetvirtSfcStandaloneOF13Provider) {
            SfcClassifierService sfcClassifierService =
                    new SfcClassifierService();
            reg = registerService(bundleContext, ISfcClassifierService.class.getName(),
                    sfcClassifierService, Service.SFC_CLASSIFIER);
            sfcClassifierService.setDependencies(bundleContext, null);
        } else {
            org.opendaylight.netvirt.openstack.netvirt.sfc.workaround.services.SfcClassifierService sfcClassifierService =
                    new org.opendaylight.netvirt.openstack.netvirt.sfc.workaround.services.SfcClassifierService();
            reg = registerService(bundleContext, ISfcClassifierService.class.getName(),
                    sfcClassifierService, Service.SFC_CLASSIFIER);
            sfcClassifierService.setDependencies(bundleContext, null);
        }

        //provider.setSfcClassifierService(sfcClassifierService);
    }

    private ServiceRegistration<?> registerService(BundleContext bundleContext, String[] interfaces,
                                                   Dictionary<String, Object> properties, Object impl) {
        ServiceRegistration<?> serviceRegistration = bundleContext.registerService(interfaces, impl, properties);
        return serviceRegistration;
    }

    private ServiceRegistration<?> registerService(BundleContext bundleContext, String interfaceClassName,
                                                       Object impl, Object serviceProperty) {
        Dictionary<String, Object> properties = new Hashtable<>();
        properties.put(AbstractServiceInstance.SERVICE_PROPERTY, serviceProperty);
        properties.put(Constants.PROVIDER_NAME_PROPERTY, OF13Provider.NAME);
        return registerService(bundleContext,
                new String[] {AbstractServiceInstance.class.getName(),interfaceClassName},
                properties, impl);
    }
}