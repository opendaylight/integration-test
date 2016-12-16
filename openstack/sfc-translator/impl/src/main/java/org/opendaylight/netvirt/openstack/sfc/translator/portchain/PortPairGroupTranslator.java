/*
 * Copyright (c) 2016 Brocade Communications Systems, Inc. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.openstack.sfc.translator.portchain;

import com.google.common.base.Preconditions;
import org.opendaylight.netvirt.openstack.sfc.translator.OvsdbMdsalHelper;
import org.opendaylight.netvirt.openstack.sfc.translator.OvsdbPortMetadata;
import org.opendaylight.yang.gen.v1.urn.cisco.params.xml.ns.yang.sfc.common.rev151017.SffDataPlaneLocatorName;
import org.opendaylight.yang.gen.v1.urn.cisco.params.xml.ns.yang.sfc.common.rev151017.SffName;
import org.opendaylight.yang.gen.v1.urn.cisco.params.xml.ns.yang.sfc.common.rev151017.SnName;
import org.opendaylight.yang.gen.v1.urn.cisco.params.xml.ns.yang.sfc.sf.rev140701.service.functions.ServiceFunction;
import org.opendaylight.yang.gen.v1.urn.cisco.params.xml.ns.yang.sfc.sff.ovs.rev140701.SffOvsBridgeAugmentation;
import org.opendaylight.yang.gen.v1.urn.cisco.params.xml.ns.yang.sfc.sff.ovs.rev140701.SffOvsBridgeAugmentationBuilder;
import org.opendaylight.yang.gen.v1.urn.cisco.params.xml.ns.yang.sfc.sff.ovs.rev140701.SffOvsLocatorOptionsAugmentation;
import org.opendaylight.yang.gen.v1.urn.cisco.params.xml.ns.yang.sfc.sff.ovs.rev140701.SffOvsLocatorOptionsAugmentationBuilder;
import org.opendaylight.yang.gen.v1.urn.cisco.params.xml.ns.yang.sfc.sff.ovs.rev140701.SffOvsNodeAugmentation;
import org.opendaylight.yang.gen.v1.urn.cisco.params.xml.ns.yang.sfc.sff.ovs.rev140701.SffOvsNodeAugmentationBuilder;
import org.opendaylight.yang.gen.v1.urn.cisco.params.xml.ns.yang.sfc.sff.ovs.rev140701.bridge.OvsBridgeBuilder;
import org.opendaylight.yang.gen.v1.urn.cisco.params.xml.ns.yang.sfc.sff.ovs.rev140701.node.OvsNodeBuilder;
import org.opendaylight.yang.gen.v1.urn.cisco.params.xml.ns.yang.sfc.sff.ovs.rev140701.options.OvsOptionsBuilder;
import org.opendaylight.yang.gen.v1.urn.cisco.params.xml.ns.yang.sfc.sff.rev140701.Open;
import org.opendaylight.yang.gen.v1.urn.cisco.params.xml.ns.yang.sfc.sff.rev140701.service.function.forwarder.base.SffDataPlaneLocator;
import org.opendaylight.yang.gen.v1.urn.cisco.params.xml.ns.yang.sfc.sff.rev140701.service.function.forwarder.base.SffDataPlaneLocatorBuilder;
import org.opendaylight.yang.gen.v1.urn.cisco.params.xml.ns.yang.sfc.sff.rev140701.service.function.forwarder.base.SffDataPlaneLocatorKey;
import org.opendaylight.yang.gen.v1.urn.cisco.params.xml.ns.yang.sfc.sff.rev140701.service.function.forwarder.base.sff.data.plane.locator.DataPlaneLocatorBuilder;
import org.opendaylight.yang.gen.v1.urn.cisco.params.xml.ns.yang.sfc.sff.rev140701.service.function.forwarders.ServiceFunctionForwarderBuilder;
import org.opendaylight.yang.gen.v1.urn.cisco.params.xml.ns.yang.sfc.sff.rev140701.service.function.forwarders.ServiceFunctionForwarderKey;
import org.opendaylight.yang.gen.v1.urn.cisco.params.xml.ns.yang.sfc.sff.rev140701.service.function.forwarders.service.function.forwarder.ServiceFunctionDictionary;
import org.opendaylight.yang.gen.v1.urn.cisco.params.xml.ns.yang.sfc.sff.rev140701.service.function.forwarders.service.function.forwarder.ServiceFunctionDictionaryBuilder;
import org.opendaylight.yang.gen.v1.urn.cisco.params.xml.ns.yang.sfc.sff.rev140701.service.function.forwarders.service.function.forwarder.ServiceFunctionDictionaryKey;
import org.opendaylight.yang.gen.v1.urn.cisco.params.xml.ns.yang.sfc.sff.rev140701.service.function.forwarders.service.function.forwarder.service.function.dictionary.SffSfDataPlaneLocatorBuilder;
import org.opendaylight.yang.gen.v1.urn.cisco.params.xml.ns.yang.sfc.sl.rev140701.VxlanGpe;
import org.opendaylight.yang.gen.v1.urn.cisco.params.xml.ns.yang.sfc.sl.rev140701.data.plane.locator.locator.type.IpBuilder;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.sfc.rev160511.sfc.attributes.port.pair.groups.PortPairGroup;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.sfc.rev160511.sfc.attributes.port.pairs.PortPair;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.rev150105.OvsdbBridgeAugmentation;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.rev150105.OvsdbNodeAugmentation;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * Class will convert OpenStack Port Pair API yang models present in
 * neutron northbound project to OpenDaylight SFC yang models.
 */
