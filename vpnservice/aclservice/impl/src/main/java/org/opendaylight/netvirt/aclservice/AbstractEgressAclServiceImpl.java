/*
 * Copyright (c) 2016 HPE, Inc. and others. All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.aclservice;

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.mdsalutil.ActionInfo;
import org.opendaylight.genius.mdsalutil.ActionType;
import org.opendaylight.genius.mdsalutil.InstructionInfo;
import org.opendaylight.genius.mdsalutil.MDSALUtil;
import org.opendaylight.genius.mdsalutil.MatchFieldType;
import org.opendaylight.genius.mdsalutil.MatchInfo;
import org.opendaylight.genius.mdsalutil.MatchInfoBase;
import org.opendaylight.genius.mdsalutil.NwConstants;
import org.opendaylight.genius.mdsalutil.interfaces.IMdsalApiManager;
import org.opendaylight.genius.utils.ServiceIndex;
import org.opendaylight.netvirt.aclservice.api.AclServiceManager.Action;
import org.opendaylight.netvirt.aclservice.utils.AclConstants;
import org.opendaylight.netvirt.aclservice.utils.AclDataUtil;
import org.opendaylight.netvirt.aclservice.utils.AclServiceOFFlowBuilder;
import org.opendaylight.netvirt.aclservice.utils.AclServiceUtils;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.access.control.list.rev160218.access.lists.Acl;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.access.control.list.rev160218.access.lists.acl.AccessListEntries;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.access.control.list.rev160218.access.lists.acl.access.list.entries.Ace;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.access.control.list.rev160218.access.lists.acl.access.list.entries.ace.Matches;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.access.control.list.rev160218.access.lists.acl.access.list.entries.ace.matches.AceType;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.access.control.list.rev160218.access.lists.acl.access.list.entries.ace.matches.ace.type.AceIp;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.types.rev131026.instruction.list.Instruction;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.servicebinding.rev160406.ServiceModeIngress;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.servicebinding.rev160406.service.bindings.services.info.BoundServices;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.aclservice.rev160608.DirectionEgress;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.aclservice.rev160608.SecurityRuleAttr;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.aclservice.rev160608.interfaces._interface.AllowedAddressPairs;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Provides abstract implementation for egress (w.r.t VM) ACL service.
 *
 * <p>
 * Note: Table names used are w.r.t switch. Hence, switch ingress is VM egress
 * and vice versa.
 */
public abstract class AbstractEgressAclServiceImpl extends AbstractAclServiceImpl {

    private static final Logger LOG = LoggerFactory.getLogger(AbstractEgressAclServiceImpl.class);

    /**
     * Initialize the member variables.
     *
     * @param dataBroker the data broker instance.
     * @param mdsalManager the mdsal manager instance.
     * @param aclDataUtil
     *            the acl data util.
     * @param aclServiceUtils
     *            the acl service util.
     */
    public AbstractEgressAclServiceImpl(DataBroker dataBroker, IMdsalApiManager mdsalManager, AclDataUtil aclDataUtil,
            AclServiceUtils aclServiceUtils) {
        // Service mode is w.rt. switch
        super(ServiceModeIngress.class, dataBroker, mdsalManager, aclDataUtil, aclServiceUtils);
    }

    /**
     * Bind service.
     *
     * @param interfaceName the interface name
     */
    @Override
    protected void bindService(String interfaceName) {
        int flowPriority = AclConstants.EGRESS_ACL_DEFAULT_FLOW_PRIORITY;

        int instructionKey = 0;
        List<Instruction> instructions = new ArrayList<>();
        instructions.add(MDSALUtil.buildAndGetGotoTableInstruction(NwConstants.INGRESS_ACL_TABLE, ++instructionKey));
        short serviceIndex = ServiceIndex.getIndex(NwConstants.ACL_SERVICE_NAME, NwConstants.ACL_SERVICE_INDEX);
        BoundServices serviceInfo =
                AclServiceUtils.getBoundServices(String.format("%s.%s.%s", "vpn", "egressacl", interfaceName),
                serviceIndex, flowPriority, AclConstants.COOKIE_ACL_BASE, instructions);
        InstanceIdentifier<BoundServices> path =
                AclServiceUtils.buildServiceId(interfaceName, serviceIndex, ServiceModeIngress.class);
        MDSALUtil.syncWrite(dataBroker, LogicalDatastoreType.CONFIGURATION, path, serviceInfo);
    }

