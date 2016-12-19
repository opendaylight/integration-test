/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.elan.l2gw.ha.commands;

import org.opendaylight.controller.md.sal.binding.api.ReadWriteTransaction;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.Node;
import org.opendaylight.yangtools.concepts.Builder;
import org.opendaylight.yangtools.yang.binding.DataObject;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;

public interface IMergeCommand<T extends DataObject, Y extends Builder, Z extends DataObject> {

    /**
     * Abstract function to merge data from src to dst in Operational Topology.
     * while existing data helps in keeping track of data only updated
     * @param dst Builder which will be used to build concrete object
     * @param existingData dataObject which are already exisitng
     * @param src dataObjects of source
     * @param nodePath nodePath of dest
     */
    void mergeOperationalData(Y dst,
                              Z existingData,
                              Z src,
                              InstanceIdentifier<Node> nodePath);

    /**
     * Abstract function to merge data from src to dst in Config Topology.
     * @param dst builder which will be used to build concrete object
     * @param src builder which are to be merged in destination
     * @param nodePath nodePath of dest
     */
    void mergeConfigData(Y dst,
                         Z src,
                         InstanceIdentifier<Node> nodePath);

    /**
     * Abstract function to update data from src to dst in Config Topology.
     * while existing data helps in keeping track of data only updated
     * @param existingData dataObject which are already exisitng
     * @param updated updated data
     * @param orig original data
     * @param nodePath nodePath of dest
     * @param tx ReadWriteTransaction
     */
    void mergeConfigUpdate(Z existingData,
                           Z updated,
                           Z orig,
                           InstanceIdentifier<Node> nodePath,
                           ReadWriteTransaction tx);

    /**
     * Abstract function to update data from src to dst in Operational Topology.
     * while existing data helps in keeping track of data only updated
     * @param existingData dataObject which are already exisitng
     * @param updatedSrc updated data source
     * @param origSrc original data source
     * @param nodePath nodePath of dest
     * @param tx ReadWriteTransaction
     */
    void mergeOpUpdate(Z existingData,
                       Z updatedSrc,
                       Z origSrc,
                       InstanceIdentifier<Node> nodePath,
                       ReadWriteTransaction tx);

}
