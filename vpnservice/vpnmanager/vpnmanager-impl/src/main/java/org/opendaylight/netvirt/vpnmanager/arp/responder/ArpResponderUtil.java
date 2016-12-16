/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.vpnmanager.arp.responder;

import java.math.BigInteger;
import java.text.MessageFormat;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Iterator;
import java.util.List;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;

import org.opendaylight.controller.md.sal.binding.api.WriteTransaction;
import org.opendaylight.genius.mdsalutil.ActionInfo;
import org.opendaylight.genius.mdsalutil.ActionType;
import org.opendaylight.genius.mdsalutil.BucketInfo;
import org.opendaylight.genius.mdsalutil.FlowEntity;
import org.opendaylight.genius.mdsalutil.GroupEntity;
import org.opendaylight.genius.mdsalutil.InstructionInfo;
import org.opendaylight.genius.mdsalutil.InstructionType;
import org.opendaylight.genius.mdsalutil.MDSALUtil;
import org.opendaylight.genius.mdsalutil.MatchFieldType;
import org.opendaylight.genius.mdsalutil.MatchInfo;
import org.opendaylight.genius.mdsalutil.MetaDataUtil;
import org.opendaylight.genius.mdsalutil.NwConstants;
import org.opendaylight.genius.mdsalutil.interfaces.IMdsalApiManager;
import org.opendaylight.netvirt.vpnmanager.ArpReplyOrRequest;
import org.opendaylight.yang.gen.v1.urn.opendaylight.action.types.rev131112.action.list.Action;
import org.opendaylight.yang.gen.v1.urn.opendaylight.action.types.rev131112.action.list.ActionKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.inventory.rev130819.tables.table.Flow;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.types.rev131026.instruction.list.Instruction;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.AllocateIdInput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.AllocateIdInputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.AllocateIdOutput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.IdManagerService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rpcs.rev160406.GetEgressActionsForInterfaceInputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rpcs.rev160406.GetEgressActionsForInterfaceOutput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rpcs.rev160406.OdlInterfaceRpcService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.group.types.rev131018.GroupTypes;
import org.opendaylight.yang.gen.v1.urn.opendaylight.openflowplugin.extension.nicira.action.rev140714.add.group.input.buckets.bucket.action.action.NxActionResubmitRpcAddGroupCase;
import org.opendaylight.yangtools.yang.common.RpcResult;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Arp Responder Utility Class
 *
 *
 */
public class ArpResponderUtil {

    private final static Logger LOG = LoggerFactory
            .getLogger(ArpResponderUtil.class);

    private static final long WAIT_TIME_FOR_SYNC_INSTALL = Long.getLong("wait.time.sync.install", 300L);

    /**
     * A Utility class
     */
    private ArpResponderUtil() {

    }

    /**
     * Install Group flow on the DPN
     *
     * @param mdSalManager
     *            Reference of MDSAL API RPC that provides API for installing
     *            group flow
     * @param dpnId
     *            DPN on which group flow to be installed
     * @param groupdId
     *            Uniquely identifiable Group Id for the group flow
     * @param groupName
     *            Name of the group flow
     * @param buckets
     *            List of the bucket actions for the group flow
     */
    public static void installGroup(final IMdsalApiManager mdSalManager,
            final BigInteger dpnId, final long groupdId, final String groupName,
            final List<BucketInfo> buckets) {
        LOG.trace("Installing group flow on dpn {}", dpnId);
        final GroupEntity groupEntity = MDSALUtil.buildGroupEntity(dpnId,
                groupdId, groupName, GroupTypes.GroupAll, buckets);
        mdSalManager.syncInstallGroup(groupEntity, WAIT_TIME_FOR_SYNC_INSTALL);
        try {
            Thread.sleep(WAIT_TIME_FOR_SYNC_INSTALL);
        } catch (InterruptedException e1) {
            LOG.warn("Error while waiting for ARP Responder Group Entry to be installed on DPN {} ", dpnId);
        }
    }

