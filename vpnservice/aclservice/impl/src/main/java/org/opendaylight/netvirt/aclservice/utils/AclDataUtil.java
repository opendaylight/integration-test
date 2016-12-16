/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.aclservice.utils;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import javax.inject.Singleton;
import org.opendaylight.netvirt.aclservice.api.utils.AclInterface;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;

@Singleton
public class AclDataUtil {

    private final Map<Uuid, List<AclInterface>> aclInterfaceMap = new ConcurrentHashMap<>();
    private final Map<Uuid, List<Uuid>> remoteAclIdMap = new ConcurrentHashMap<>();
    private final Map<String, Integer> aclFlowPriorityMap = new ConcurrentHashMap<>();

    public synchronized void addAclInterfaceMap(List<Uuid> aclList, AclInterface port) {
        for (Uuid acl : aclList) {
            List<AclInterface> interfaceList = aclInterfaceMap.get(acl);
            if (interfaceList == null) {
                interfaceList = new ArrayList<>();
                interfaceList.add(port);
                aclInterfaceMap.put(acl, interfaceList);
            } else {
                interfaceList.add(port);
            }
        }
    }

    public synchronized void removeAclInterfaceMap(List<Uuid> aclList, AclInterface port) {
        for (Uuid acl : aclList) {
            List<AclInterface> interfaceList = aclInterfaceMap.get(acl);
            if (interfaceList != null) {
                interfaceList.remove(port);
            }
        }
    }

    public List<AclInterface> getInterfaceList(Uuid acl) {
        return aclInterfaceMap.get(acl);
    }

    /**
     * Gets the set of ACL interfaces per ACL (in a map) which has specified
     * remote ACL ID.
     *
     * @param remoteAclId the remote acl id
     * @return the set of ACL interfaces per ACL (in a map) which has specified
     *         remote ACL ID.
     */
    public Map<String, Set<AclInterface>> getRemoteAclInterfaces(Uuid remoteAclId) {
        List<Uuid> remoteAclList = getRemoteAcl(remoteAclId);
        if (remoteAclList == null) {
            return null;
        }
        Map<String, Set<AclInterface>> mapOfAclWithInterfaces = new HashMap<>();
        for (Uuid acl : remoteAclList) {
            Set<AclInterface> interfaceSet = new HashSet<>();
            List<AclInterface> interfaces = getInterfaceList(acl);
            if (interfaces != null && !interfaces.isEmpty()) {
                interfaceSet.addAll(interfaces);
                mapOfAclWithInterfaces.put(acl.getValue(), interfaceSet);
            }
        }
        return mapOfAclWithInterfaces;
    }

    public synchronized void addRemoteAclId(Uuid remoteAclId, Uuid aclId) {
        List<Uuid> aclList = remoteAclIdMap.get(remoteAclId);
        if (aclList == null) {
            aclList = new ArrayList<>();
            aclList.add(aclId);
            remoteAclIdMap.put(remoteAclId, aclList);
        } else {
            aclList.add(aclId);
        }
    }

    public synchronized void removeRemoteAclId(Uuid remoteAclId, Uuid aclId) {
        List<Uuid> aclList = remoteAclIdMap.get(remoteAclId);
        if (aclList != null) {
            aclList.remove(aclId);
        }
    }

    public List<Uuid> getRemoteAcl(Uuid remoteAclId) {
        return remoteAclIdMap.get(remoteAclId);
    }

    /**
     * Adds the acl flow priority to the cache.
     *
     * @param aclName the acl name
     * @param flowPriority the flow priority
     */
    public void addAclFlowPriority(final String aclName, final Integer flowPriority) {
        this.aclFlowPriorityMap.put(aclName, flowPriority);
    }

    /**
     * Removes the acl flow priority from the cache.
     *
     * @param aclName the acl name
     */
    public void removeAclFlowPriority(final String aclName) {
        this.aclFlowPriorityMap.remove(aclName);
    }

    /**
     * Gets the acl flow priority from the cache.
     *
     * @param aclName the acl name
     * @return the acl flow priority
     */
    public Integer getAclFlowPriority(final String aclName) {
        Integer priority = this.aclFlowPriorityMap.get(aclName);
        if (priority == null) {
            // Set to default value
            priority = AclConstants.PROTO_MATCH_PRIORITY;
        }
        return priority;
    }
}
