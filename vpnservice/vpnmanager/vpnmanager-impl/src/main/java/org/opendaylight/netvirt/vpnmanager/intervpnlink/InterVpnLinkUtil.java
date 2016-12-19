/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others. All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.vpnmanager.intervpnlink;

import com.google.common.base.Optional;
import com.google.common.base.Preconditions;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.mdsalutil.MDSALUtil;
import org.opendaylight.genius.mdsalutil.MatchFieldType;
import org.opendaylight.genius.mdsalutil.MatchInfo;
import org.opendaylight.genius.mdsalutil.MetaDataUtil;
import org.opendaylight.genius.mdsalutil.NwConstants;
import org.opendaylight.genius.mdsalutil.interfaces.IMdsalApiManager;
import org.opendaylight.genius.utils.ServiceIndex;
import org.opendaylight.netvirt.bgpmanager.api.IBgpManager;
import org.opendaylight.netvirt.fibmanager.api.IFibManager;
import org.opendaylight.netvirt.fibmanager.api.RouteOrigin;
import org.opendaylight.netvirt.vpnmanager.VpnConstants;
import org.opendaylight.netvirt.vpnmanager.VpnFootprintService;
import org.opendaylight.netvirt.vpnmanager.VpnUtil;
import org.opendaylight.netvirt.vpnmanager.api.intervpnlink.InterVpnLinkCache;
import org.opendaylight.netvirt.vpnmanager.api.intervpnlink.InterVpnLinkDataComposite;
import org.opendaylight.netvirt.vpnmanager.utilities.InterfaceUtils;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.inventory.rev130819.tables.table.Flow;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.types.rev131026.instruction.list.Instruction;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.FibEntries;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.fibentries.VrfTables;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.fibentries.VrfTablesKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.vrfentries.VrfEntry;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.vrfentries.VrfEntryBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.vrfentries.VrfEntryKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.netvirt.inter.vpn.link.rev160311.InterVpnLinkStates;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.netvirt.inter.vpn.link.rev160311.InterVpnLinks;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.netvirt.inter.vpn.link.rev160311.inter.vpn.link.states.InterVpnLinkState;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.netvirt.inter.vpn.link.rev160311.inter.vpn.link.states.InterVpnLinkStateBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.netvirt.inter.vpn.link.rev160311.inter.vpn.link.states.InterVpnLinkStateKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.netvirt.inter.vpn.link.rev160311.inter.vpn.link.states.inter.vpn.link.state.FirstEndpointState;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.netvirt.inter.vpn.link.rev160311.inter.vpn.link.states.inter.vpn.link.state.SecondEndpointState;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.netvirt.inter.vpn.link.rev160311.inter.vpn.links.InterVpnLink;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.netvirt.inter.vpn.link.rev160311.inter.vpn.links.InterVpnLinkKey;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.google.common.util.concurrent.ListenableFuture;
import java.math.BigInteger;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;


/**
 * This class contains methods to be used as utilities related with inter-vpn-link.
 *
 */
public class InterVpnLinkUtil {

    private static final Logger LOG = LoggerFactory.getLogger(InterVpnLinkUtil.class);

    /**
     * Retrieves the Instance Identifier that points to an InterVpnLink object
     * in MDSL
     *
     * @param iVpnLinkName The name of the InterVpnLink
     * @return The requested InstanceIdentifier
     */
    public static InstanceIdentifier<InterVpnLink> getInterVpnLinkPath(String iVpnLinkName) {
        return InstanceIdentifier.builder(InterVpnLinks.class)
                .child(InterVpnLink.class, new InterVpnLinkKey(iVpnLinkName))
                .build();
    }

    /**
     * Retrieves the Instance Identifier that points to an InterVpnLinkState object
     * in MDSL
     *
     * @param vpnLinkName The name of the InterVpnLink
     * @return The requested InstanceIdentifier
     */
    public static InstanceIdentifier<InterVpnLinkState> getInterVpnLinkStateIid(String vpnLinkName) {
        return InstanceIdentifier.builder(InterVpnLinkStates.class)
                .child(InterVpnLinkState.class, new InterVpnLinkStateKey(vpnLinkName))
                .build();
    }

    public static String buildInterVpnLinkIfaceName(String vpnName, BigInteger dpnId) {
        return String.format("InterVpnLink.%s.%s", vpnName, dpnId.toString());
    }