    /**
     * Get Default ARP Responder Drop flow on the DPN
     *
     * @param dpnId
     *            DPN on which group flow to be installed
     *
     */
    public static FlowEntity getArpResponderTableMissFlow(final BigInteger dpnId) {
        return MDSALUtil.buildFlowEntity(dpnId, NwConstants.ARP_RESPONDER_TABLE,
                String.valueOf(NwConstants.ARP_RESPONDER_TABLE),
                NwConstants.TABLE_MISS_PRIORITY,
                ArpResponderConstant.DROP_FLOW_NAME.value(), 0, 0,
                NwConstants.COOKIE_ARP_RESPONDER,
                new ArrayList<MatchInfo>(),
                Arrays.asList(new InstructionInfo(InstructionType.apply_actions,
                        Arrays.asList(new ActionInfo(ActionType.drop_action,
                                new String[] {})))));
    }

    /**
     * Get Bucket Actions for ARP Responder Group Flow
     *
     * <p>
     * Install Default Groups, Group has 3 Buckets
     * </p>
     * <ul>
     * <li>Punt to controller</li>
     * <li>Resubmit to Table {@link NwConstants#LPORT_DISPATCHER_TABLE}, for
     * ELAN flooding
     * <li>Resubmit to Table {@link NwConstants#ARP_RESPONDER_TABLE}, for ARP
     * Auto response from DPN itself</li>
     * </ul>
     *
     * @param resubmitTableId
     *            Resubmit Flow Table Id
     * @param resubmitTableId2
     *            Resubmit Flow Table Id
     * @return List of bucket actions
     */
    public static List<BucketInfo> getDefaultBucketInfos(
            final short resubmitTableId, final short resubmitTableId2) {
        final List<BucketInfo> buckets = new ArrayList<>();
        buckets.add(new BucketInfo(Arrays.asList(new ActionInfo(
                ActionType.punt_to_controller, new String[] {}))));
        buckets.add(new BucketInfo(
                Arrays.asList(new ActionInfo(ActionType.nx_resubmit,
                        new String[] { String.valueOf(resubmitTableId) }))));
        buckets.add(new BucketInfo(
                Arrays.asList(new ActionInfo(ActionType.nx_resubmit,
                        new String[] { String.valueOf(resubmitTableId2) }))));
        return buckets;
    }

    /**
     * Get Match Criteria for the ARP Responder Flow
     * <p>
     * List of Match Criteria for ARP Responder
     * </p>
     * <ul>
     * <li>Packet is ARP</li>
     * <li>Packet is ARP Request</li>
     * <li>The ARP packet is requesting for Gateway IP</li>
     * <li>Metadata which is generated by using Service
     * Index({@link NwConstants#L3VPN_SERVICE_INDEX}) Lport Tag
     * ({@link MetaDataUtil#METADATA_MASK_LPORT_TAG}) and VRF
     * ID({@link MetaDataUtil#METADATA_MASK_VRFID})</li>
     * </ul>
     *
     * @param lPortTag
     *            LPort Tag
     * @param vpnId
     *            VPN ID
     * @param ipAddress
     *            Gateway IP
     * @return List of Match criteria
     */
    public static List<MatchInfo> getMatchCriteria(final int lPortTag,
            final long vpnId, final String ipAddress) {

        final List<MatchInfo> matches = new ArrayList<MatchInfo>();
        short mIndex = NwConstants.L3VPN_SERVICE_INDEX;
        final BigInteger metadata = MetaDataUtil.getMetaDataForLPortDispatcher(
                lPortTag, ++mIndex, MetaDataUtil.getVpnIdMetadata(vpnId));
        final BigInteger metadataMask = MetaDataUtil
                .getMetaDataMaskForLPortDispatcher(
                        MetaDataUtil.METADATA_MASK_SERVICE_INDEX,
                        MetaDataUtil.METADATA_MASK_LPORT_TAG,
                        MetaDataUtil.METADATA_MASK_VRFID);

        // Matching Arp request flows
        matches.add(new MatchInfo(MatchFieldType.eth_type,
                new long[] { NwConstants.ETHTYPE_ARP }));
        matches.add(new MatchInfo(MatchFieldType.metadata,
                new BigInteger[] { metadata, metadataMask }));
        matches.add(new MatchInfo(MatchFieldType.arp_op,
                new long[] { ArpReplyOrRequest.REQUEST.getArpOperation() }));
        matches.add(new MatchInfo(MatchFieldType.arp_tpa,
                new String[] { ipAddress, "32" }));
        return matches;

    }

