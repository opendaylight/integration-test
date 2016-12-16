/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.elanmanager.utils;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;
import org.opendaylight.genius.utils.cache.CacheUtil;
import org.opendaylight.netvirt.neutronvpn.api.l2gw.L2GatewayDevice;

public class ElanL2GwCacheUtils {

    private static final ConcurrentHashMap<String, L2GatewayDevice> EMPTY_MAP = new ConcurrentHashMap<>();
    public static final String L2GATEWAY_CONN_CACHE_NAME = "L2GWCONN";

    private ElanL2GwCacheUtils() {
    }

    static {
        CacheUtil.createCache(ElanL2GwCacheUtils.L2GATEWAY_CONN_CACHE_NAME);
    }

    public static void addL2GatewayDeviceToCache(String elanName, L2GatewayDevice l2GwDevice) {
        ConcurrentMap<String, ConcurrentMap<String, L2GatewayDevice>> cachedMap =
                (ConcurrentMap<String, ConcurrentMap<String, L2GatewayDevice>>) CacheUtil.getCache(
                        ElanL2GwCacheUtils.L2GATEWAY_CONN_CACHE_NAME);
        ConcurrentMap<String, L2GatewayDevice> deviceMap = cachedMap.get(elanName);
        if (deviceMap == null) {
            synchronized (ElanL2GwCacheUtils.class) {
                deviceMap = cachedMap.get(elanName);
                if (deviceMap == null) {
                    deviceMap = new ConcurrentHashMap<>();
                    cachedMap.put(elanName, deviceMap);
                }
            }
        }
        deviceMap.put(l2GwDevice.getHwvtepNodeId(), l2GwDevice);
    }

    public static void removeL2GatewayDeviceFromAllElanCache(String deviceName) {
        ConcurrentMap<String, ConcurrentMap<String, L2GatewayDevice>> cachedMap =
                (ConcurrentMap<String, ConcurrentMap<String, L2GatewayDevice>>) CacheUtil.getCache(
                        ElanL2GwCacheUtils.L2GATEWAY_CONN_CACHE_NAME);
        for (String elanName : cachedMap.keySet()) {
            ConcurrentMap<String, L2GatewayDevice> deviceMap = cachedMap.get(elanName);
            if (deviceMap != null) {
                deviceMap.remove(deviceName);
            }
        }
    }


    public static L2GatewayDevice removeL2GatewayDeviceFromCache(String elanName, String l2gwDeviceNodeId) {
        ConcurrentMap<String, ConcurrentMap<String, L2GatewayDevice>> cachedMap =
                (ConcurrentMap<String, ConcurrentMap<String, L2GatewayDevice>>) CacheUtil.getCache(
                        ElanL2GwCacheUtils.L2GATEWAY_CONN_CACHE_NAME);
        ConcurrentMap<String, L2GatewayDevice> deviceMap = cachedMap.get(elanName);
        if (deviceMap != null) {
            L2GatewayDevice device = deviceMap.remove(l2gwDeviceNodeId);
            return device;
        } else {
            return null;
        }
    }

    public static L2GatewayDevice getL2GatewayDeviceFromCache(String elanName, String l2gwDeviceNodeId) {
        ConcurrentMap<String, ConcurrentMap<String, L2GatewayDevice>> cachedMap =
                (ConcurrentMap<String, ConcurrentMap<String, L2GatewayDevice>>) CacheUtil.getCache(
                        ElanL2GwCacheUtils.L2GATEWAY_CONN_CACHE_NAME);
        ConcurrentMap<String, L2GatewayDevice> deviceMap = cachedMap.get(elanName);
        if (deviceMap != null) {
            return deviceMap.get(l2gwDeviceNodeId);
        } else {
            return null;
        }
    }

    public static ConcurrentMap<String, L2GatewayDevice> getInvolvedL2GwDevices(String elanName) {
        ConcurrentMap<String, ConcurrentMap<String, L2GatewayDevice>> cachedMap =
                (ConcurrentMap<String, ConcurrentMap<String, L2GatewayDevice>>) CacheUtil
                .getCache(ElanL2GwCacheUtils.L2GATEWAY_CONN_CACHE_NAME);
        ConcurrentMap<String, L2GatewayDevice> result = cachedMap.get(elanName);
        if (result == null) {
            result = EMPTY_MAP;
        }
        return result;
    }

    public static List<L2GatewayDevice> getAllElanDevicesFromCache() {
        ConcurrentMap<String, ConcurrentMap<String, L2GatewayDevice>> cachedMap =
                (ConcurrentMap<String, ConcurrentMap<String, L2GatewayDevice>>) CacheUtil.getCache(
                        ElanL2GwCacheUtils.L2GATEWAY_CONN_CACHE_NAME);
        if (cachedMap == null || cachedMap.isEmpty()) {
            return null;
        }

        List<L2GatewayDevice> l2GwDevices = new ArrayList<>();
        for (ConcurrentMap<String, L2GatewayDevice> l2gwDevices : cachedMap.values()) {
            for (L2GatewayDevice l2gwDevice : l2gwDevices.values() ) {
                l2GwDevices.add(l2gwDevice);
            }
        }

        return l2GwDevices;
    }

}
