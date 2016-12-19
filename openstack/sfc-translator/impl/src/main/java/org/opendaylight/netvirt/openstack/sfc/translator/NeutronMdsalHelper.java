/*
 * Copyright (c) 2016 Brocade Communications Systems, Inc. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.openstack.sfc.translator;

import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.netvirt.utils.mdsal.utils.MdsalUtils;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.ports.attributes.Ports;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.ports.attributes.ports.Port;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.ports.attributes.ports.PortKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.rev150712.Neutron;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.sfc.flow.classifier.rev160511.sfc.flow.classifiers.attributes.SfcFlowClassifiers;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.sfc.flow.classifier.rev160511.sfc.flow.classifiers.attributes.sfc.flow.classifiers.SfcFlowClassifier;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.sfc.flow.classifier.rev160511.sfc.flow.classifiers.attributes.sfc.flow.classifiers.SfcFlowClassifierKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.sfc.rev160511.sfc.attributes.PortPairGroups;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.sfc.rev160511.sfc.attributes.PortPairs;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.sfc.rev160511.sfc.attributes.port.pair.groups.PortPairGroup;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.sfc.rev160511.sfc.attributes.port.pair.groups.PortPairGroupKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.sfc.rev160511.sfc.attributes.port.pairs.PortPair;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.sfc.rev160511.sfc.attributes.port.pairs.PortPairKey;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Utility functions to read Neutron models (e.g network, subnet, port, sfc flow classifier
 * port pair, port group, port chain) from md-sal data store.
 */
public class NeutronMdsalHelper {
    private static final Logger LOG = LoggerFactory.getLogger(NeutronMdsalHelper.class);
    private static final InstanceIdentifier<SfcFlowClassifiers> fcIid =
            InstanceIdentifier.create(Neutron.class).child(SfcFlowClassifiers.class);
    private static final InstanceIdentifier<Ports> portsIid =
            InstanceIdentifier.create(Neutron.class).child(Ports.class);
    private static final InstanceIdentifier<PortPairs> portPairsIid =
            InstanceIdentifier.create(Neutron.class).child(PortPairs.class);
    private static final InstanceIdentifier<PortPairGroups> portPairGroupsIid =
            InstanceIdentifier.create(Neutron.class).child(PortPairGroups.class);

    private final DataBroker dataBroker;
    private final MdsalUtils mdsalUtils;

    public NeutronMdsalHelper(DataBroker dataBroker) {
        this.dataBroker = dataBroker;
        mdsalUtils = new MdsalUtils(this.dataBroker);
    }

    public Port getNeutronPort(Uuid portId) {
        Port neutronPort = mdsalUtils.read(LogicalDatastoreType.CONFIGURATION , getNeutronPortPath(portId));
        return neutronPort;
    }

    public PortPair getNeutronPortPair(Uuid portPairId) {
        PortPair neutronPortPair
                = mdsalUtils.read(LogicalDatastoreType.CONFIGURATION , getNeutronPortPairPath(portPairId));
        return neutronPortPair;
    }

    public PortPairGroup getNeutronPortPairGroup(Uuid portPairGroupId) {
        PortPairGroup neutronPortPairGroup
                = mdsalUtils.read(LogicalDatastoreType.CONFIGURATION , getNeutronPortPairGroupPath(portPairGroupId));
        return neutronPortPairGroup;
    }

    public SfcFlowClassifier getNeutronFlowClassifier(Uuid flowClassifierId) {
        SfcFlowClassifier sfcFlowClassifier
                = mdsalUtils.read(LogicalDatastoreType.CONFIGURATION , getNeutronSfcFlowClassifierPath(flowClassifierId));
        return sfcFlowClassifier;
    }

    private InstanceIdentifier<Port> getNeutronPortPath(Uuid portId) {
        return portsIid.builder().child(Port.class, new PortKey(portId)).build();
    }

    private InstanceIdentifier<PortPair> getNeutronPortPairPath(Uuid portPairId) {
        return portPairsIid.builder().child(PortPair.class, new PortPairKey(portPairId)).build();
    }

    private InstanceIdentifier<PortPairGroup> getNeutronPortPairGroupPath(Uuid portPairGroupId) {
        return portPairGroupsIid.builder().child(PortPairGroup.class, new PortPairGroupKey(portPairGroupId)).build();
    }

    private InstanceIdentifier<SfcFlowClassifier> getNeutronSfcFlowClassifierPath(Uuid portId) {
        return fcIid.builder().child(SfcFlowClassifier.class, new SfcFlowClassifierKey(portId)).build();
    }
}