    /**
     * Updates VpnToDpn map by adding a fake VpnInterface related to an
     * InterVpnLink in the corresponding DPNs. If the fake iface is the
     * first one on the any of the specified DPNs, the installation of
     * Fib flows on that DPN will be triggered
     *
     * @param vpnFootprintService VpnFootprintService service reference
     * @param vpnName Name of the VPN to which the fake interfaces belong
     * @param dpnList List of DPNs where the fake InterVpnLink interface must
     *     be added
     */
    public static void updateVpnFootprint(VpnFootprintService vpnFootprintService, String vpnName,
                                          List<BigInteger> dpnList) {
        LOG.debug("updateVpnFootprint (add):  vpn={}  dpnList={}", vpnName, dpnList);
        // Note: when a set of DPNs is calculated for Vpn1, these DPNs are added to the VpnToDpn map of Vpn2. Why?
        // because we do the handover from Vpn1 to Vpn2 in those DPNs, so in those DPNs we must know how to reach
        // to Vpn2 targets. If new Vpn2 targets are added later, the Fib will be maintained in these DPNs even if
        // Vpn2 is not physically present there.
        for ( BigInteger dpnId : dpnList ) {
            String ifaceName = buildInterVpnLinkIfaceName(vpnName, dpnId);
            vpnFootprintService.updateVpnToDpnMapping(dpnId, vpnName, ifaceName, true /* addition */);
        }
    }

    /**
     * Updates VpnToDpn map by removing the fake VpnInterface related to an
     * InterVpnLink in the corresponding DPNs.
     *
     * @param vpnFootprintService VpnFootprintService service reference
     * @param vpnName Name of the VPN to which the fake interfaces belong
     * @param dpnId DPN where the fake InterVpnLink interface must be removed from
     */
    public static void removeIVpnLinkIfaceFromVpnFootprint(VpnFootprintService vpnFootprintService,
                                                           String vpnName, BigInteger dpnId) {
        String ifaceName = buildInterVpnLinkIfaceName(vpnName, dpnId);
        LOG.debug("updateVpnFootprint (remove):  vpn={}  dpn={}  ifaceName={}", vpnName, dpnId, ifaceName);
        vpnFootprintService.updateVpnToDpnMapping(dpnId, vpnName, ifaceName, false /* removal */);
    }

    /**
     * Retrieves the InterVpnLink object searching by its name
     *
     * @param broker dataBroker service reference
     * @param vpnLinkName Name of the InterVpnLink
     * @return the InterVpnLink or Optional.absent() if there is no
     *     InterVpnLink with the specified name
     */
    public static Optional<InterVpnLink> getInterVpnLinkByName(DataBroker broker, String vpnLinkName) {
        InstanceIdentifier<InterVpnLink> interVpnLinksIid =
                InstanceIdentifier.builder(InterVpnLinks.class)
                        .child(InterVpnLink.class, new InterVpnLinkKey(vpnLinkName)).build();
        return  VpnUtil.read(broker, LogicalDatastoreType.CONFIGURATION, interVpnLinksIid);
    }