public class PortPairGroupTranslator {
    private static final Logger LOG = LoggerFactory.getLogger(PortPairGroupTranslator.class);
    private static final String OPT_FLOW_STR = "flow";
    private static final String OPT_GPE_STR = "gpe";
    private static final String OPT_DST_PORT = "6633";

    private static final AtomicInteger counter = new AtomicInteger(0);
    private static final String SFF_DEFAULT_NAME = "sff";
    private static final String SFF_DPL_SUFFIX = "-dpl";
    private static final String SFF_DPL_FIX_NAME = "vxgpe";

    public static ServiceFunctionForwarderBuilder buildServiceFunctionForwarder(
            PortPairGroup portPairGroup,
            List<PortPair> portPairs,
            Map<Uuid, OvsdbPortMetadata> ovsdbPortsMetadata) {
        Preconditions.checkNotNull(portPairGroup, "Port pair group must not be null");

        ServiceFunctionForwarderBuilder sffBuilder = new ServiceFunctionForwarderBuilder();
        SffOvsBridgeAugmentationBuilder sffOvsBridgeAugBuilder = new SffOvsBridgeAugmentationBuilder();
        SffOvsNodeAugmentationBuilder sffOvsNodeAugBuilder = new SffOvsNodeAugmentationBuilder();

        List<SffDataPlaneLocator> sffDataPlaneLocator = new ArrayList<>();
        SffDataPlaneLocatorBuilder sffDplBuilder = new SffDataPlaneLocatorBuilder();
        DataPlaneLocatorBuilder dplBuilder = new DataPlaneLocatorBuilder();

        IpBuilder sffLocator = new IpBuilder();

        //Currently we only support one SF per type. Mean, one port-pair per port-pair-group.
        //Get port pair from neutron data store.
        PortPair portPair = portPairs.get(0);
        if (portPair == null) {
           LOG.error("Port pair {} does not exist in the neutron data store. Port Pair Group {} request can't be " +
                   "processed.", portPairGroup.getPortPairs().get(0), portPairGroup);
            return null;
        }
        //Get metadata of neutron port related to port pair ingress port from ovsdb data store.
        OvsdbPortMetadata ovsdbPortMetadata = ovsdbPortsMetadata.get(portPair.getIngress());

        //Convert the port pair to service function

        //Set SFF DPL transport type
        dplBuilder.setTransport(VxlanGpe.class);

        //Set SFF Locator Type
        OvsdbNodeAugmentation ovsdbNodeAug = ovsdbPortMetadata.getOvsdbNode();
        if (ovsdbNodeAug != null ) {
            sffLocator.setIp(ovsdbNodeAug.getConnectionInfo().getRemoteIp());
            sffLocator.setPort(ovsdbNodeAug.getConnectionInfo().getRemotePort());
        }
        dplBuilder.setLocatorType(sffLocator.build());
        //set data-path-locator for sff-data-path-locator
        sffDplBuilder.setDataPlaneLocator(dplBuilder.build());

        //Set location options for sff-dp-locator
        sffDplBuilder.addAugmentation(SffOvsLocatorOptionsAugmentation.class, buildOvsOptions().build());

        //Set ovsdb bridge name for sff
        OvsBridgeBuilder ovsBridgeBuilder = new OvsBridgeBuilder();
        OvsdbBridgeAugmentation ovsdbBridgeAugmentation = ovsdbPortMetadata.getOvsdbBridgeNode();
        if (ovsdbBridgeAugmentation != null) {
            ovsBridgeBuilder.setBridgeName(ovsdbBridgeAugmentation.getBridgeName().getValue());

            //Set SFF name
            String serviceNode = OvsdbMdsalHelper.getNodeKey(ovsdbBridgeAugmentation.getManagedBy().getValue());
            if(serviceNode.isEmpty()) {
                serviceNode += SFF_DEFAULT_NAME + counter.incrementAndGet();
                sffBuilder.setName(new SffName(serviceNode));
                sffBuilder.setServiceNode(new SnName(serviceNode));
            } else {
                //Set service node to ovsdbNode
                sffBuilder.setServiceNode(new SnName(serviceNode));

                //Set SFF name to ovsdbBridgeNode
                serviceNode += "/" + ovsdbBridgeAugmentation.getBridgeName().getValue();
                sffBuilder.setName(new SffName(serviceNode));
            }

            //Set ovsdb-node iid reference for SFF
            OvsNodeBuilder ovsNodeBuilder = new OvsNodeBuilder();
            ovsNodeBuilder.setNodeId(ovsdbBridgeAugmentation.getManagedBy());
            sffOvsNodeAugBuilder.setOvsNode(ovsNodeBuilder.build());
            sffBuilder.addAugmentation(SffOvsNodeAugmentation.class, sffOvsNodeAugBuilder.build());
        }
        sffOvsBridgeAugBuilder.setOvsBridge(ovsBridgeBuilder.build());
        sffBuilder.addAugmentation(SffOvsBridgeAugmentation.class, sffOvsBridgeAugBuilder.build());

        //Set management ip, same to the ovsdb  node ip
        sffBuilder.setIpMgmtAddress(sffLocator.getIp());

        //TODO: DPL name should not be hardcoded. Require net-virt classifier to remove dependency on it.
        sffDplBuilder.setName(new SffDataPlaneLocatorName(SFF_DPL_FIX_NAME));
        sffDplBuilder.setKey(new SffDataPlaneLocatorKey(sffDplBuilder.getName()));
        sffDataPlaneLocator.add(sffDplBuilder.build());
        //set SFF key
        sffBuilder.setKey(new ServiceFunctionForwarderKey(sffBuilder.getName()));
        sffBuilder.setSffDataPlaneLocator(sffDataPlaneLocator);

        return sffBuilder;
    }