    /**
     * Get List of actions for ARP Responder Flows
     *
     * Actions consists of all the ARP actions from
     * {@link ActionType} and Egress Actions Retrieved
     *
     * @param ifaceMgrRpcService
     *            Interface manager RPC reference to invoke RPC to get Egress
     *            actions for the interface
     * @param vpnInterface
     *            VPN Interface for which flow to be installed
     * @param ipAddress
     *            Gateway IP Address
     * @param macAddress
     *            Gateway MacAddress
     * @return List of ARP Responder Actions actions
     */
    public static List<Action> getActions(
            final OdlInterfaceRpcService ifaceMgrRpcService,
            final String vpnInterface, final String ipAddress,
            final String macAddress) {

        final List<Action> actions = new ArrayList<>();
        int actionCounter = 0;
        actions.add(new ActionInfo(ActionType.move_src_dst_eth, new String[] {},
                actionCounter++).buildAction());
        actions.add(new ActionInfo(ActionType.set_field_eth_src,
                new String[] { macAddress }, actionCounter++)
                        .buildAction());
        actions.add(new ActionInfo(ActionType.set_arp_op,
                new String[] { String.valueOf(NwConstants.ARP_REPLY) },
                actionCounter++).buildAction());
        actions.add(new ActionInfo(ActionType.move_sha_to_tha, new String[] {},
                actionCounter++).buildAction());
        actions.add(new ActionInfo(ActionType.move_spa_to_tpa, new String[] {},
                actionCounter++).buildAction());
        actions.add(new ActionInfo(ActionType.load_mac_to_sha,
                new String[] { macAddress }, actionCounter++)
                        .buildAction());
        actions.add(new ActionInfo(ActionType.load_ip_to_spa,
                new String[] { ipAddress }, actionCounter++).buildAction());
        //A temporary fix until to send packet to incoming port by loading IN_PORT with zero, until in_port is overridden in table=0
        actions.add(new ActionInfo(ActionType.nx_load_in_port,
                new BigInteger[] { BigInteger.ZERO }, actionCounter++)
                        .buildAction());

        actions.addAll(getEgressActionsForInterface(ifaceMgrRpcService,
                vpnInterface, actionCounter));
        LOG.trace("Total Number of actions is {}", actionCounter);
        return actions;

    }

    /**
     * Get instruction list for ARP responder flows originated from ext-net e.g.
     * router-gw/fip.<br>
     * The split-horizon bit should be reset in order to allow traffic from
     * provider network to be routed back to flat/VLAN network and override the
     * egress table drop flow.<br>
     * In order to allow write-metadata in the ARP responder table the resubmit
     * action needs to be replaced with goto instruction.
     *
     * @param ifaceMgrRpcService
     * @param extInterfaceName
     * @param ipAddress
     * @param macAddress
     * @return
     */
    public static List<Instruction> getExtInterfaceInstructions(final OdlInterfaceRpcService ifaceMgrRpcService,
            final String extInterfaceName, final String ipAddress, final String macAddress) {
        Short tableId = null;
        List<Instruction> instructions = new ArrayList<>();
        List<Action> actions = getActions(ifaceMgrRpcService, extInterfaceName, ipAddress, macAddress);
        for (Iterator<Action> iterator = actions.iterator(); iterator.hasNext();) {
            org.opendaylight.yang.gen.v1.urn.opendaylight.action.types.rev131112.action.Action actionClass = iterator
                    .next().getAction();
            if (actionClass instanceof NxActionResubmitRpcAddGroupCase) {
                tableId = ((NxActionResubmitRpcAddGroupCase) actionClass).getNxResubmit().getTable();
                iterator.remove();
                break;
            }
        }

        instructions.add(MDSALUtil.buildApplyActionsInstruction(actions, 0));
        // reset the split-horizon bit to allow traffic to be sent back to the
        // provider port
        instructions.add(new InstructionInfo(InstructionType.write_metadata,
                new BigInteger[] { BigInteger.ZERO, MetaDataUtil.METADATA_MASK_SH_FLAG }).buildInstruction(1));

        if (tableId != null) {
            // replace resubmit action with goto so it can co-exist with
            // write-metadata
            if (tableId > NwConstants.ARP_RESPONDER_TABLE) {
                instructions.add(new InstructionInfo(InstructionType.goto_table, new long[] { tableId.longValue() })
                        .buildInstruction(2));
            } else {
                LOG.warn("Failed to insall responder flow for interface {}. Resubmit to {} can't be replaced with goto",
                        extInterfaceName, tableId);
            }
        }

        return instructions;
    }

