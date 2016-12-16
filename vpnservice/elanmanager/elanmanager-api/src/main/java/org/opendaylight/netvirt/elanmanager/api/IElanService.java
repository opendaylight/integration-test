/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.elanmanager.api;

import java.math.BigInteger;
import java.util.Collection;
import java.util.List;
import org.opendaylight.netvirt.elanmanager.exceptions.MacNotFoundException;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.instances.ElanInstance;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.interfaces.ElanInterface;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.forwarding.entries.MacEntry;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.Node;

public interface IElanService extends IEtreeService {

    boolean createElanInstance(String elanInstanceName, long macTimeout, String description);

    void updateElanInstance(String elanInstanceName, long newMacTimout, String newDescription);

    boolean deleteElanInstance(String elanInstanceName);

    void addElanInterface(String elanInstanceName, String interfaceName, List<String> staticMacAddresses,
            String description);

    void updateElanInterface(String elanInstanceName, String interfaceName, List<String> updatedStaticMacAddresses,
            String newDescription);

    void deleteElanInterface(String elanInstanceName, String interfaceName);

    void addStaticMacAddress(String elanInstanceName, String interfaceName, String macAddress);

    void deleteStaticMacAddress(String elanInstanceName, String interfaceName, String macAddress)
            throws MacNotFoundException;

    Collection<MacEntry> getElanMacTable(String elanInstanceName);

    void flushMACTable(String elanInstanceName);

    ElanInstance getElanInstance(String elanInstanceName);

    List<ElanInstance> getElanInstances();

    List<String> getElanInterfaces(String elanInstanceName);

    void createExternalElanNetwork(ElanInstance elanInstance);

    void createExternalElanNetworks(Node node);

    void updateExternalElanNetworks(Node origNode, Node updatedNode);

    void deleteExternalElanNetwork(ElanInstance elanInstance);

    void deleteExternalElanNetworks(Node node);

    Collection<String> getExternalElanInterfaces(String elanInstanceName);

    String getExternalElanInterface(String elanInstanceName, BigInteger dpnId);

    boolean isExternalInterface(String interfaceName);

    ElanInterface getElanInterfaceByElanInterfaceName(String interfaceName);

    void handleKnownL3DmacAddress(String macAddress, String elanInstanceName, int addOrRemove);
}