    public static void buildServiceFunctionDictonary(ServiceFunctionForwarderBuilder sffBuilder,
                                                                           ServiceFunction sf) {
        List<ServiceFunctionDictionary> sfdList = new ArrayList<>();
        ServiceFunctionDictionaryBuilder sfdBuilder = new ServiceFunctionDictionaryBuilder();

        //Build Sff-sf-data-plane-locator
        SffSfDataPlaneLocatorBuilder sffSfDplBuilder = new SffSfDataPlaneLocatorBuilder();
        sffSfDplBuilder.setSfDplName(sf.getSfDataPlaneLocator().get(0).getName());
        sffSfDplBuilder.setSffDplName(sffBuilder.getSffDataPlaneLocator().get(0).getName());
        sfdBuilder.setSffSfDataPlaneLocator(sffSfDplBuilder.build());

        sfdBuilder.setName(sf.getName());
        sfdBuilder.setKey(new ServiceFunctionDictionaryKey(sfdBuilder.getName()));

        //NOTE: fail mode is set to Open by default
        sfdBuilder.setFailmode(Open.class);
        sfdList.add(sfdBuilder.build());

        //TODO: set interface name list

        if (sffBuilder.getServiceFunctionDictionary() != null) {
            for (Iterator<ServiceFunctionDictionary> sfdItr = sffBuilder.getServiceFunctionDictionary().iterator();sfdItr
                    .hasNext();) {
                ServiceFunctionDictionary sfd = sfdItr.next();
                if (sfd.getName().equals(sfdBuilder.getName())) {
                    LOG.info("Existing SF dictionary {} found in SFF {}, removing the SF dictionary", sfd.getName(),
                            sffBuilder.getName());
                    sfdItr.remove();
                    break;
                }
            }
            sffBuilder.getServiceFunctionDictionary().addAll(sfdList);
        } else {
            sffBuilder.setServiceFunctionDictionary(sfdList);
        }
        LOG.info("Final Service Function Dictionary {}", sffBuilder.getServiceFunctionDictionary());
    }

    private static SffOvsLocatorOptionsAugmentationBuilder buildOvsOptions() {
        SffOvsLocatorOptionsAugmentationBuilder ovsOptions = new SffOvsLocatorOptionsAugmentationBuilder();
        OvsOptionsBuilder ovsOptionsBuilder = new OvsOptionsBuilder();
        ovsOptionsBuilder.setRemoteIp(OPT_FLOW_STR);
        ovsOptionsBuilder.setDstPort(OPT_DST_PORT);
        ovsOptionsBuilder.setKey(OPT_FLOW_STR);
        ovsOptionsBuilder.setExts(OPT_GPE_STR);
        ovsOptions.setOvsOptions(ovsOptionsBuilder.build());
        return ovsOptions;
    }
}
