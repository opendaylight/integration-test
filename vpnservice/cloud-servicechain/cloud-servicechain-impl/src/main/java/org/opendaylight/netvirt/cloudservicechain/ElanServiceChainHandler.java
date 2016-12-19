/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.cloudservicechain;

import com.google.common.base.Optional;
import java.math.BigInteger;
import java.util.Collection;
import java.util.List;

import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.mdsalutil.MDSALUtil;
import org.opendaylight.genius.mdsalutil.NWUtil;
import org.opendaylight.genius.mdsalutil.NwConstants;
import org.opendaylight.genius.mdsalutil.interfaces.IMdsalApiManager;
import org.opendaylight.netvirt.cloudservicechain.utils.ElanServiceChainUtils;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.cloud.servicechain.state.rev170511.ElanServiceChainState;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.cloud.servicechain.state.rev170511.elan.to.pseudo.port.data.list.ElanToPseudoPortData;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.ElanInstances;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.instances.ElanInstance;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.instances.ElanInstanceKey;

import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * It is in charge of executing the changes in the Pipeline that are related to
 * Elan Pseudo Ports when participating in ServiceChains.
 *
 */
public class ElanServiceChainHandler {

    private static final Logger LOG = LoggerFactory.getLogger(ElanServiceChainHandler.class);

    private final DataBroker broker;
    private final IMdsalApiManager mdsalManager;


    public ElanServiceChainHandler(final DataBroker db, final IMdsalApiManager mdsalMgr) {
        this.broker = db;
        this.mdsalManager = mdsalMgr;
    }

    /**
     * Programs the needed flows for sending traffic to the SCF pipeline when
     * it is comming from an L2-GW (ELAN) and also for handing over that
     * traffic from SCF to ELAN when the packets does not match any Service
     * Chain.
     *
     * @param elanName Name of the ELAN to be considered
     * @param tableId Table id, in the SCF Pipeline, to which the traffic must
     *        go to.
     * @param scfTag Tag of the ServiceChain
     * @param elanLportTag LPortTag of the ElanPseudoPort that participates in
     *        the ServiceChain
     * @param addOrRemove States if the flows must be created or removed
     */
    public void programElanScfPipeline(String elanName, short tableId, long scfTag, int elanLportTag, int addOrRemove) {
        LOG.info("programElanScfPipeline:  elanName={}   scfTag={}   elanLportTag={}    addOrRemove={}",
                 elanName, scfTag, elanLportTag, addOrRemove);
        // There are 3 rules to be considered:
        //  1. LportDispatcher To Scf. Matches on elanPseudoPort + SI=1. Goes to DL Subscriber table
        //  2. LportDispatcher From Scf. Matches on elanPseudoPort + SI=3. Goes to ELAN DMAC
        //  3. ExtTunnelTable From L2GwDevice. Matches on VNI + SI=1. Sets ElanPseudoPort tag and goes
        //             to LportDispatcher table.
        // And these rules must be programmed in all the Elan footprint

        // Find the ElanInstance
        Optional<ElanInstance> elanInstance = ElanServiceChainUtils.getElanInstanceByName(broker, elanName);
        if ( !elanInstance.isPresent() ) {
            LOG.debug("Could not find an Elan Instance with name={}", elanName);
            return;
        }

        Optional<Collection<BigInteger>> elanDpnsOpc = ElanServiceChainUtils.getElanDpnsByName(broker, elanName);
        if ( !elanDpnsOpc.isPresent() ) {
            LOG.debug("Could not find any DPN related to Elan {}", elanName);
            return;
        }

        // updates map which stores relationship between elan and elanLPortTag and scfTag
        ElanServiceChainUtils.updateElanToLportTagMap(broker, elanName, elanLportTag, scfTag, addOrRemove);

        Long vni = elanInstance.get().getSegmentationId();
        if ( vni == null ) {
            LOG.warn("There is no VNI for elan {}. VNI is mandatory. Returning", elanName);
            return;
        }

        int elanTag = elanInstance.get().getElanTag().intValue();
        LOG.debug("elanName={}  ->  vni={}  elanTag={}", elanName, vni, elanTag);
        // For each DPN in the Elan, do
        //    Program LPortDispatcher to Scf
        //    Program LPortDispatcher from Scf
        //    Program ExtTunnelTable.
        for (BigInteger dpnId : elanDpnsOpc.get()) {
            ElanServiceChainUtils.programLPortDispatcherToScf(mdsalManager, dpnId, elanTag, elanLportTag, tableId,
                                                              scfTag, addOrRemove);
            ElanServiceChainUtils.programLPortDispatcherFromScf(mdsalManager, dpnId, elanLportTag, elanTag,
                                                                addOrRemove);
            ElanServiceChainUtils.programExternalTunnelTable(mdsalManager, dpnId, elanLportTag, vni, elanTag,
                                                             addOrRemove);
        }

    }

