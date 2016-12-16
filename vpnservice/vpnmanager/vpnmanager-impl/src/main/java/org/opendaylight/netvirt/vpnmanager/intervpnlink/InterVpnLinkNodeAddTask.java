/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others. All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.vpnmanager.intervpnlink;

import com.google.common.base.Optional;
import com.google.common.util.concurrent.CheckedFuture;
import com.google.common.util.concurrent.ListenableFuture;
import java.math.BigInteger;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.concurrent.Callable;

import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.WriteTransaction;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.controller.md.sal.common.api.data.TransactionCommitFailedException;
import org.opendaylight.genius.mdsalutil.interfaces.IMdsalApiManager;
import org.opendaylight.netvirt.vpnmanager.VpnFootprintService;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.netvirt.inter.vpn.link.rev160311.inter.vpn.link.states.InterVpnLinkState;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.netvirt.inter.vpn.link.rev160311.inter.vpn.link.states.InterVpnLinkStateBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.netvirt.inter.vpn.link.rev160311.inter.vpn.link.states.inter.vpn.link.state.FirstEndpointState;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.netvirt.inter.vpn.link.rev160311.inter.vpn.link.states.inter.vpn.link.state.FirstEndpointStateBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.netvirt.inter.vpn.link.rev160311.inter.vpn.link.states.inter.vpn.link.state.SecondEndpointState;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.netvirt.inter.vpn.link.rev160311.inter.vpn.link.states.inter.vpn.link.state.SecondEndpointStateBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.netvirt.inter.vpn.link.rev160311.inter.vpn.links.InterVpnLink;


/**
 * A task that, when a Node comes UP, checks if there are any InterVpnLink that
 * hasn't been instantiated in any DPN yet. This may happen if, for example,
 * there are no DPNs connected to controller by the time the InterVpnLink is
 * created.
 *
 */
public class InterVpnLinkNodeAddTask implements Callable<List<ListenableFuture<Void>>> {
    private static final String NBR_OF_DPNS_PROPERTY_NAME = "vpnservice.intervpnlink.number.dpns";

    private final DataBroker broker;
    private final BigInteger dpnId;
    private final IMdsalApiManager mdsalManager;
    private final VpnFootprintService vpnFootprintService;

    public InterVpnLinkNodeAddTask(final DataBroker broker, final IMdsalApiManager mdsalMgr,
                                   final VpnFootprintService vpnFootprintService, final BigInteger dpnId) {
        this.broker = broker;
        this.mdsalManager = mdsalMgr;
        this.vpnFootprintService = vpnFootprintService;
        this.dpnId = dpnId;
    }

    @Override
    public List<ListenableFuture<Void>> call() throws Exception {
        List<ListenableFuture<Void>> result = new ArrayList<>();
        // check if there is any inter-vpn-link in with erroneous state
        List<InterVpnLinkState> allInterVpnLinkState = InterVpnLinkUtil.getAllInterVpnLinkState(broker);
        int numberOfDpns = Integer.getInteger(NBR_OF_DPNS_PROPERTY_NAME, 1);

        List<BigInteger> firstDpnList = Collections.singletonList(this.dpnId);
        List<BigInteger> secondDpnList = firstDpnList;
        for (InterVpnLinkState interVpnLinkState : allInterVpnLinkState) {
            if ( interVpnLinkState.getState() != InterVpnLinkState.State.Error ) {
                continue;
            }

            // if the inter-vpn-link is erroneous and any of its endPoints has no dpns associated
            if (shouldConfigureLinkIntoDpn(interVpnLinkState, numberOfDpns)) {
                installLPortDispatcherTable(interVpnLinkState, firstDpnList, secondDpnList);
                CheckedFuture<Void, TransactionCommitFailedException> futures =
                        updateInterVpnLinkState(interVpnLinkState, firstDpnList, secondDpnList, numberOfDpns);
                result.add(futures);
            }
        }
        return result;
    }