    /**
     * Updates inter-VPN link state
     *
     * @param broker dataBroker service reference
     * @param vpnLinkName The name of the InterVpnLink
     * @param state Sets the state of the InterVpnLink to Active or Error
     * @param newFirstEndpointState Updates the lportTag and/or DPNs of the 1st
     *     endpoint of the InterVpnLink
     * @param newSecondEndpointState Updates the lportTag and/or DPNs of the
     *     2nd endpoint of the InterVpnLink
     */
    public static void updateInterVpnLinkState(DataBroker broker, String vpnLinkName, InterVpnLinkState.State state,
                                               FirstEndpointState newFirstEndpointState,
                                               SecondEndpointState newSecondEndpointState) {
        Optional<InterVpnLinkState> optOldVpnLinkState = getInterVpnLinkState(broker, vpnLinkName);
        if ( optOldVpnLinkState.isPresent() ) {
            InterVpnLinkState newVpnLinkState =
                    new InterVpnLinkStateBuilder(optOldVpnLinkState.get()).setState(state)
                            .setFirstEndpointState(newFirstEndpointState)
                            .setSecondEndpointState(newSecondEndpointState)
                            .build();
            VpnUtil.syncUpdate(broker, LogicalDatastoreType.CONFIGURATION,
                    InterVpnLinkUtil.getInterVpnLinkStateIid(vpnLinkName), newVpnLinkState);
            InterVpnLinkCache.addInterVpnLinkStateToCaches(newVpnLinkState);
        } else {
            InterVpnLinkState newIVpnLinkState =
                    new InterVpnLinkStateBuilder().setKey(new InterVpnLinkStateKey(vpnLinkName))
                            .setInterVpnLinkName(vpnLinkName)
                            .setFirstEndpointState(newFirstEndpointState)
                            .setSecondEndpointState(newSecondEndpointState)
                            .setState(InterVpnLinkState.State.Active)
                            .build();
            VpnUtil.syncWrite(broker, LogicalDatastoreType.CONFIGURATION,
                    InterVpnLinkUtil.getInterVpnLinkStateIid(vpnLinkName), newIVpnLinkState);
            InterVpnLinkCache.addInterVpnLinkStateToCaches(newIVpnLinkState);
        }
    }

    /**
     * Installs a Flow in LPortDispatcher table that matches on SI=2 and
     * the lportTag of one InterVpnLink's endpoint and sets the vrfTag of the
     * other endpoint and sends to FIB table
     *
     * @param broker dataBroker service reference
     * @param mdsalManager MDSAL API accessor
     * @param interVpnLink Object that holds the needed information about both
     *     endpoints of the InterVpnLink.
     * @param dpnList The list of DPNs where this flow must be installed
     * @param vpnUuidOtherEndpoint UUID of the other endpoint of the
     *     InterVpnLink
     * @param lPortTagOfOtherEndpoint Dataplane identifier of the other
     *     endpoint of the InterVpnLink
     * @return the list of Futures for each and every flow that has been
     *     installed
     */
    public static List<ListenableFuture<Void>> installLPortDispatcherTableFlow(DataBroker broker,
                                                                               IMdsalApiManager mdsalManager,
                                                                               InterVpnLink interVpnLink,
                                                                               List<BigInteger> dpnList,
                                                                               Uuid vpnUuidOtherEndpoint,
                                                                               Long lPortTagOfOtherEndpoint) {
        List<ListenableFuture<Void>> result = new ArrayList<>();
        long vpnId = VpnUtil.getVpnId(broker, vpnUuidOtherEndpoint.getValue());
        for ( BigInteger dpnId : dpnList ) {
            // insert into LPortDispatcher table
            Flow lPortDispatcherFlow = buildLPortDispatcherFlow(interVpnLink.getName(), vpnId,
                                                                lPortTagOfOtherEndpoint.intValue());
            result.add(mdsalManager.installFlow(dpnId, lPortDispatcherFlow));
        }

        return result;
    }

    /**
     * Builds a Flow to be installed into LPortDispatcher table, that matches on
     * SI=2 + vpnLinkEndpointPseudoPortTag and sends to FIB
     *
     * @param interVpnLinkName The name of the InterVpnLink
     * @param vpnId Dataplane identifier of the VPN, the Vrf Tag.
     * @param lportTag DataPlane identifier of the LogicalPort.
     * @return the Flow ready to be installed
     */
    public static Flow buildLPortDispatcherFlow(String interVpnLinkName, long vpnId, int lportTag) {
        LOG.info("Inter-vpn-link : buildLPortDispatcherFlow. vpnId {}   lportTag {} ", vpnId, lportTag);
        List<MatchInfo> matches = Arrays.asList(new MatchInfo(MatchFieldType.metadata,
                new BigInteger[] {
                        MetaDataUtil.getMetaDataForLPortDispatcher(lportTag,
                                ServiceIndex.getIndex(NwConstants.L3VPN_SERVICE_NAME, NwConstants.L3VPN_SERVICE_INDEX)),
                        MetaDataUtil.getMetaDataMaskForLPortDispatcher() }));
        String flowRef = getLportDispatcherFlowRef(interVpnLinkName, lportTag);
        Flow lPortDispatcherFlow = MDSALUtil.buildFlowNew(NwConstants.LPORT_DISPATCHER_TABLE, flowRef,
                VpnConstants.DEFAULT_LPORT_DISPATCHER_FLOW_PRIORITY, flowRef,
                0, 0, VpnUtil.getCookieL3((int) vpnId), matches,
                buildLportDispatcherTableInstructions(vpnId));
        return lPortDispatcherFlow;
    }

