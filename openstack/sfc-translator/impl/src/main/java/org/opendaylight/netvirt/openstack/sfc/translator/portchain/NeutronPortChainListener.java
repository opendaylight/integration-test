/*
 * Copyright (c) 2016 Brocade Communications Systems, Inc. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.openstack.sfc.translator.portchain;

import com.google.common.util.concurrent.ThreadFactoryBuilder;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.DataTreeIdentifier;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.netvirt.openstack.sfc.translator.DelegatingDataTreeListener;
import org.opendaylight.netvirt.openstack.sfc.translator.NeutronMdsalHelper;
import org.opendaylight.netvirt.openstack.sfc.translator.OvsdbMdsalHelper;
import org.opendaylight.netvirt.openstack.sfc.translator.OvsdbPortMetadata;
import org.opendaylight.netvirt.openstack.sfc.translator.SfcMdsalHelper;
import org.opendaylight.netvirt.openstack.sfc.translator.flowclassifier.FlowClassifierTranslator;
import org.opendaylight.yang.gen.v1.urn.cisco.params.xml.ns.yang.sfc.rsp.rev140701.CreateRenderedPathInput;
import org.opendaylight.yang.gen.v1.urn.cisco.params.xml.ns.yang.sfc.rsp.rev140701.CreateRenderedPathOutput;
import org.opendaylight.yang.gen.v1.urn.cisco.params.xml.ns.yang.sfc.rsp.rev140701.DeleteRenderedPathInput;
import org.opendaylight.yang.gen.v1.urn.cisco.params.xml.ns.yang.sfc.rsp.rev140701.RenderedServicePathService;
import org.opendaylight.yang.gen.v1.urn.cisco.params.xml.ns.yang.sfc.sf.rev140701.service.functions.ServiceFunction;
import org.opendaylight.yang.gen.v1.urn.cisco.params.xml.ns.yang.sfc.sf.rev140701.service.functions.ServiceFunctionBuilder;
import org.opendaylight.yang.gen.v1.urn.cisco.params.xml.ns.yang.sfc.sfc.rev140701.service.function.chain.grouping.ServiceFunctionChain;
import org.opendaylight.yang.gen.v1.urn.cisco.params.xml.ns.yang.sfc.sff.rev140701.service.function.forwarders.ServiceFunctionForwarder;
import org.opendaylight.yang.gen.v1.urn.cisco.params.xml.ns.yang.sfc.sff.rev140701.service.function.forwarders.ServiceFunctionForwarderBuilder;
import org.opendaylight.yang.gen.v1.urn.cisco.params.xml.ns.yang.sfc.sfp.rev140701.service.function.paths.ServiceFunctionPath;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.access.control.list.rev160218.access.lists.Acl;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.ports.attributes.ports.Port;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.rev150712.Neutron;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.sfc.flow.classifier.rev160511.sfc.flow.classifiers.attributes.sfc.flow.classifiers.SfcFlowClassifier;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.sfc.rev160511.sfc.attributes.PortChains;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.sfc.rev160511.sfc.attributes.port.chains.PortChain;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.sfc.rev160511.sfc.attributes.port.pair.groups.PortPairGroup;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.sfc.rev160511.sfc.attributes.port.pairs.PortPair;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.Topology;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.opendaylight.yangtools.yang.common.RpcResult;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.ThreadFactory;

/**
 * OpenDaylight Neutron Port Chain yang models data change listener
 */
public class NeutronPortChainListener extends DelegatingDataTreeListener<PortChain> {
    private static final Logger LOG = LoggerFactory.getLogger(NeutronPortChainListener.class);

    private static final InstanceIdentifier<PortChain> portChainIid =
            InstanceIdentifier.create(Neutron.class).child(PortChains.class).child(PortChain.class);
    private final ExecutorService eventProcessor;
    private final SfcMdsalHelper sfcMdsalHelper;
    private final NeutronMdsalHelper neutronMdsalHelper;
    private final OvsdbMdsalHelper ovsdbMdsalHelper;
    private RenderedServicePathService rspService;

    public NeutronPortChainListener(DataBroker db, RenderedServicePathService rspService) {
        super(db,new DataTreeIdentifier<>(LogicalDatastoreType.CONFIGURATION, portChainIid));
        this.sfcMdsalHelper = new SfcMdsalHelper(db);
        this.neutronMdsalHelper = new NeutronMdsalHelper(db);
        this.ovsdbMdsalHelper = new OvsdbMdsalHelper(db);
        this.rspService = rspService;
        ThreadFactory threadFactory = new ThreadFactoryBuilder().setNameFormat("Port-Chain-Event-Processor").build();
        this.eventProcessor = Executors.newSingleThreadExecutor(threadFactory);
    }