    public void removeElanPseudoPortFlows(String elanName, int elanLportTag) {
        Optional<ElanServiceChainState> elanServiceChainState =
            ElanServiceChainUtils.getElanServiceChainState(broker, elanName);
        if (!elanServiceChainState.isPresent()) {
            LOG.warn("Could not find ServiceChain state data for Elan {}, elanPseudoLportTag={}",
                     elanName, elanLportTag);
            return;
        }
        Optional<ElanInstance> elanInstance = ElanServiceChainUtils.getElanInstanceByName(broker, elanName);
        if ( !elanInstance.isPresent() ) {
            LOG.warn("Could not find ElanInstance for name {}", elanName);
            return;
        }

        Long vni = elanInstance.get().getSegmentationId();
        if (vni == null) {
            LOG.warn("Elan {} is not related to a VNI. VNI is mandatory for ServiceChaining. Returning", elanName);
            return;
        }

        List<ElanToPseudoPortData> elanToPseudoPortDataList = elanServiceChainState.get().getElanToPseudoPortData();
        if ( elanToPseudoPortDataList == null || elanToPseudoPortDataList.isEmpty() ) {
            LOG.info("Could not find elan {} with elanPseudoPort {} participating in any ServiceChain",
                     elanName, elanLportTag);
            return;
        }

        if ( elanInstance.get().getElanTag() == null ) {
            LOG.info("Could not find elanTag for elan {} ", elanName);
            return;
        }

        int elanTag = elanInstance.get().getElanTag().intValue();

        List<BigInteger> operativeDPNs = NWUtil.getOperativeDPNs(broker);
        for (ElanToPseudoPortData elanToPseudoPortData : elanToPseudoPortDataList) {
            Long scfTag = elanToPseudoPortData.getScfTag();

            for (BigInteger dpnId : operativeDPNs) {
                ElanServiceChainUtils.programLPortDispatcherToScf(mdsalManager, dpnId, elanTag, elanLportTag,
                        CloudServiceChainConstants.SCF_DOWN_SUB_FILTER_TCP_BASED_TABLE,
                        scfTag, NwConstants.DEL_FLOW);
                ElanServiceChainUtils.programLPortDispatcherFromScf(mdsalManager, dpnId, elanLportTag, elanTag,
                                                                    NwConstants.DEL_FLOW);
                ElanServiceChainUtils.programExternalTunnelTable(mdsalManager, dpnId, elanLportTag, vni, elanTag,
                                                                 NwConstants.DEL_FLOW);
            }
        }

        // Lastly, remove the serviceChain-state for the Elan
        InstanceIdentifier<ElanServiceChainState> path =
            InstanceIdentifier.builder(ElanInstances.class).child(ElanInstance.class, new ElanInstanceKey(elanName))
                              .augmentation(ElanServiceChainState.class)
                              .build();

        MDSALUtil.syncDelete(broker, LogicalDatastoreType.OPERATIONAL, path);
    }

}