    /**
     * Builds a flowRef to be assigned to the flow to be installed into
     * LPortDispatcher table
     *
     * @param interVpnLinkName The name of the InterVpnLink
     * @param lportTag Dataplane identifier of the LogicalPort
     * @return the flow reference string
     */
    public static String getLportDispatcherFlowRef(String interVpnLinkName, Integer lportTag) {
        return new StringBuffer()
                .append(VpnConstants.FLOWID_PREFIX).append("INTERVPNLINK")
                .append(NwConstants.FLOWID_SEPARATOR).append(interVpnLinkName)
                .append(NwConstants.FLOWID_SEPARATOR).append(lportTag)
                .append(NwConstants.FLOWID_SEPARATOR).append(ServiceIndex.getIndex(NwConstants.L3VPN_SERVICE_NAME,
                                                                                   NwConstants.L3VPN_SERVICE_INDEX))
                .append(NwConstants.FLOWID_SEPARATOR)
                .append(VpnConstants.DEFAULT_LPORT_DISPATCHER_FLOW_PRIORITY)
                .toString();
    }


    public static List<Instruction> buildLportDispatcherTableInstructions (long vpnId) {
        int instructionKey = 0;
        List<Instruction> instructions = new ArrayList<Instruction>();
        instructions.add(MDSALUtil.buildAndGetWriteMetadaInstruction(MetaDataUtil.getVpnIdMetadata(vpnId),
                MetaDataUtil.METADATA_MASK_VRFID,
                ++instructionKey));
        instructions.add(MDSALUtil.buildAndGetGotoTableInstruction(NwConstants.L3_FIB_TABLE, ++instructionKey));

        return instructions;
    }

    /**
     * Retrieves the States of all InterVpnLinks
     *
     * @param broker dataBroker service reference
     * @return the list of objects that holds the InterVpnLink state information
     */
    public static List<InterVpnLinkState> getAllInterVpnLinkState(DataBroker broker) {
        InstanceIdentifier<InterVpnLinkStates> interVpnLinkStateIid =
                InstanceIdentifier.builder(InterVpnLinkStates.class).build();

        Optional<InterVpnLinkStates> interVpnLinkStateOpData =
                MDSALUtil.read(broker, LogicalDatastoreType.CONFIGURATION, interVpnLinkStateIid);

        return (interVpnLinkStateOpData.isPresent()) ? interVpnLinkStateOpData.get().getInterVpnLinkState()
                : new ArrayList<InterVpnLinkState>();
    }

    /**
     * Retrieves the State of an InterVpnLink
     *
     * @param broker dataBroker service reference
     * @param iVpnLinkName The name of the InterVpnLink
     * @return the object that contains the State of the specified InterVpnLink
     *         or Optional.absent() if it doesnt exist
     */
    public static Optional<InterVpnLinkState> getInterVpnLinkState(DataBroker broker, String iVpnLinkName) {
        return MDSALUtil.read(broker, LogicalDatastoreType.CONFIGURATION, getInterVpnLinkStateIid(iVpnLinkName));
    }

    /**
     * Checks if the specified InterVpnLink is currently Active
     *
     * @param broker dataBroker service reference
     * @param iVpnLinkName The name of the InterVpnLink
     * @return true if the InterVpnLink is Active
     */
    public static boolean isInterVpnLinkActive(DataBroker broker, String iVpnLinkName) {
        Optional<InterVpnLinkState> optIVpnLinkState = getInterVpnLinkState(broker, iVpnLinkName);
        if ( ! optIVpnLinkState.isPresent() ) {
            return false;
        }
        InterVpnLinkState iVpnLinkState = optIVpnLinkState.get();
        return iVpnLinkState.getState() == InterVpnLinkState.State.Active;
    }

