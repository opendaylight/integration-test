/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.neutronvpn.api.l2gw.utils;

import java.util.concurrent.ConcurrentMap;

import org.opendaylight.netvirt.neutronvpn.api.l2gw.L2GatewayDevice;
import org.opendaylight.genius.utils.cache.CacheUtil;

public class L2GatewayCacheUtils {
    public static final String L2GATEWAY_CACHE_NAME = "L2GW";

    public static void createL2DeviceCache() {
        if (CacheUtil.getCache(L2GatewayCacheUtils.L2GATEWAY_CACHE_NAME) == null) {
            CacheUtil.createCache(L2GatewayCacheUtils.L2GATEWAY_CACHE_NAME);
        }
    }

    public static void addL2DeviceToCache(String devicename, L2GatewayDevice l2GwDevice) {
        ConcurrentMap<String, L2GatewayDevice> cachedMap = (ConcurrentMap<String, L2GatewayDevice>) CacheUtil
                .getCache(L2GatewayCacheUtils.L2GATEWAY_CACHE_NAME);
        cachedMap.put(devicename, l2GwDevice);
    }

    public static L2GatewayDevice removeL2DeviceFromCache(String devicename) {
        ConcurrentMap<String, L2GatewayDevice> cachedMap = (ConcurrentMap<String, L2GatewayDevice>) CacheUtil
                .getCache(L2GatewayCacheUtils.L2GATEWAY_CACHE_NAME);
        return cachedMap.remove(devicename);
    }

    public static L2GatewayDevice getL2DeviceFromCache(String devicename) {
        ConcurrentMap<String, L2GatewayDevice> cachedMap = (ConcurrentMap<String, L2GatewayDevice>) CacheUtil
                .getCache(L2GatewayCacheUtils.L2GATEWAY_CACHE_NAME);
        return cachedMap.get(devicename);
    }

    public static ConcurrentMap<String, L2GatewayDevice> getCache() {
        return (ConcurrentMap<String, L2GatewayDevice>) CacheUtil
                .getCache(L2GatewayCacheUtils.L2GATEWAY_CACHE_NAME);
    }

}
