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
import org.opendaylight.genius.mdsalutil.ActionInfo;
import org.opendaylight.genius.mdsalutil.ActionType;
import org.opendaylight.genius.mdsalutil.InstructionInfo;
import org.opendaylight.genius.mdsalutil.InstructionType;
import org.opendaylight.genius.mdsalutil.MatchInfoBase;
import org.opendaylight.genius.mdsalutil.NwConstants;
import org.opendaylight.genius.mdsalutil.interfaces.IMdsalApiManager;
import org.opendaylight.netvirt.aclservice.api.AclServiceManager.Action;
import org.opendaylight.netvirt.aclservice.utils.AclConstants;
import org.opendaylight.netvirt.aclservice.utils.AclDataUtil;
import org.opendaylight.netvirt.aclservice.utils.AclServiceUtils;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.access.control.list.rev160218.access.lists.acl.access.list.entries.Ace;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.aclservice.rev160608.interfaces._interface.AllowedAddressPairs;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class LearnEgressAclServiceImpl extends AbstractEgressAclServiceImpl {

    private static final Logger LOG = LoggerFactory.getLogger(LearnEgressAclServiceImpl.class);

    /**
     * Initialize the member variables.
     *
     * @param dataBroker
     *            the data broker instance.
     * @param mdsalManager
     *            the mdsal manager instance.
     * @param aclDataUtil
     *            the acl data util.
     * @param aclServiceUtils
     *            the acl service util.
     */
    public LearnEgressAclServiceImpl(DataBroker dataBroker, IMdsalApiManager mdsalManager, AclDataUtil aclDataUtil,
            AclServiceUtils aclServiceUtils) {
        super(dataBroker, mdsalManager, aclDataUtil, aclServiceUtils);
    }

    @Override
    protected void programSpecificFixedRules(BigInteger dpid, String dhcpMacAddress,
            List<AllowedAddressPairs> allowedAddresses, int lportTag, String portId, Action action, int addOrRemove) {
    }

    @Override
    protected String syncSpecificAclFlow(BigInteger dpId, int lportTag, int addOrRemove, int priority, Ace ace,
            String portId, Map<String, List<MatchInfoBase>> flowMap, String flowName) {
        List<MatchInfoBase> flowMatches = flowMap.get(flowName);
        flowMatches.add(AclServiceUtils.buildLPortTagMatch(lportTag));
        List<ActionInfo> actionsInfos = new ArrayList<>();
        addLearnActions(flowMatches, actionsInfos);

        actionsInfos.add(new ActionInfo(ActionType.nx_resubmit,
                new String[] {Short.toString(NwConstants.LPORT_DISPATCHER_TABLE)}));

        List<InstructionInfo> instructions = new ArrayList<>();
        instructions.add(new InstructionInfo(InstructionType.apply_actions, actionsInfos));

        String flowNameAdded = flowName + "Egress" + lportTag + ace.getKey().getRuleName();
        syncFlow(dpId, NwConstants.INGRESS_LEARN2_TABLE, flowNameAdded, AclConstants.PROTO_MATCH_PRIORITY, "ACL", 0, 0,
                AclConstants.COOKIE_ACL_BASE, flowMatches, instructions, addOrRemove);
        return flowName;
    }

    /*
     * learn header
     *
     * 0 1 2 3 4 5 6 7 idleTO hardTO prio cook flags table finidle finhrad
     *
     * learn flowmod learnFlowModType srcField dstField FlowModNumBits 0 1 2 3
     */
    private void addLearnActions(List<MatchInfoBase> flows, List<ActionInfo> actionsInfos) {
        if (AclServiceUtils.containsTcpMatchField(flows)) {
            addTcpLearnActions(actionsInfos);
        } else if (AclServiceUtils.containsUdpMatchField(flows)) {
            addUdpLearnActions(actionsInfos);
        } else {
            addOtherProtocolsLearnActions(actionsInfos);
        }
    }

    private void addOtherProtocolsLearnActions(List<ActionInfo> actionsInfos) {
        String[][] learnActionMatches = LearnCommonAclServiceImpl.getOtherProtocolsLearnActionMatches(actionsInfos);

        String[] header = new String[] {
            String.valueOf(this.aclServiceUtils.getConfig().getSecurityGroupDefaultIdleTimeout()),
            String.valueOf(this.aclServiceUtils.getConfig().getSecurityGroupDefaultHardTimeout()),
            AclConstants.PROTO_MATCH_PRIORITY.toString(),
            AclConstants.COOKIE_ACL_BASE.toString(),
            AclConstants.LEARN_DELETE_LEARNED_FLAG_VALUE.toString(),
            Short.toString(NwConstants.EGRESS_LEARN_TABLE),
            "0",
            "0"
        };
        actionsInfos.add(new ActionInfo(ActionType.learn, header, learnActionMatches));
    }

    private void addTcpLearnActions(List<ActionInfo> actionsInfos) {
        String[][] learnActionMatches = LearnCommonAclServiceImpl.getTcpLearnActionMatches();

        String[] header = new String[] {
            String.valueOf(this.aclServiceUtils.getConfig().getSecurityGroupTcpIdleTimeout()),
            String.valueOf(this.aclServiceUtils.getConfig().getSecurityGroupTcpHardTimeout()),
            AclConstants.PROTO_MATCH_PRIORITY.toString(),
            AclConstants.COOKIE_ACL_BASE.toString(),
            AclConstants.LEARN_DELETE_LEARNED_FLAG_VALUE.toString(),
            Short.toString(NwConstants.EGRESS_LEARN_TABLE),
            String.valueOf(this.aclServiceUtils.getConfig().getSecurityGroupTcpFinIdleTimeout()),
            String.valueOf(this.aclServiceUtils.getConfig().getSecurityGroupTcpFinHardTimeout())
        };
        actionsInfos.add(new ActionInfo(ActionType.learn, header, learnActionMatches));
    }

    private void addUdpLearnActions(List<ActionInfo> actionsInfos) {
        String[][] learnActionMatches = LearnCommonAclServiceImpl.getUdpLearnActionMatches();

        String[] header = new String[] {
            String.valueOf(this.aclServiceUtils.getConfig().getSecurityGroupUdpIdleTimeout()),
            String.valueOf(this.aclServiceUtils.getConfig().getSecurityGroupUdpHardTimeout()),
            AclConstants.PROTO_MATCH_PRIORITY.toString(),
            AclConstants.COOKIE_ACL_BASE.toString(),
            AclConstants.LEARN_DELETE_LEARNED_FLAG_VALUE.toString(),
            Short.toString(NwConstants.EGRESS_LEARN_TABLE),
            "0",
            "0"
        };
        actionsInfos.add(new ActionInfo(ActionType.learn, header, learnActionMatches));
    }
}