    /**
     * Retrieves an InterVpnLink by searching by one of its endpoint's IP.
     *
     * @param broker dataBroker service reference
     * @param endpointIp IP to serch for.
     * @return the InterVpnLink or null if no InterVpnLink can be found
     */
    public static Optional<InterVpnLink> getInterVpnLinkByEndpointIp(DataBroker broker, String endpointIp) {
        List<InterVpnLink> allInterVpnLinks = InterVpnLinkUtil.getAllInterVpnLinks(broker);
        for (InterVpnLink interVpnLink : allInterVpnLinks) {
            if (interVpnLink.getFirstEndpoint().getIpAddress().getValue().equals(endpointIp)
                    || interVpnLink.getSecondEndpoint().getIpAddress().getValue().equals(endpointIp)) {
                return Optional.of(interVpnLink);
            }
        }
        return Optional.absent();
    }


    /**
     * Retrieves the InterVpnLink that has one of its 2 endpoints installed in
     * the specified DpnId
     *
     * @param broker dataBroker service reference
     * @param dpnId Id of the DPN
     * @return The InterVpnLink object if found, Optional.absent() otherwise
     */
    public static Optional<InterVpnLink> getInterVpnLinkByDpnId(DataBroker broker, BigInteger dpnId) {
        List<InterVpnLink> allInterVpnLinks = InterVpnLinkUtil.getAllInterVpnLinks(broker);
        for (InterVpnLink interVpnLink : allInterVpnLinks) {
            Optional<InterVpnLinkState> optInterVpnLinkState = getInterVpnLinkState(broker, interVpnLink.getName());
            if ( optInterVpnLinkState.isPresent()
                    && ( optInterVpnLinkState.get().getFirstEndpointState().getDpId().contains(dpnId)
                    || optInterVpnLinkState.get().getSecondEndpointState().getDpId().contains(dpnId) ) ) {
                return Optional.fromNullable(interVpnLink);
            }
        }
        return Optional.absent();
    }

    /**
     * Retrieves all configured InterVpnLinks
     *
     * @param broker dataBroker service reference
     * @return the list of InterVpnLinks
     */
    public static List<InterVpnLink> getAllInterVpnLinks(DataBroker broker) {
        InstanceIdentifier<InterVpnLinks> interVpnLinksIid = InstanceIdentifier.builder(InterVpnLinks.class).build();

        Optional<InterVpnLinks> interVpnLinksOpData =
                MDSALUtil.read(broker, LogicalDatastoreType.CONFIGURATION, interVpnLinksIid);

        return interVpnLinksOpData.isPresent() ? interVpnLinksOpData.get().getInterVpnLink()
                : new ArrayList<>();
    }

    /**
     * Retrieves the list of DPNs where the endpoint of a VPN in an InterVPNLink was instantiated
     *
     * @param broker dataBroker service reference
     * @param vpnLinkName the name of the InterVpnLink
     * @param vpnUuid UUID of the VPN whose endpoint to be checked
     * @return the list of DPN Ids
     */
    public static List<BigInteger> getVpnLinkEndpointDPNs(DataBroker broker, String vpnLinkName, String vpnUuid) {
        Optional<InterVpnLinkState> interVpnLinkState = getInterVpnLinkState(broker, vpnLinkName);
        if ( interVpnLinkState.isPresent()) {
            if (interVpnLinkState.get().getFirstEndpointState().getVpnUuid().getValue().equals(vpnUuid)) {
                return interVpnLinkState.get().getFirstEndpointState().getDpId();
            } else {
                return interVpnLinkState.get().getSecondEndpointState().getDpId();
            }
        } else {
            LOG.trace("Could not find InterVpnLinkState for interVpnLink {}", vpnLinkName);
            return new ArrayList<BigInteger>();
        }
    }

    /**
     * Retrieves the list of DPNs where the endpoint of a VPN in an InterVPNLink was instantiated
     *
     * @param broker dataBroker service reference
     * @param endpointIp Ip of the endpoint specified in the InterVpnLink
     * @return the list of DPN Ids
     */
    public static List<BigInteger> getVpnLinkEndpointDPNsByIp(DataBroker broker, String endpointIp) {
        Optional<InterVpnLink> optIVpnLink = getInterVpnLinkByEndpointIp(broker, endpointIp);
        if ( optIVpnLink.isPresent() ) {
            InterVpnLink iVpnLink = optIVpnLink.get();
            boolean isFirstEndpoint = iVpnLink.getFirstEndpoint().getIpAddress().getValue().equals(endpointIp);
            return isFirstEndpoint ? getVpnLinkEndpointDPNs(broker, iVpnLink.getName(),
                    iVpnLink.getFirstEndpoint().getVpnUuid().getValue())
                    : getVpnLinkEndpointDPNs(broker, iVpnLink.getName(),
                    iVpnLink.getSecondEndpoint().getVpnUuid().getValue());
        } else {
            LOG.trace("Could not find an InterVpnLink with endpoint IpAddr={}", endpointIp);
            return new ArrayList<BigInteger>();
        }
    }


