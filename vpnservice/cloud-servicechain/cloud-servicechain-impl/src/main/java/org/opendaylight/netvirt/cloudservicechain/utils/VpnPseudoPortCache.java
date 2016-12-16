/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.cloudservicechain.utils;

import java.util.List;
import java.util.concurrent.ConcurrentHashMap;

import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.genius.utils.cache.CacheUtil;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.cloud.servicechain.state.rev170511.vpn.to.pseudo.port.list.VpnToPseudoPortData;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Manages a per-blade cache, which is feeded by a clustered data change
 * listener.
 *
 */
public class VpnPseudoPortCache {

    public static final Logger LOG = LoggerFactory.getLogger(VpnPseudoPortCache.class);
    public static final String VPNPSEUDOPORT_CACHE_NAME = "VrfToVpnPseudoPortCache";

    public static void createVpnPseudoPortCache(DataBroker broker) {
        if (CacheUtil.getCache(VPNPSEUDOPORT_CACHE_NAME) == null) {
            CacheUtil.createCache(VPNPSEUDOPORT_CACHE_NAME);
            initialLoadFromDS(broker);
        }
    }

    public static void destroyVpnPseudoPortCache() {
        if (CacheUtil.getCache(VPNPSEUDOPORT_CACHE_NAME) != null) {
            CacheUtil.destroyCache(VPNPSEUDOPORT_CACHE_NAME);
        }
    }

    private static void initialLoadFromDS(DataBroker broker) {
        LOG.info("Initial read of Vpn to VpnPseudoPort map from Datastore");
        List<VpnToPseudoPortData> allVpnToPseudoPortData = VpnServiceChainUtils.getAllVpnToPseudoPortData(broker);
        for ( VpnToPseudoPortData vpnToPseudoPort : allVpnToPseudoPortData ) {
            addVpnPseudoPortToCache(vpnToPseudoPort.getVrfId(), vpnToPseudoPort.getVpnLportTag());
        }
    }

    public static void addVpnPseudoPortToCache(String vrfId, long vpnPseudoLportTag) {
        LOG.debug("Adding vpn {} and vpnPseudoLportTag {} to VpnPseudoPortCache", vrfId, vpnPseudoLportTag);
        ConcurrentHashMap<String, Long> cache =
            (ConcurrentHashMap<String, Long>) CacheUtil.getCache(VPNPSEUDOPORT_CACHE_NAME);
        cache.put(vrfId, vpnPseudoLportTag);
    }

    public static Long getVpnPseudoPortTagFromCache(String vrfId) {
        ConcurrentHashMap<String, Long> cache =
            (ConcurrentHashMap<String, Long>) CacheUtil.getCache(VPNPSEUDOPORT_CACHE_NAME);
        return cache.get(vrfId);
    }

    public static void removeVpnPseudoPortFromCache(String vrfId) {
        LOG.debug("Removing vpn {} from VpnPseudoPortCache", vrfId);
        ConcurrentHashMap<String, Long> cache =
            (ConcurrentHashMap<String, Long>) CacheUtil.getCache(VPNPSEUDOPORT_CACHE_NAME);
        cache.remove(vrfId);
    }


}
