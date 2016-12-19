/*
 * Copyright (c) 2016 Hewlett Packard Enterprise, Co. and others. All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.elanmanager.api;

import java.util.List;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.etree.rev160614.EtreeInterface;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.etree.rev160614.EtreeInterface.EtreeInterfaceType;

public interface IEtreeService {

    void deleteEtreeInterface(String elanInstanceName, String interfaceName);

    boolean deleteEtreeInstance(String elanInstanceName);

    void addEtreeInterface(String elanInstanceName, String interfaceName, EtreeInterfaceType interfaceType,
            List<String> staticMacAddresses, String description);

    boolean createEtreeInstance(String elanInstanceName, long macTimeout, String description);

    EtreeInterface getEtreeInterfaceByElanInterfaceName(String elanInterface);
}
