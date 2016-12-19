/*
 * Copyright (c) 2015 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.cloudservicechain;


import org.opendaylight.netvirt.cloudservicechain.api.ICloudServiceChain;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class CloudServiceChainProvider implements ICloudServiceChain {

    private static final Logger LOG = LoggerFactory.getLogger(CloudServiceChainProvider.class);

    private final VPNServiceChainHandler vpnServiceChainHandler;
    private final ElanServiceChainHandler elanServiceChainHandler;

    public CloudServiceChainProvider(VPNServiceChainHandler vpnServiceChainHandler,
                                     ElanServiceChainHandler elanServiceChainHandler) {
        this.vpnServiceChainHandler = vpnServiceChainHandler;
        this.elanServiceChainHandler = elanServiceChainHandler;
    }

    @Override
    public void programVpnToScfPipeline(String vpnId, short tableId, long scfTag, int lportTag, int addOrRemove) {
        LOG.info("L3VPN Service chaining :programVpnToScfPipeline [Started] {} {} {} {} {}",
                 vpnId, tableId,scfTag, lportTag, addOrRemove);
        vpnServiceChainHandler.programVpnToScfPipeline(vpnId, tableId, scfTag, lportTag, addOrRemove);
    }

    @Override
    public void programScfToVpnPipeline(String vpnId, long scfTag, int scsTag, long dpnId, int lportTag,
                                        boolean isLastServiceChain, int addOrRemove) {
        LOG.info("L3VPN Service chaining :programScfToVpnPipeline [Started] {} {} {} {}", vpnId, scfTag,
                 dpnId, lportTag);
        vpnServiceChainHandler.programScfToVpnPipeline(vpnId, scfTag, scsTag, dpnId, lportTag, isLastServiceChain,
                                                       addOrRemove);
    }

    /* (non-Javadoc)
     * @see org.opendaylight.netvirtchain.api.IVpnServiceChain#removeVpnPseudoPortFlows(java.lang.String, int)
     */
    @Override
    public void removeVpnPseudoPortFlows(String vpnInstanceName, int vpnPseudoLportTag) {
        LOG.info("L3VPN Service chaining :removeVpnPseudoPortFlows [Started] vpnPseudoLportTag={}", vpnPseudoLportTag);
        vpnServiceChainHandler.removeVpnPseudoPortFlows(vpnInstanceName, vpnPseudoLportTag);
    }

    @Override
    public void programElanScfPipeline(String elanName, short tableId, long scfTag, int elanLportTag,
                                       boolean isLastServiceChain, int addOrRemove) {
        LOG.info("ELAN Service chaining :programElanScfPipeline [Started] {} {} {} {} {}",
                 elanName, tableId, scfTag, elanLportTag, addOrRemove);
        elanServiceChainHandler.programElanScfPipeline(elanName, tableId, scfTag, elanLportTag, addOrRemove);
    }

    @Override
    public void programElanScfPipeline(String elanName, short tableId, int scfTag, int elanLportTag, int addOrRemove) {
        LOG.info("ELAN Service chaining :programElanScfPipeline [Started] {} {} {} {} {}",
                 elanName, tableId, scfTag, elanLportTag, addOrRemove);
        elanServiceChainHandler.programElanScfPipeline(elanName, tableId, scfTag, elanLportTag, addOrRemove);
    }

    @Override
    public void removeElanPseudoPortFlows(String elanName, int elanPseudoLportTag) {
        LOG.info("ELAN Service chaining :removeElanPseudoPortFlows [Started] elanPseudoLportTag={}",
                 elanPseudoLportTag);
        elanServiceChainHandler.removeElanPseudoPortFlows(elanName, elanPseudoLportTag);
    }

}
