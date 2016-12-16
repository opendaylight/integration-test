/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.aclservice.api.utils;

import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public final class AclInterfaceCacheUtil {
    private static final Logger LOG = LoggerFactory.getLogger(AclInterfaceCacheUtil.class);

    static ConcurrentMap<String, AclInterface> cachedMap = new ConcurrentHashMap<>();

    public static void addAclInterfaceToCache(String interfaceId, AclInterface aclInterface) {
        cachedMap.put(interfaceId, aclInterface);
    }

    public static synchronized void removeAclInterfaceFromCache(String interfaceId) {
        AclInterface aclInterface = cachedMap.get(interfaceId);
        if (aclInterface == null) {
            LOG.warn("AclInterface object not found in cache for interface {}", interfaceId);
            return;
        }
        if (aclInterface.isMarkedForDelete()) {
            cachedMap.remove(interfaceId);
        } else {
            aclInterface.setIsMarkedForDelete(true);
        }
    }

    public static AclInterface getAclInterfaceFromCache(String interfaceId) {
        return cachedMap.get(interfaceId);
    }

    private AclInterfaceCacheUtil() { }
}