    /**
     * Leaks a route from one VPN to another. By default, the origin for this leaked route is INTERVPN
     *
     * @param broker           dataBroker service reference
     * @param bgpManager       Used to advertise routes to the BGP Router
     * @param interVpnLink     Reference to the object that holds the info about the link between the 2 VPNs
     * @param srcVpnUuid       UUID of the VPN that has the route that is going to be leaked to the other VPN
     * @param dstVpnUuid       UUID of the VPN that is going to receive the route
     * @param prefix           Prefix of the route
     * @param label            Label of the route in the original VPN
     */
    public static void leakRoute(DataBroker broker, IBgpManager bgpManager, InterVpnLink interVpnLink,
                                 String srcVpnUuid, String dstVpnUuid, String prefix, Long label) {
        leakRoute(broker, bgpManager, interVpnLink, srcVpnUuid, dstVpnUuid, prefix, label, RouteOrigin.INTERVPN);
    }

    /**
     * Leaks a route from one VPN to another.
     *
     * @param broker           dataBroker service reference
     * @param bgpManager       Used to advertise routes to the BGP Router
     * @param interVpnLink     Reference to the object that holds the info about the link between the 2 VPNs
     * @param srcVpnUuid       UUID of the VPN that has the route that is going to be leaked to the other VPN
     * @param dstVpnUuid       UUID of the VPN that is going to receive the route
     * @param prefix           Prefix of the route
     * @param label            Label of the route in the original VPN
     * @param forcedOrigin     By default, origin for leaked routes should be INTERVPN, however it is possible to
     *                         provide a different origin if desired.
     */
    public static void leakRoute(DataBroker broker, IBgpManager bgpManager, InterVpnLink interVpnLink,
                                 String srcVpnUuid, String dstVpnUuid, String prefix, Long label,
                                 RouteOrigin forcedOrigin) {
        Preconditions.checkNotNull(interVpnLink);

        // The source VPN must participate in the InterVpnLink
        Preconditions.checkArgument(interVpnLink.getFirstEndpoint().getVpnUuid().getValue().equals(srcVpnUuid)
                        || interVpnLink.getSecondEndpoint().getVpnUuid().getValue().equals(srcVpnUuid),
                "The source VPN {} does not participate in the interVpnLink {}",
                srcVpnUuid, interVpnLink.getName());
        // The destination VPN must participate in the InterVpnLink
        Preconditions.checkArgument(interVpnLink.getFirstEndpoint().getVpnUuid().getValue().equals(dstVpnUuid)
                        || interVpnLink.getSecondEndpoint().getVpnUuid().getValue().equals(dstVpnUuid),
                "The destination VPN {} does not participate in the interVpnLink {}",
                dstVpnUuid, interVpnLink.getName());

        boolean destinationIs1stEndpoint = interVpnLink.getFirstEndpoint().getVpnUuid().getValue().equals(dstVpnUuid);

        String endpointIp = destinationIs1stEndpoint ? interVpnLink.getSecondEndpoint().getIpAddress().getValue()
                : interVpnLink.getFirstEndpoint().getIpAddress().getValue();

        VrfEntry newVrfEntry = new VrfEntryBuilder().setKey(new VrfEntryKey(prefix)).setDestPrefix(prefix)
                .setLabel(label).setNextHopAddressList(Arrays.asList(endpointIp))
                .setOrigin(RouteOrigin.INTERVPN.getValue())
                .build();

        String dstVpnRd = VpnUtil.getVpnRd(broker, dstVpnUuid);
        InstanceIdentifier<VrfEntry> newVrfEntryIid =
                InstanceIdentifier.builder(FibEntries.class)
                        .child(VrfTables.class, new VrfTablesKey(dstVpnRd))
                        .child(VrfEntry.class, new VrfEntryKey(newVrfEntry.getDestPrefix()))
                        .build();
        VpnUtil.asyncWrite(broker, LogicalDatastoreType.CONFIGURATION, newVrfEntryIid, newVrfEntry);

        // Finally, route is advertised it to the DC-GW. But while in the FibEntries the nexthop is the other
        // endpoint's IP, in the DC-GW the nexthop for those prefixes are the IPs of those DPNs where the target
        // VPN has been instantiated
        Optional<InterVpnLinkState> optVpnLinkState = getInterVpnLinkState(broker, interVpnLink.getName());
        if ( optVpnLinkState.isPresent() ) {
            InterVpnLinkState vpnLinkState = optVpnLinkState.get();
            List<BigInteger> dpnIdList = destinationIs1stEndpoint ? vpnLinkState.getFirstEndpointState().getDpId()
                    : vpnLinkState.getSecondEndpointState().getDpId();
            List<String> nexthops = new ArrayList<String>();
            for (BigInteger dpnId : dpnIdList) {
                nexthops.add(InterfaceUtils.getEndpointIpAddressForDPN(broker, dpnId));
            }
            try {
                LOG.debug("Advertising route in VPN={} [prefix={} label={}  nexthops={}] to DC-GW",
                        dstVpnRd, newVrfEntry.getDestPrefix(), label.intValue(), nexthops);
                bgpManager.advertisePrefix(dstVpnRd, null /*macAddress*/, newVrfEntry.getDestPrefix(), nexthops,
                        VrfEntry.EncapType.Mplsgre, label.intValue(), 0 /*l3vni*/, null /*gatewayMacAddress*/);
            } catch (Exception exc) {
                LOG.error("Could not advertise prefix {} with label {} to VPN rd={}",
                        newVrfEntry.getDestPrefix(), label.intValue(), dstVpnRd);
            }
        } else {
            LOG.warn("Error when advertising leaked routes: Could not find State for InterVpnLink={}",
                    interVpnLink.getName());
        }
    }