    /**
     * Method removes PortChain which is identified by InstanceIdentifier.
     *
     * @param path - the whole path to PortChain
     * @param deletedPortChain        - PortChain for removing
     */
    @Override
    public void remove(InstanceIdentifier<PortChain> path, PortChain deletedPortChain) {
        if(this.rspService != null) {
            DeleteRenderedPathInput deleteRenderedPathInput =
                    PortChainTranslator.buildDeleteRenderedServicePathInput(PortChainTranslator
                    .getSFPKey(deletedPortChain));
            if (deleteRenderedPathInput != null ) {
                this.rspService.deleteRenderedPath(deleteRenderedPathInput);
            }
        }
        sfcMdsalHelper.deleteServiceFunctionPath(PortChainTranslator.getSFPKey(deletedPortChain));
        sfcMdsalHelper.deleteServiceFunctionChain(PortChainTranslator.getSFCKey(deletedPortChain));
    }

    /**
     * Method updates the original PortChain to the update PortChain.
     * Both are identified by same InstanceIdentifier.
     *
     * @param path - the whole path to PortChain
     * @param originalPortChain   - original PortChain (for update)
     * @param updatePortChain     - changed PortChain (contain updates)
     */
    @Override
    public void update(InstanceIdentifier<PortChain> path, PortChain originalPortChain, PortChain updatePortChain) {
        //TODO: Add support for chain update
    }

    /**
     * Method adds the PortChain which is identified by InstanceIdentifier
     * to device.
     *
     * @param path - the whole path to new PortChain
     * @param newPortChain        - new PortChain
     */
    @Override
    public void add(final InstanceIdentifier<PortChain> path, final PortChain newPortChain) {
        processPortChain(newPortChain);
        eventProcessor.submit(new Runnable() {
            @Override
            public void run() {
                processPortChain(newPortChain);
            }
        });
    }