    /**
     * Unbind service.
     *
     * @param interfaceName the interface name
     */
    @Override
    protected void unbindService(String interfaceName) {
        InstanceIdentifier<BoundServices> path =
                AclServiceUtils.buildServiceId(interfaceName,
                        ServiceIndex.getIndex(NwConstants.ACL_SERVICE_NAME, NwConstants.ACL_SERVICE_INDEX),
                        ServiceModeIngress.class);
        MDSALUtil.syncDelete(dataBroker, LogicalDatastoreType.CONFIGURATION, path);
    }

    @Override
    protected void programGeneralFixedRules(BigInteger dpid, String dhcpMacAddress,
            List<AllowedAddressPairs> allowedAddresses, int lportTag, Action action, int addOrRemove) {
        LOG.info("programFixedRules :  adding default rules.");

        if (action == Action.ADD || action == Action.REMOVE) {
            egressAclDhcpAllowClientTraffic(dpid, dhcpMacAddress, lportTag, addOrRemove);
            egressAclDhcpv6AllowClientTraffic(dpid, dhcpMacAddress, lportTag, addOrRemove);
            egressAclDhcpDropServerTraffic(dpid, dhcpMacAddress, lportTag, addOrRemove);
            egressAclDhcpv6DropServerTraffic(dpid, dhcpMacAddress, lportTag, addOrRemove);
            egressAclIcmpv6DropRouterAdvts(dpid, lportTag, addOrRemove);
        }
        programArpRule(dpid, allowedAddresses, lportTag, addOrRemove);
    }

    @Override
    protected boolean programAclRules(List<Uuid> aclUuidList, BigInteger dpId, int lportTag, int addOrRemove, String
            portId) {
        LOG.trace("Applying custom rules DpId {}, lportTag {}", dpId, lportTag);
        if (aclUuidList == null || dpId == null) {
            LOG.warn("one of the egress acl parameters can not be null. sg {}, dpId {}",
                    aclUuidList, dpId);
            return false;
        }
        for (Uuid sgUuid :aclUuidList ) {
            Acl acl = AclServiceUtils.getAcl(dataBroker, sgUuid.getValue());
            if (null == acl) {
                LOG.warn("The ACL is empty");
                continue;
            }
            AccessListEntries accessListEntries = acl.getAccessListEntries();
            List<Ace> aceList = accessListEntries.getAce();
            for (Ace ace: aceList) {
                programAceRule(dpId, lportTag, addOrRemove, acl.getAclName(), ace, portId, null);
            }
        }
        return true;
    }

    @Override
    protected void programAceRule(BigInteger dpId, int lportTag, int addOrRemove, String aclName, Ace ace,
            String portId, List<AllowedAddressPairs> syncAllowedAddresses) {
        SecurityRuleAttr aceAttr = AclServiceUtils.getAccesssListAttributes(ace);
        if (!aceAttr.getDirection().equals(DirectionEgress.class)) {
            return;
        }
        Matches matches = ace.getMatches();
        AceType aceType = matches.getAceType();
        Map<String,List<MatchInfoBase>> flowMap = null;
        if (aceType instanceof AceIp) {
            flowMap = AclServiceOFFlowBuilder.programIpFlow(matches);
            if (syncAllowedAddresses != null) {
                flowMap = AclServiceUtils.getFlowForAllowedAddresses(syncAllowedAddresses, flowMap, false);
            } else if (aceAttr.getRemoteGroupId() != null) {
                flowMap = aclServiceUtils.getFlowForRemoteAcl(aceAttr.getRemoteGroupId(), portId, flowMap,
                    false);
            }
        }
        if (null == flowMap) {
            LOG.error("Failed to apply ACL {} lportTag {}", ace.getKey(), lportTag);
            return;
        }
        int priority = this.aclDataUtil.getAclFlowPriority(aclName);
        // The flow map contains list of flows if port range is selected.
        for (String flowName : flowMap.keySet()) {
            flowName = syncSpecificAclFlow(dpId, lportTag, addOrRemove, priority, ace, portId, flowMap, flowName);
        }
    }