    /**
     * Install ARP Responder FLOW
     *
     * @param mdSalManager
     *            Reference of MDSAL API RPC that provides API for installing
     *            flow
     * @param writeInvTxn
     *            Write Transaction to write the flow
     * @param dpnId
     *            DPN on which flow to be installed
     * @param flowId
     *            Uniquely Identifiable Arp Responder Table flow Id
     * @param flowName
     *            Readable flow name
     * @param priority
     *            Flow Priority
     * @param cookie
     *            Flow Cookie
     * @param matches
     *            List of Match Criteria for the flow
     * @param instructions
     *            List of Instructions for the flow
     */
    public static void installFlow(final IMdsalApiManager mdSalManager,
            final WriteTransaction writeInvTxn, final BigInteger dpnId,
            final String flowId, final String flowName,
            final int priority, final BigInteger cookie,
            List<MatchInfo> matches, List<Instruction> instructions) {

        final Flow flowEntity = MDSALUtil.buildFlowNew(
                NwConstants.ARP_RESPONDER_TABLE, flowId, priority, flowName, 0,
                0, cookie, matches, instructions);
        mdSalManager.addFlowToTx(dpnId, flowEntity, writeInvTxn);
    }

    /**
     * Remove flow form DPN
     *
     * @param mdSalManager
     *            Reference of MDSAL API RPC that provides API for installing
     *            flow
     * @param writeInvTxn
     *            Write Transaction to write the flow
     * @param dpnId
     *            DPN form which flow to be removed
     * @param flowId
     *            Uniquely Identifiable Arp Responder Table flow Id that is to
     *            be removed
     */
    public static void removeFlow(final IMdsalApiManager mdSalManager,
            final WriteTransaction writeInvTxn,
            final BigInteger dpnId, final String flowId) {
        final Flow flowEntity = MDSALUtil
                .buildFlow(NwConstants.ARP_RESPONDER_TABLE, flowId);
        mdSalManager.removeFlowToTx(dpnId, flowEntity, writeInvTxn);
    }

    /**
     * Creates Uniquely Identifiable flow Id
     * <p>
     * <b>Refer:</b> {@link ArpResponderConstant#FLOW_ID_FORMAT}
     *
     * @param lportTag
     *            LportTag of the flow
     * @param gwIp
     *            Gateway IP for which ARP Response flow to be installed
     * @return Unique Flow Id
     */
    public static String getFlowID(final int lportTag, final String gwIp) {
        return MessageFormat.format(ArpResponderConstant.FLOW_ID_FORMAT.value(),
                NwConstants.ARP_RESPONDER_TABLE, lportTag, gwIp);
    }

