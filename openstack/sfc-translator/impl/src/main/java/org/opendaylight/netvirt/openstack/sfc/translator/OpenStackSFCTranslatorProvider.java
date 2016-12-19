/*
 * Copyright (c) 2016 Brocade Communications Systems, Inc. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.openstack.sfc.translator;

import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.netvirt.openstack.sfc.translator.flowclassifier.NeutronFlowClassifierListener;
import org.opendaylight.netvirt.openstack.sfc.translator.portchain.NeutronPortChainListener;
import org.opendaylight.netvirt.openstack.sfc.translator.portchain.NeutronPortPairGroupListener;
import org.opendaylight.netvirt.openstack.sfc.translator.portchain.NeutronPortPairListener;
import org.opendaylight.yang.gen.v1.urn.cisco.params.xml.ns.yang.sfc.rsp.rev140701.RenderedServicePathService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.netvirt.openstack.sfc.translator.config.rev160720.OpenstackSfcTranslatorConfig;
import org.osgi.framework.BundleContext;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class OpenStackSFCTranslatorProvider implements AutoCloseable {
    private static final Logger LOG = LoggerFactory.getLogger(OpenStackSFCTranslatorProvider.class);

    private static BundleContext bundleContext;
    private final DataBroker dataBroker;
    private final RenderedServicePathService rspService;
    private final OpenstackSfcTranslatorConfig openstackSfcTranslatorConfig;

    public OpenStackSFCTranslatorProvider(
            final DataBroker dataBroker,
            final RenderedServicePathService rspService,
            final OpenstackSfcTranslatorConfig openstackSfcTranslatorConfig,
            BundleContext bundleContext) {
        this.dataBroker = dataBroker;
        this.rspService = rspService;
        this.openstackSfcTranslatorConfig = openstackSfcTranslatorConfig;
        this.bundleContext = bundleContext;
    }

    //This method will be called by blueprint, during bundle initialization.
    public void start() {
        LOG.info("OpenStack SFC Translator Session started");
        new NeutronFlowClassifierListener(dataBroker);
        new NeutronPortPairListener(dataBroker);
        new NeutronPortPairGroupListener(dataBroker);
        new NeutronPortChainListener(dataBroker, rspService);
        if (this.rspService == null) {
            LOG.warn("RenderedServicePath Service is not available. Translation layer might not work as expected.");
        }
    }

    @Override
    public void close() throws Exception {
        LOG.info("OpenStack SFC Translator Closed");
    }
}