    public static void handleStaticRoute(InterVpnLinkDataComposite iVpnLink, String vpnName,
                                         String destination, String nexthop, int label,
                                         DataBroker dataBroker, IFibManager fibManager, IBgpManager bgpManager)
             throws Exception {

        LOG.debug("handleStaticRoute [vpnLink={} srcVpn={} destination={} nextHop={} label={}]",
                  iVpnLink.getInterVpnLinkName(), vpnName, destination, nexthop, label);

        String vpnRd = VpnUtil.getVpnRd(dataBroker, vpnName);
        if ( vpnRd == null ) {
            LOG.warn("Could not find Route-Distinguisher for VpnName {}", vpnName);
            return;
        }
        LOG.debug("Writing FibEntry to DS:  vpnRd={}, prefix={}, label={}, nexthop={} (interVpnLink)",
                  vpnRd, destination, label, nexthop);
        fibManager.addOrUpdateFibEntry(dataBroker, vpnRd, null /*macAddress*/, destination, Collections.singletonList(nexthop), VrfEntry.EncapType.Mplsgre, label,
                0 /*l3vni*/, null /*gatewayMacAddress*/, RouteOrigin.STATIC, null /*writeTxn*/);

        // Now advertise to BGP. The nexthop that must be advertised to BGP are the IPs of the DPN where the
        // VPN's endpoint have been instantiated
        // List<String> nexthopList = new ArrayList<>(); // The nexthops to be advertised to BGP
        List<BigInteger> endpointDpns = iVpnLink.getEndpointDpnsByVpnName(vpnName);
        List<String> nexthopList =
            endpointDpns.stream().map(dpnId -> InterfaceUtils.getEndpointIpAddressForDPN(dataBroker, dpnId))
                                 .collect(Collectors.toList());
        LOG.debug("advertising IVpnLink route to BGP:  vpnRd={}, prefix={}, label={}, nexthops={}",
                  vpnRd, destination, label, nexthopList);
        bgpManager.advertisePrefix(vpnRd, null /*macAddress*/, destination, nexthopList,
                VrfEntry.EncapType.Mplsgre, label, 0 /*l3vni*/, null /*gatewayMacAddress*/);

        // TODO: Leak if static-routes-leaking flag is active

    }
}