    private void processPortChain(PortChain newPortChain) {
        //List of Port Pair Group attached to the Port Chain
        List<PortPairGroup> portPairGroupList = new ArrayList<>();
        //Port Pair Group and associated Port Pair
        Map<Uuid, List<PortPair>> groupPortPairsList = new HashMap<>();
        //Map of Port Pair uuid and Port pair ingress port related Neutron Port
        Map<Uuid, Port> portPairToNeutronPortMap = new HashMap<>();

        //Mapping of Port Pair UUID and OvsdbPortMetadata of the port pair ingress port
        Map<Uuid, OvsdbPortMetadata> portPairOvsdbMetadata = new HashMap<>();

        Map<Uuid, ServiceFunctionForwarderBuilder> portPairGroupToSFFMap = new HashMap<>();
        List<ServiceFunction> portChainServiceFunctionList = new ArrayList<>();

        //Read chain related port pair group, port pair and neutron port from neutron data store
        for (Uuid ppgUuid : newPortChain.getPortPairGroups()) {
            PortPairGroup ppg = neutronMdsalHelper.getNeutronPortPairGroup(ppgUuid);
            if (ppg != null) {
                List<PortPair> portPairList = new ArrayList<>();
                portPairGroupList.add(ppg);
                for(Uuid ppUuid : ppg.getPortPairs()) {
                    PortPair pp = neutronMdsalHelper.getNeutronPortPair(ppUuid);
                    if (pp != null) {
                        portPairList.add(pp);
                        //NOTE:Assuming that ingress and egress port is same.
                        Port neutronPort = neutronMdsalHelper.getNeutronPort(pp.getIngress());
                        if (neutronPort != null) {
                            portPairToNeutronPortMap.put(pp.getIngress(), neutronPort);
                        }
                    }
                }
                groupPortPairsList.put(ppgUuid, portPairList);
            }
        }

        Topology ovsdbTopology = ovsdbMdsalHelper.getOvsdbTopologyTree();

        //Read ovsdb port details related to neutron port. Each Port pair has two neutron port
        //With the current implementation, i am assuming that we support SF only with single port
        //that act as a ingress as well as egress.
        for(Map.Entry<Uuid, Port> neutronPortEntry : portPairToNeutronPortMap.entrySet()) {
            OvsdbPortMetadata ovsdbPortMetadata =
                    ovsdbMdsalHelper.getOvsdbPortMetadata(
                            neutronPortEntry.getValue().getKey().getUuid(),
                            ovsdbTopology);

            if(ovsdbPortMetadata != null) {
                portPairOvsdbMetadata.put(neutronPortEntry.getKey(), ovsdbPortMetadata);
            }
        }

        //For each port pair group
        for (PortPairGroup ppg : portPairGroupList) {
            List<ServiceFunctionBuilder> portPairSFList = new ArrayList<>();

            List<PortPair> portPairList =  groupPortPairsList.get(ppg.getUuid());
            Map<Uuid, OvsdbPortMetadata> metadataList = new HashMap<>();
            //Generate OvsdbPortMetadata for list of all the port pair
            for (PortPair portPair : portPairList) {
                OvsdbPortMetadata metadata = portPairOvsdbMetadata.get(portPair.getIngress());

                if (metadata != null) {
                    metadataList.put(portPair.getIngress(), metadata);
                }
            }

            //Build the SFF Builder from port pair group
            ServiceFunctionForwarderBuilder sffBuilder =
                    PortPairGroupTranslator.buildServiceFunctionForwarder(ppg,portPairList, metadataList);
            LOG.info("SFF generated for Port Pair Group {} :: {}",ppg, sffBuilder);
            //Check if SFF already exist
            ServiceFunctionForwarder existingSff =
                    sfcMdsalHelper.getExistingSFF(sffBuilder.getIpMgmtAddress().getIpv4Address().getValue());
            if(existingSff != null) {
                LOG.info("SFF already exist for Port Pair Group {}. Existing SFF is {}",ppg, existingSff);
                sffBuilder = new ServiceFunctionForwarderBuilder(existingSff);
            }
            //Add SFF builder to the map for later reference
            portPairGroupToSFFMap.put(ppg.getUuid(), sffBuilder);

            //Generate all the SF and write it to SFC data store
            for (PortPair portPair : portPairList) {
                OvsdbPortMetadata metadata = portPairOvsdbMetadata.get(portPair.getIngress());
                //Build the service function for the given port pair.
                ServiceFunctionBuilder sfBuilder = PortPairTranslator.buildServiceFunction(portPair,
                        ppg,
                        portPairToNeutronPortMap.get(portPair.getIngress()),
                        metadata,
                        sffBuilder.build());

                if (sfBuilder != null) {
                    LOG.info("Service Function generated for the Port Pair {} :: {}", portPair, sfBuilder);
                    //Write the Service Function to SFC data store.
                    sfcMdsalHelper.addServiceFunction(sfBuilder.build());

                    //Add to the list, to populated SFF Service Function Dictionary
                    portPairSFList.add(sfBuilder);

                    //Add the SF to Port Chain related SF list
                    portChainServiceFunctionList.add(sfBuilder.build());
                } else {
                    LOG.warn("Service Function building failed for Port Pair {}", portPair);
                }
            }

            //Update the Service Function Dictionary of SFF
            for (ServiceFunctionBuilder sf : portPairSFList) {
                PortPairGroupTranslator.buildServiceFunctionDictonary(sffBuilder, sf.build());
                LOG.info("Updating Service Function dictionary of SFF {} for SF {}", sffBuilder, sf);
            }
            // Send SFF create request
            LOG.info("Add Service Function Forwarder {} for Port Pair Group {}", sffBuilder.build(), ppg);
            sfcMdsalHelper.addServiceFunctionForwarder(sffBuilder.build());
        }
        //Build Service Function Chain Builder
        ServiceFunctionChain sfc =
                PortChainTranslator.buildServiceFunctionChain(newPortChain, portChainServiceFunctionList);

        //Write SFC to data store
        if (sfc != null) {
            LOG.info("Add service function chain {}", sfc);
            sfcMdsalHelper.addServiceFunctionChain(sfc);
        } else {
            LOG.warn("Service Function Chain building failed for Port Chain {}", newPortChain);
        }

        // Build Service Function Path Builder
        ServiceFunctionPath sfp = PortChainTranslator.buildServiceFunctionPath(sfc);
        //Write SFP to data store
        if (sfp != null) {
            LOG.info("Add service function path {}", sfp);
           sfcMdsalHelper.addServiceFunctionPath(sfp);
        } else {
            LOG.warn("Service Function Path building failed for Service Chain {}", sfc);
        }

        //TODO:Generate Flow Classifiers and augment RSP on it.

        if (this.rspService != null) {
            // Build Create Rendered Service Path input
            CreateRenderedPathInput rpInput = PortChainTranslator.buildCreateRenderedServicePathInput(sfp);

            //Call Create Rendered Service Path RPC call
            if (rpInput != null) {
                LOG.info("Call RPC for creating RSP :{}", rpInput);
                Future<RpcResult<CreateRenderedPathOutput>> result =  this.rspService.createRenderedPath(rpInput);
                try {
                    if (result.get() != null) {
                        CreateRenderedPathOutput output = result.get().getResult();
                        LOG.debug("RSP name received from SFC : {}", output.getName());
                        processFlowClassifiers(newPortChain, newPortChain.getFlowClassifiers(), output.getName());
                    } else {
                        LOG.error("RSP creation failed : {}", rpInput);
                    }
                } catch (InterruptedException | ExecutionException e) {
                    LOG.error("Error occurred during creating Rendered Service Path using RPC call", e);
                }
            }
        } else {
            LOG.error("Rendered Path Service is not available, can't create Rendered Path for Port Chain", newPortChain);
        }
    }

    private void processFlowClassifiers(PortChain pc, List<Uuid> flowClassifiers, String rspName) {
        for (Uuid uuid : flowClassifiers) {
            SfcFlowClassifier fc = neutronMdsalHelper.getNeutronFlowClassifier(uuid);
            if (fc != null) {
                Acl acl = FlowClassifierTranslator.buildAcl(fc, rspName);
                if (acl != null ) {
                    sfcMdsalHelper.addAclFlowClassifier(acl);
                } else {
                    LOG.warn("Acl building failed for flow classifier {}. Traffic might not be redirected to RSP", fc);
                }

            } else {
                LOG.error("Neutron Flow Classifier {} attached to Port Chain {} is not present in the neutron data " +
                        "store", uuid, pc);
            }
        }
    }
}