    /**
     * Generate Cookie per flow
     * <p>
     * Cookie is generated by Summation of
     * {@link NwConstants#COOKIE_ARP_RESPONDER} + 1 + lportTag + Gateway IP
     *
     * @param lportTag
     *            Lport Tag of the flow
     * @param gwIp
     *            Gateway IP for which ARP Response flow to be installed
     * @return Cookie
     */
    public static BigInteger generateCookie(final long lportTag,
            final String gwIp) {
        LOG.trace("IPAddress in long {}", gwIp);
        return NwConstants.COOKIE_ARP_RESPONDER.add(BigInteger.ONE)
                .add(BigInteger.valueOf(lportTag))
                .add(BigInteger.valueOf(ipTolong(gwIp)));
    }

    /**
     * Get IP Address in Long from String
     *
     * @param address
     *            IP Address that to be converted to long
     * @return Long value of the IP Address
     */
    private static long ipTolong(String address) {

        // Parse IP parts into an int array
        long[] ip = new long[4];
        String[] parts = address.split("\\.");

        for (int i = 0; i < 4; i++) {
            ip[i] = Long.parseLong(parts[i]);
        }
        // Add the above IP parts into an int number representing your IP
        // in a 32-bit binary form
        long ipNumbers = 0;
        for (int i = 0; i < 4; i++) {
            ipNumbers += ip[i] << (24 - (8 * i));
        }
        return ipNumbers;

    }

    /**
     * Get List of Egress Action for the VPN interface
     *
     * @param ifaceMgrRpcService
     *            Interface Manager RPC reference that invokes API to retrieve
     *            Egress Action
     * @param ifName
     *            VPN Interface for which Egress Action to be retrieved
     * @param actionCounter
     *            Action Key
     * @return List of Egress Actions
     */
    public static List<Action> getEgressActionsForInterface(
            final OdlInterfaceRpcService ifaceMgrRpcService, String ifName,
            int actionCounter) {
        final List<Action> listActions = new ArrayList<>();
        try {
            final RpcResult<GetEgressActionsForInterfaceOutput> result = ifaceMgrRpcService
                    .getEgressActionsForInterface(
                            new GetEgressActionsForInterfaceInputBuilder()
                                    .setIntfName(ifName).build())
                    .get();
            if (result.isSuccessful()) {
                final List<org.opendaylight.yang.gen.v1.urn.opendaylight.action.types.rev131112.action.list.Action> actions = result
                        .getResult().getAction();
                for (final Action action : actions) {

                    listActions
                            .add(new org.opendaylight.yang.gen.v1.urn.opendaylight.action.types.rev131112.action.list.ActionBuilder(
                                    action).setKey(new ActionKey(actionCounter))
                                            .setOrder(actionCounter++).build());

                }
            } else {
                LOG.warn(
                        "RPC Call to Get egress actions for interface {} returned with Errors {}",
                        ifName, result.getErrors());
            }
        } catch (InterruptedException | ExecutionException e) {
            LOG.warn("Exception when egress actions for interface {}", ifName,
                    e);
        }
        return listActions;
    }

    /**
     * Uses the IdManager to retrieve ARP Responder GroupId from ELAN pool.
     *
     * @param idManager
     *            the id manager
     * @return the integer
     */
    public static Long retrieveStandardArpResponderGroupId(IdManagerService idManager) {

        AllocateIdInput getIdInput = new AllocateIdInputBuilder().setPoolName(ArpResponderConstant.ELAN_ID_POOL_NAME.value())
                .setIdKey(ArpResponderConstant.ARP_RESPONDER_GROUP_ID.value()).build();

        try {
            Future<RpcResult<AllocateIdOutput>> result = idManager.allocateId(getIdInput);
            RpcResult<AllocateIdOutput> rpcResult = result.get();
            if (rpcResult.isSuccessful()) {
                LOG.trace("Retrieved Group Id is {}", rpcResult.getResult().getIdValue().longValue());
                return rpcResult.getResult().getIdValue().longValue();
            } else {
                LOG.warn("RPC Call to Allocate Id returned with Errors {}", rpcResult.getErrors());
            }
        } catch (InterruptedException | ExecutionException e) {
            LOG.warn("Exception when Allocating Id", e);
        }
        return 0L;
    }

}