    private boolean shouldConfigureLinkIntoDpn(InterVpnLinkState interVpnLinkState, int numberOfDpns) {

        if ((interVpnLinkState.getFirstEndpointState().getDpId() == null
           || interVpnLinkState.getFirstEndpointState().getDpId().isEmpty())
           || (interVpnLinkState.getSecondEndpointState().getDpId() == null
           || interVpnLinkState.getSecondEndpointState().getDpId().isEmpty())) {
            return true;
        } else if (!interVpnLinkState.getFirstEndpointState().getDpId().contains(dpnId)
                && !interVpnLinkState.getSecondEndpointState().getDpId().contains(dpnId)
                && (interVpnLinkState.getFirstEndpointState().getDpId().size() < numberOfDpns)) {
            return true;
        } else {
            return false;
        }
    }

    private CheckedFuture<Void, TransactionCommitFailedException>
                updateInterVpnLinkState(InterVpnLinkState interVpnLinkState, List<BigInteger> firstDpnList,
                                        List<BigInteger> secondDpnList, int numberOfDpns) {
        FirstEndpointState firstEndPointState =
                new FirstEndpointStateBuilder(interVpnLinkState.getFirstEndpointState())
                                                               .setDpId(firstDpnList).build();
        SecondEndpointState secondEndPointState =
                new SecondEndpointStateBuilder(interVpnLinkState.getSecondEndpointState())
                                                                .setDpId(secondDpnList).build();
        InterVpnLinkState newInterVpnLinkState = new InterVpnLinkStateBuilder(interVpnLinkState)
                                                                .setState(InterVpnLinkState.State.Active)
                                                                .setFirstEndpointState(firstEndPointState)
                                                                .setSecondEndpointState(secondEndPointState)
                                                                .build();
        WriteTransaction tx = broker.newWriteOnlyTransaction();
        tx.merge(LogicalDatastoreType.CONFIGURATION,
                 InterVpnLinkUtil.getInterVpnLinkStateIid(interVpnLinkState.getInterVpnLinkName()), newInterVpnLinkState, true);
        return tx.submit();
    }

    private void installLPortDispatcherTable(InterVpnLinkState interVpnLinkState, List<BigInteger> firstDpnList,
                                             List<BigInteger> secondDpnList) {
        Optional<InterVpnLink> vpnLink =
            InterVpnLinkUtil.getInterVpnLinkByName(broker, interVpnLinkState.getKey().getInterVpnLinkName());
        if (vpnLink.isPresent()) {
            Uuid firstEndpointVpnUuid = vpnLink.get().getFirstEndpoint().getVpnUuid();
            Uuid secondEndpointVpnUuid = vpnLink.get().getSecondEndpoint().getVpnUuid();
            // Note that in the DPN of the firstEndpoint we install the lportTag of the secondEndpoint and viceversa
            InterVpnLinkUtil.installLPortDispatcherTableFlow(broker, mdsalManager, vpnLink.get(), firstDpnList,
                                                    secondEndpointVpnUuid,
                                                    interVpnLinkState.getSecondEndpointState().getLportTag());
            InterVpnLinkUtil.installLPortDispatcherTableFlow(broker, mdsalManager, vpnLink.get(), secondDpnList,
                                                    firstEndpointVpnUuid,
                                                    interVpnLinkState.getFirstEndpointState().getLportTag());
            // Update the VPN -> DPNs Map.
            // Note: when a set of DPNs is calculated for Vpn1, these DPNs are added to the VpnToDpn map of Vpn2. Why?
            // because we do the handover from Vpn1 to Vpn2 in those DPNs, so in those DPNs we must know how to reach
            // to Vpn2 targets. If new Vpn2 targets are added later, the Fib will be maintained in these DPNs even if
            // Vpn2 is not physically present there.
            InterVpnLinkUtil.updateVpnFootprint(vpnFootprintService, secondEndpointVpnUuid.getValue(), firstDpnList);
            InterVpnLinkUtil.updateVpnFootprint(vpnFootprintService, firstEndpointVpnUuid.getValue(), secondDpnList);
        }
    }

}