    protected abstract String syncSpecificAclFlow(BigInteger dpId, int lportTag, int addOrRemove, int priority, Ace ace,
            String portId, Map<String, List<MatchInfoBase>> flowMap, String flowName);

    /**
     * Anti-spoofing rule to block the Ipv4 DHCP server traffic from the port.
     *
     * @param dpId the dpId
     * @param dhcpMacAddress the Dhcp mac address
     * @param lportTag the lport tag
     * @param addOrRemove add/remove the flow.
     */
    protected void egressAclDhcpDropServerTraffic(BigInteger dpId, String dhcpMacAddress, int lportTag,
            int addOrRemove) {
        List<MatchInfoBase> matches = AclServiceUtils.buildDhcpMatches(AclConstants.DHCP_SERVER_PORT_IPV4,
                AclConstants.DHCP_CLIENT_PORT_IPV4, lportTag);

        List<InstructionInfo> instructions = new ArrayList<>();
        List<ActionInfo> actionsInfos = new ArrayList<>();
        actionsInfos.add(new ActionInfo(ActionType.drop_action, new String[] {}));
        String flowName = "Egress_DHCP_Server_v4" + dpId + "_" + lportTag + "_" + dhcpMacAddress + "_Drop_";
        syncFlow(dpId, NwConstants.INGRESS_ACL_TABLE, flowName,
                AclConstants.PROTO_DHCP_CLIENT_TRAFFIC_MATCH_PRIORITY, "ACL", 0,
                0, AclConstants.COOKIE_ACL_BASE, matches, instructions, addOrRemove);
    }

    /**
     * Anti-spoofing rule to block the Ipv6 DHCP server traffic from the port.
     *
     * @param dpId the dpId
     * @param dhcpMacAddress the Dhcp mac address
     * @param lportTag the lport tag
     * @param addOrRemove add/remove the flow.
     */
    protected void egressAclDhcpv6DropServerTraffic(BigInteger dpId, String dhcpMacAddress, int lportTag,
            int addOrRemove) {
        List<MatchInfoBase> matches = AclServiceUtils.buildDhcpV6Matches(AclConstants.DHCP_SERVER_PORT_IPV6,
                AclConstants.DHCP_CLIENT_PORT_IPV6, lportTag);

        List<InstructionInfo> instructions = new ArrayList<>();
        List<ActionInfo> actionsInfos = new ArrayList<>();
        actionsInfos.add(new ActionInfo(ActionType.drop_action, new String[] {}));
        String flowName = "Egress_DHCP_Server_v6" + "_" + dpId + "_" + lportTag + "_" + dhcpMacAddress + "_Drop_";
        syncFlow(dpId, NwConstants.INGRESS_ACL_TABLE, flowName,
                AclConstants.PROTO_DHCP_CLIENT_TRAFFIC_MATCH_PRIORITY, "ACL", 0,
                0, AclConstants.COOKIE_ACL_BASE, matches, instructions, addOrRemove);
    }

    /**
     * Anti-spoofing rule to block the Ipv6 Router Advts from the VM port.
     *
     * @param dpId the dpId
     * @param lportTag the lport tag
     * @param addOrRemove add/remove the flow.
     */
    private void egressAclIcmpv6DropRouterAdvts(BigInteger dpId, int lportTag, int addOrRemove) {
        List<MatchInfoBase> matches = AclServiceUtils.buildIcmpV6Matches(AclConstants.ICMPV6_TYPE_RA, 0, lportTag);

        List<InstructionInfo> instructions = new ArrayList<>();
        List<ActionInfo> actionsInfos = new ArrayList<>();
        actionsInfos.add(new ActionInfo(ActionType.drop_action, new String[] {}));
        String flowName = "Egress_ICMPv6" + "_" + dpId + "_" + lportTag + "_" + AclConstants.ICMPV6_TYPE_RA + "_Drop_";
        syncFlow(dpId, NwConstants.INGRESS_ACL_TABLE, flowName, AclConstants.PROTO_IPV6_DROP_PRIORITY, "ACL", 0,
                0, AclConstants.COOKIE_ACL_BASE, matches, instructions, addOrRemove);
    }

