/*
 * Copyright (c) 2016 Red Hat, Inc. and others. All rights reserved.
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
import org.opendaylight.genius.mdsalutil.ActionInfo;
import org.opendaylight.genius.mdsalutil.ActionType;
import org.opendaylight.genius.mdsalutil.InstructionInfo;
import org.opendaylight.genius.mdsalutil.InstructionType;
import org.opendaylight.genius.mdsalutil.MatchFieldType;
import org.opendaylight.genius.mdsalutil.MatchInfo;
import org.opendaylight.genius.mdsalutil.MatchInfoBase;
import org.opendaylight.genius.mdsalutil.NwConstants;
import org.opendaylight.genius.mdsalutil.NxMatchFieldType;
import org.opendaylight.genius.mdsalutil.NxMatchInfo;
import org.opendaylight.genius.mdsalutil.interfaces.IMdsalApiManager;
import org.opendaylight.netvirt.aclservice.api.AclServiceManager.Action;
import org.opendaylight.netvirt.aclservice.api.AclServiceManager.MatchCriteria;
import org.opendaylight.netvirt.aclservice.utils.AclConstants;
import org.opendaylight.netvirt.aclservice.utils.AclDataUtil;
import org.opendaylight.netvirt.aclservice.utils.AclServiceUtils;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.access.control.list.rev160218.access.lists.acl.access.list.entries.Ace;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.aclservice.rev160608.IpPrefixOrAddress;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.aclservice.rev160608.interfaces._interface.AllowedAddressPairs;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Provides the stateful implementation for egress (w.r.t VM) ACL service.
 *
 * <p>
 * Note: Table names used are w.r.t switch. Hence, switch ingress is VM egress
 * and vice versa.
 */
public class StatefulEgressAclServiceImpl extends AbstractEgressAclServiceImpl {

    private static final Logger LOG = LoggerFactory.getLogger(StatefulEgressAclServiceImpl.class);

    public StatefulEgressAclServiceImpl(DataBroker dataBroker, IMdsalApiManager mdsalManager, AclDataUtil aclDataUtil,
            AclServiceUtils aclServiceUtils) {
        super(dataBroker, mdsalManager, aclDataUtil, aclServiceUtils);
    }

    /**
     * Program conntrack rules.
     *
     * @param dpid the dpid
     * @param dhcpMacAddress the dhcp mac address.
     * @param allowedAddresses the allowed addresses
     * @param lportTag the lport tag
     * @param addOrRemove addorRemove
     */
    @Override
    protected void programSpecificFixedRules(BigInteger dpid, String dhcpMacAddress,
            List<AllowedAddressPairs> allowedAddresses, int lportTag, String portId, Action action, int addOrRemove) {
        programEgressAclFixedConntrackRule(dpid, allowedAddresses, lportTag, portId, action, addOrRemove);
    }

    @Override
    protected String syncSpecificAclFlow(BigInteger dpId, int lportTag, int addOrRemove, int priority, Ace ace,
            String portId, Map<String, List<MatchInfoBase>> flowMap, String flowName) {
        List<MatchInfoBase> flows = flowMap.get(flowName);
        flowName += "Egress" + lportTag + ace.getKey().getRuleName();
        flows.add(AclServiceUtils.buildLPortTagMatch(lportTag));
        flows.add(new NxMatchInfo(NxMatchFieldType.ct_state,
            new long[] {AclConstants.TRACKED_NEW_CT_STATE, AclConstants.TRACKED_NEW_CT_STATE_MASK}));

        Long elanId = AclServiceUtils.getElanIdFromInterface(portId, dataBroker);
        List<ActionInfo> actionsInfos = new ArrayList<>();
        actionsInfos.add(new ActionInfo(ActionType.nx_conntrack,
            new String[] {"1", "0", elanId.toString(), "255"}, 2));
        List<InstructionInfo> instructions = getDispatcherTableResubmitInstructions(actionsInfos);

        syncFlow(dpId, NwConstants.INGRESS_ACL_FILTER_TABLE, flowName, priority, "ACL", 0, 0,
                AclConstants.COOKIE_ACL_BASE, flows, instructions, addOrRemove);
        return flowName;
    }

    /**
     * Adds the rule to send the packet to the netfilter to check whether it is
     * a known packet.
     *
     * @param dpId the dpId
     * @param allowedAddresses the allowed addresses
     * @param priority the priority of the flow
     * @param flowId the flowId
     * @param conntrackState the conntrack state of the packets thats should be
     *        send
     * @param conntrackMask the conntrack mask
     * @param portId the portId
     * @param addOrRemove whether to add or remove the flow
     */
    private void programConntrackRecircRules(BigInteger dpId, List<AllowedAddressPairs> allowedAddresses,
            Integer priority, String flowId, String portId, int addOrRemove) {
        for (AllowedAddressPairs allowedAddress : allowedAddresses) {
            IpPrefixOrAddress attachIp = allowedAddress.getIpAddress();
            String attachMac = allowedAddress.getMacAddress().getValue();

            List<MatchInfoBase> matches = new ArrayList<>();
            matches.add(new MatchInfo(MatchFieldType.eth_src, new String[] {attachMac}));
            matches.addAll(AclServiceUtils.buildIpMatches(attachIp, MatchCriteria.MATCH_SOURCE));

            Long elanTag = AclServiceUtils.getElanIdFromInterface(portId, dataBroker);
            List<InstructionInfo> instructions = new ArrayList<>();
            List<ActionInfo> actionsInfos = new ArrayList<>();
            actionsInfos.add(new ActionInfo(ActionType.nx_conntrack,
                    new String[] {"0", "0", elanTag.toString(), Short.toString(
                        NwConstants.INGRESS_ACL_FILTER_TABLE)}, 2));
            instructions.add(new InstructionInfo(InstructionType.apply_actions, actionsInfos));

            String flowName = "Egress_Fixed_Conntrk_" + dpId + "_" + attachMac + "_"
                    + String.valueOf(attachIp.getValue()) + "_" + flowId;
            syncFlow(dpId, NwConstants.INGRESS_ACL_TABLE, flowName, AclConstants.PROTO_MATCH_PRIORITY, "ACL", 0, 0,
                    AclConstants.COOKIE_ACL_BASE, matches, instructions, addOrRemove);
        }
    }

    /**
     * Programs the default connection tracking rules.
     *
     * @param dpid the dp id
     * @param allowedAddresses the allowed addresses
     * @param lportTag the lport tag
     * @param portId the portId
     * @param action the action
     * @param write whether to add or remove the flow.
     */
    private void programEgressAclFixedConntrackRule(BigInteger dpid, List<AllowedAddressPairs> allowedAddresses,
            int lportTag, String portId, Action action, int write) {
        programConntrackRecircRules(dpid, allowedAddresses, AclConstants.CT_STATE_UNTRACKED_PRIORITY,
            "Recirc", portId, write );
        LOG.info("programEgressAclFixedConntrackRule :  default connection tracking rule are added.");
    }
}