    /**
     * Add rule to ensure only DHCP server traffic from the specified mac is
     * allowed.
     *
     * @param dpId the dpid
     * @param dhcpMacAddress the DHCP server mac address
     * @param lportTag the lport tag
     * @param addOrRemove whether to add or remove the flow
     */
    private void egressAclDhcpAllowClientTraffic(BigInteger dpId, String dhcpMacAddress, int lportTag,
            int addOrRemove) {
        final List<MatchInfoBase> matches = AclServiceUtils.buildDhcpMatches(AclConstants.DHCP_CLIENT_PORT_IPV4,
                AclConstants.DHCP_SERVER_PORT_IPV4, lportTag);

        List<ActionInfo> actionsInfos = new ArrayList<>();
        List<InstructionInfo> instructions = getDispatcherTableResubmitInstructions(actionsInfos);

        String flowName = "Egress_DHCP_Client_v4" + dpId + "_" + lportTag + "_" + dhcpMacAddress + "_Permit_";
        syncFlow(dpId, NwConstants.INGRESS_ACL_TABLE, flowName, AclConstants.PROTO_DHCP_CLIENT_TRAFFIC_MATCH_PRIORITY,
            "ACL", 0, 0, AclConstants.COOKIE_ACL_BASE, matches, instructions, addOrRemove);
    }

    /**
     * Add rule to ensure only DHCPv6 server traffic from the specified mac is
     * allowed.
     *
     * @param dpId the dpid
     * @param dhcpMacAddress the DHCP server mac address
     * @param lportTag the lport tag
     * @param addOrRemove whether to add or remove the flow
     */
    private void egressAclDhcpv6AllowClientTraffic(BigInteger dpId, String dhcpMacAddress, int lportTag,
            int addOrRemove) {
        final List<MatchInfoBase> matches = AclServiceUtils.buildDhcpV6Matches(AclConstants.DHCP_CLIENT_PORT_IPV6,
                AclConstants.DHCP_SERVER_PORT_IPV6, lportTag);

        List<ActionInfo> actionsInfos = new ArrayList<>();
        List<InstructionInfo> instructions = getDispatcherTableResubmitInstructions(actionsInfos);

        String flowName = "Egress_DHCP_Client_v6" + "_" + dpId + "_" + lportTag + "_" + dhcpMacAddress + "_Permit_";
        syncFlow(dpId, NwConstants.INGRESS_ACL_TABLE, flowName, AclConstants.PROTO_DHCP_CLIENT_TRAFFIC_MATCH_PRIORITY,
            "ACL", 0, 0, AclConstants.COOKIE_ACL_BASE, matches, instructions, addOrRemove);
    }

    /**
     * Adds the rule to allow arp packets.
     *
     * @param dpId the dpId
     * @param allowedAddresses the allowed addresses
     * @param lportTag the lport tag
     * @param addOrRemove whether to add or remove the flow
     */
    protected void programArpRule(BigInteger dpId, List<AllowedAddressPairs> allowedAddresses, int lportTag,
            int addOrRemove) {
        for (AllowedAddressPairs allowedAddress : allowedAddresses) {
            String attachMac = allowedAddress.getMacAddress().getValue();
            List<MatchInfo> matches = new ArrayList<>();
            matches.add(new MatchInfo(MatchFieldType.eth_type, new long[] {NwConstants.ETHTYPE_ARP}));
            matches.add(new MatchInfo(MatchFieldType.arp_sha, new String[] {attachMac}));
            matches.add(AclServiceUtils.buildLPortTagMatch(lportTag));

            List<InstructionInfo> instructions = getDispatcherTableResubmitInstructions(new ArrayList<>());

            String flowName = "Egress_ARP_" + dpId + "_" + attachMac;
            syncFlow(dpId, NwConstants.INGRESS_ACL_TABLE, flowName,
                    AclConstants.PROTO_ARP_TRAFFIC_MATCH_PRIORITY, "ACL", 0, 0,
                    AclConstants.COOKIE_ACL_BASE, matches, instructions, addOrRemove);
        }
    }
}
