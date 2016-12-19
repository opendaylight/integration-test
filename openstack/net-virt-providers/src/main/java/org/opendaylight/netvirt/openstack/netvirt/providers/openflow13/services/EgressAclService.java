/*
 * Copyright (c) 2014 - 2016 Red Hat, Inc. and others. All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.openstack.netvirt.providers.openflow13.services;

import java.net.Inet4Address;
import java.net.Inet6Address;
import java.net.InetAddress;
import java.net.UnknownHostException;
import java.util.ArrayList;
import java.util.List;
import java.util.HashMap;
import java.util.Map;

import org.opendaylight.netvirt.openstack.netvirt.api.Constants;
import org.opendaylight.netvirt.openstack.netvirt.api.EgressAclProvider;
import org.opendaylight.netvirt.openstack.netvirt.api.LearnConstants;
import org.opendaylight.netvirt.openstack.netvirt.api.SecurityGroupCacheManger;
import org.opendaylight.netvirt.openstack.netvirt.api.SecurityServicesManager;
import org.opendaylight.netvirt.openstack.netvirt.providers.ConfigInterface;
import org.opendaylight.netvirt.openstack.netvirt.providers.openflow13.AbstractServiceInstance;
import org.opendaylight.netvirt.openstack.netvirt.providers.openflow13.Service;
import org.opendaylight.netvirt.openstack.netvirt.translator.NeutronSecurityGroup;
import org.opendaylight.netvirt.openstack.netvirt.translator.NeutronSecurityRule;
import org.opendaylight.netvirt.openstack.netvirt.translator.Neutron_IPs;
import org.opendaylight.netvirt.openstack.netvirt.translator.crud.INeutronSecurityRuleCRUD;
import org.opendaylight.netvirt.utils.mdsal.openflow.ActionUtils;
import org.opendaylight.netvirt.utils.mdsal.openflow.FlowUtils;
import org.opendaylight.netvirt.utils.mdsal.openflow.InstructionUtils;
import org.opendaylight.netvirt.utils.mdsal.openflow.MatchUtils;
import org.opendaylight.netvirt.utils.servicehelper.ServiceHelper;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.Ipv4Prefix;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.Ipv6Prefix;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.MacAddress;
import org.opendaylight.yang.gen.v1.urn.opendaylight.action.types.rev131112.action.Action;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.inventory.rev130819.tables.table.FlowBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.types.rev131026.flow.InstructionsBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.types.rev131026.flow.MatchBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.types.rev131026.instruction.list.Instruction;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.types.rev131026.instruction.list.InstructionBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.types.rev131026.instruction.list.InstructionKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.nodes.NodeBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.model.match.types.rev131026.match.Icmpv4MatchBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.model.match.types.rev131026.match.Icmpv6MatchBuilder;
import org.osgi.framework.BundleContext;
import org.osgi.framework.ServiceReference;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.google.common.collect.Lists;

public class EgressAclService extends AbstractServiceInstance implements EgressAclProvider, ConfigInterface {

    private static final Logger LOG = LoggerFactory.getLogger(EgressAclService.class);
    private volatile SecurityServicesManager securityServicesManager;
    private volatile SecurityGroupCacheManger securityGroupCacheManger;
    private volatile INeutronSecurityRuleCRUD neutronSecurityRule;
    private static final int DHCP_SOURCE_PORT = 67;
    private static final int DHCP_DESTINATION_PORT = 68;
    private static final int DHCPV6_SOURCE_PORT = 547;
    private static final int DHCPV6_DESTINATION_PORT = 546;
    private static final String HOST_MASK = "/32";
    private static final String V6_HOST_MASK = "/128";
    private static final int PORT_RANGE_MIN = 1;
    private static final int PORT_RANGE_MAX = 65535;

    public EgressAclService() {
        super(Service.EGRESS_ACL);
    }

    public EgressAclService(Service service) {
        super(service);
    }

    @Override
    public void programPortSecurityGroup(Long dpid, String segmentationId, String attachedMac, long localPort,
                                       NeutronSecurityGroup securityGroup, String portUuid, boolean write) {

        LOG.trace("programPortSecurityGroup: neutronSecurityGroup: {} ", securityGroup);
        if (securityGroup == null || getSecurityRulesforGroup(securityGroup) == null) {
            return;
        }

        List<NeutronSecurityRule> portSecurityList = getSecurityRulesforGroup(securityGroup);
        /* Iterate over the Port Security Rules in the Port Security Group bound to the port*/
        for (NeutronSecurityRule portSecurityRule : portSecurityList) {

            /**
             * Neutron Port Security Acl "egress" and "IPv4"
             * Check that the base conditions for flow based Port Security are true:
             * Port Security Rule Direction ("egress") and Protocol ("IPv4")
             * Neutron defines the direction "ingress" as the vSwitch to the VM as defined in:
             * http://docs.openstack.org/api/openstack-network/2.0/content/security_groups.html
             *
             */

            if (portSecurityRule == null
                    || portSecurityRule.getSecurityRuleEthertype() == null
                    || portSecurityRule.getSecurityRuleDirection() == null) {
                continue;
            }

            if (NeutronSecurityRule.DIRECTION_EGRESS.equals(portSecurityRule.getSecurityRuleDirection())) {
                LOG.debug("programPortSecurityGroup: Acl Rule matching IP and ingress is: {} ", portSecurityRule);
                if (null != portSecurityRule.getSecurityRemoteGroupID()) {
                    //Remote Security group is selected
                    List<Neutron_IPs> remoteSrcAddressList = securityServicesManager
                            .getVmListForSecurityGroup(portUuid,portSecurityRule.getSecurityRemoteGroupID());
                    if (null != remoteSrcAddressList) {
                        for (Neutron_IPs vmIp :remoteSrcAddressList ) {

                            programPortSecurityRule(dpid, segmentationId, attachedMac,
                                                    localPort, portSecurityRule, vmIp, write);
                        }
                        if (write) {
                            securityGroupCacheManger.addToCache(portSecurityRule.getSecurityRemoteGroupID(), portUuid);
                        } else {
                            securityGroupCacheManger.removeFromCache(portSecurityRule.getSecurityRemoteGroupID(),
                                                                     portUuid);
                        }
                    }
                } else {
                    programPortSecurityRule(dpid, segmentationId, attachedMac, localPort,
                                            portSecurityRule, null, write);
                }
                if (write) {
                    securityGroupCacheManger.portAdded(securityGroup.getSecurityGroupUUID(), portUuid);
                } else {
                    securityGroupCacheManger.portRemoved(securityGroup.getSecurityGroupUUID(), portUuid);
                }
            }
        }
    }

    @Override
    public void programPortSecurityRule(Long dpid, String segmentationId, String attachedMac,
                                        long localPort, NeutronSecurityRule portSecurityRule,
                                        Neutron_IPs vmIp, boolean write) {
        String securityRuleEtherType = portSecurityRule.getSecurityRuleEthertype();
        boolean isIpv6 = NeutronSecurityRule.ETHERTYPE_IPV6.equals(securityRuleEtherType);
        if (!isIpv6 && !NeutronSecurityRule.ETHERTYPE_IPV4.equals(securityRuleEtherType)) {
            LOG.debug("programPortSecurityRule: SecurityRuleEthertype {} does not match IPv4/v6.",
                securityRuleEtherType);
            return;
        }


        String ipaddress = null;
        if (null != vmIp) {
            ipaddress = vmIp.getIpAddress();
            try {
                InetAddress address = InetAddress.getByName(ipaddress);
                if (isIpv6 && address instanceof Inet4Address || !isIpv6 && address instanceof Inet6Address) {
                    LOG.debug("programPortSecurityRule: Remote vmIP {} does not match with "
                            + "SecurityRuleEthertype {}.", ipaddress, securityRuleEtherType);
                    return;
                }
            } catch (UnknownHostException e) {
                LOG.warn("Invalid IP address {}", ipaddress, e);
                return;
            }
        }
        if (null == portSecurityRule.getSecurityRuleProtocol()) {
            /* TODO Rework on the priority values */
            egressAclIp(dpid, isIpv6, segmentationId, attachedMac,
                portSecurityRule, ipaddress,
                write, Constants.PROTO_PORT_PREFIX_MATCH_PRIORITY);
            if(!isIpv6) {
                portSecurityRule.setSecurityRuleProtocol(MatchUtils.TCP);
                portSecurityRule.setSecurityRulePortMin(PORT_RANGE_MIN);
                portSecurityRule.setSecurityRulePortMax(PORT_RANGE_MAX);
                egressAclTcp(dpid, segmentationId, attachedMac,
                        portSecurityRule,ipaddress, write,
                        Constants.PROTO_PORT_MATCH_PRIORITY);
                portSecurityRule.setSecurityRuleProtocol(MatchUtils.UDP);
                egressAclUdp(dpid, segmentationId, attachedMac,
                        portSecurityRule, ipaddress, write,
                        Constants.PROTO_PORT_MATCH_PRIORITY);
                portSecurityRule.setSecurityRuleProtocol(MatchUtils.ICMP);
                portSecurityRule.setSecurityRulePortMin(null);
                portSecurityRule.setSecurityRulePortMax(null);
                egressAclIcmp(dpid, segmentationId, attachedMac,
                        portSecurityRule, ipaddress,write,
                        Constants.PROTO_PORT_MATCH_PRIORITY);
                portSecurityRule.setSecurityRuleProtocol(null);
            }
        } else {
            switch (portSecurityRule.getSecurityRuleProtocol() == null ? "" : portSecurityRule.getSecurityRuleProtocol()) {
                case MatchUtils.TCP:
                    LOG.debug("programPortSecurityRule: Rule matching TCP", portSecurityRule);
                    egressAclTcp(dpid, segmentationId, attachedMac,
                        portSecurityRule,ipaddress, write,
                        Constants.PROTO_PORT_PREFIX_MATCH_PRIORITY);
                    break;
                case MatchUtils.UDP:
                    LOG.debug("programPortSecurityRule: Rule matching UDP", portSecurityRule);
                    egressAclUdp(dpid, segmentationId, attachedMac,
                        portSecurityRule, ipaddress, write,
                        Constants.PROTO_PORT_PREFIX_MATCH_PRIORITY);
                    break;
                case MatchUtils.ICMP:
                case MatchUtils.ICMPV6:
                    LOG.debug("programPortSecurityRule: Rule matching ICMP", portSecurityRule);
                    egressAclIcmp(dpid, segmentationId, attachedMac,
                        portSecurityRule, ipaddress,write,
                        Constants.PROTO_PORT_PREFIX_MATCH_PRIORITY);
                    break;
                default:
                    LOG.info("programPortSecurityAcl: Protocol is not TCP/UDP/ICMP but other "
                            + "protocol = ", portSecurityRule.getSecurityRuleProtocol());
                    egressOtherProtocolAclHandler(dpid, segmentationId, attachedMac,
                        portSecurityRule, ipaddress, write,
                        Constants.PROTO_PORT_PREFIX_MATCH_PRIORITY, isIpv6);
                    break;
            }
        }
    }

    private void egressOtherProtocolAclHandler(Long dpidLong, String segmentationId, String srcMac,
                                               NeutronSecurityRule portSecurityRule, String dstAddress,
                                               boolean write, Integer priority, boolean isIpv6) {
        if(null == portSecurityRule.getSecurityRuleProtocol() || portSecurityRule.getSecurityRuleProtocol().equals(MatchUtils.ANY_PROTOCOL)) {
            egressAclIp(dpidLong, isIpv6, segmentationId, srcMac,
                    portSecurityRule, dstAddress,
                    write, Constants.PROTO_PORT_PREFIX_MATCH_PRIORITY - 1);
            if(!isIpv6) {
                portSecurityRule.setSecurityRuleProtocol(MatchUtils.TCP);
                portSecurityRule.setSecurityRulePortMin(PORT_RANGE_MIN);
                portSecurityRule.setSecurityRulePortMax(PORT_RANGE_MAX);
                egressAclTcp(dpidLong, segmentationId, srcMac,
                        portSecurityRule,dstAddress, write,
                        Constants.PROTO_PORT_PREFIX_MATCH_PRIORITY);
                portSecurityRule.setSecurityRuleProtocol(MatchUtils.UDP);
                egressAclUdp(dpidLong, segmentationId, srcMac,
                        portSecurityRule, dstAddress, write,
                        Constants.PROTO_PORT_PREFIX_MATCH_PRIORITY);
                portSecurityRule.setSecurityRulePortMin(null);
                portSecurityRule.setSecurityRulePortMax(null);
                portSecurityRule.setSecurityRuleProtocol(MatchUtils.ICMP);
                egressAclIcmp(dpidLong, segmentationId, srcMac,
                        portSecurityRule, dstAddress,write,
                        Constants.PROTO_PORT_PREFIX_MATCH_PRIORITY);
                portSecurityRule.setSecurityRuleProtocol(null);
            }
        } else {
            if (portSecurityRule.getSecurityRuleProtocol().equals(MatchUtils.TCP_PROTOCOL)) {
                portSecurityRule.setSecurityRulePortMin(PORT_RANGE_MIN);
                portSecurityRule.setSecurityRulePortMax(PORT_RANGE_MAX);
                egressAclTcp(dpidLong, segmentationId, srcMac,
                        portSecurityRule,dstAddress, write,
                        Constants.PROTO_PORT_PREFIX_MATCH_PRIORITY);
            } else if (portSecurityRule.getSecurityRuleProtocol().equals(MatchUtils.UDP_PROTOCOL)) {
                portSecurityRule.setSecurityRulePortMin(PORT_RANGE_MIN);
                portSecurityRule.setSecurityRulePortMax(PORT_RANGE_MAX);
                egressAclUdp(dpidLong, segmentationId, srcMac,
                        portSecurityRule, dstAddress, write,
                        Constants.PROTO_PORT_PREFIX_MATCH_PRIORITY);
            } else if (portSecurityRule.getSecurityRuleProtocol().equals(MatchUtils.ICMP_PROTOCOL)) {
                egressAclIcmp(dpidLong, segmentationId, srcMac,
                        portSecurityRule, dstAddress,write,
                        Constants.PROTO_PORT_PREFIX_MATCH_PRIORITY);
            } else {
                MatchBuilder matchBuilder = new MatchBuilder();
                String flowId = "Egress_Other_" + segmentationId + "_" + srcMac + "_";
                matchBuilder = MatchUtils.createV4EtherMatchWithType(matchBuilder,srcMac,null,MatchUtils.ETHERTYPE_IPV4);
                short proto = 0;
                try {
                    Integer protocol = new Integer(portSecurityRule.getSecurityRuleProtocol());
                    proto = protocol.shortValue();
                    flowId = flowId + proto;
                } catch (NumberFormatException e) {
                    LOG.error("Protocol vlaue conversion failure", e);
                }
                matchBuilder = MatchUtils.createIpProtocolAndEthMatch(matchBuilder, proto, srcMac, null);
                if (null != dstAddress) {
                    flowId = flowId + dstAddress;
                    matchBuilder = MatchUtils.addRemoteIpPrefix(matchBuilder, null,
                                                                 MatchUtils.iPv4PrefixFromIPv4Address(dstAddress));
                } else if (null != portSecurityRule.getSecurityRuleRemoteIpPrefix()) {
                    flowId = flowId + portSecurityRule.getSecurityRuleRemoteIpPrefix();
                    if(isIpv6) {
                        matchBuilder = MatchUtils.addRemoteIpv6Prefix(matchBuilder,null,
                                new Ipv6Prefix(portSecurityRule.getSecurityRuleRemoteIpPrefix()));
                    } else {
                        if (!portSecurityRule.getSecurityRuleRemoteIpPrefix().contains("/0")) {
                            matchBuilder = MatchUtils.addRemoteIpPrefix(matchBuilder, null,
                                new Ipv4Prefix(portSecurityRule.getSecurityRuleRemoteIpPrefix()));
                        }
                    }
                }
                flowId = flowId + "_Permit";
                NodeBuilder nodeBuilder = FlowUtils.createNodeBuilder(dpidLong);
                FlowBuilder flowBuilder = FlowUtils.createFlowBuilder(flowId, priority, matchBuilder, getTable());
                addInstructionWithConntrackCommit(flowBuilder, false);
                syncFlow(flowBuilder ,nodeBuilder, write);
            }
        }
    }

    @Override
    public void programFixedSecurityGroup(Long dpid, String segmentationId, String attachedMac,
                                          long localPort, List<Neutron_IPs> srcAddressList, boolean write) {

        egressAclDhcpAllowClientTrafficFromVm(dpid, write, localPort,
                                              Constants.PROTO_DHCP_CLIENT_TRAFFIC_MATCH_PRIORITY);
        egressAclDhcpv6AllowClientTrafficFromVm(dpid, write, localPort,
                                                Constants.PROTO_DHCP_CLIENT_TRAFFIC_MATCH_PRIORITY);
        programArpRule(dpid, segmentationId, localPort, attachedMac, write);
        if (securityServicesManager.isConntrackEnabled()) {
            programEgressAclFixedConntrackRule(dpid, segmentationId, localPort, attachedMac, write);
        } else {
            egressVMDrop(dpid, segmentationId, attachedMac, write,Constants.PROTO_TCP_SYN_MATCH_PRIORITY_DROP);
            egressVMRegex(dpid, segmentationId, attachedMac, write,Constants.PROTO_REG6_MATCH_PRIORITY);
        }
        egressAclDhcpDropServerTrafficfromVm(dpid, localPort, write,
                                             Constants.PROTO_DHCP_CLIENT_SPOOF_MATCH_PRIORITY_DROP);
        egressAclDhcpv6DropServerTrafficfromVm(dpid, localPort, write,
                                               Constants.PROTO_DHCP_CLIENT_SPOOF_MATCH_PRIORITY_DROP);
    }
    private void egressVMRegex(Long dpidLong, String segmentationId, String srcMac,
            boolean write, Integer priority) {
        String flowName = "Egress_Regx_" + segmentationId + "_" + srcMac;
        MatchBuilder matchBuilder = new MatchBuilder();
        matchBuilder = MatchUtils.createV4EtherMatchWithoutType(matchBuilder,srcMac,null);
        MatchUtils.addNxRegMatch(matchBuilder,
                new MatchUtils.RegMatch(ClassifierService.REG_FIELD_6, ClassifierService.REG_VALUE_FROM_LOCAL));
        FlowBuilder flowBuilder = FlowUtils.createFlowBuilder(flowName, priority, matchBuilder, getTable());
        addPipelineInstruction(flowBuilder, null, false);
        NodeBuilder nodeBuilder = FlowUtils.createNodeBuilder(dpidLong);
        syncFlow(flowBuilder, nodeBuilder, write);
    }

    private void addTcpSynFlagMatchIpv4Drop(Long dpidLong, String segmentationId, String srcMac,
                                  boolean write, Integer priority) {
        String flowName = "Egress_TCP_Ipv4_" + segmentationId + "_" + srcMac + "_DROP";
        MatchBuilder matchBuilder = new MatchBuilder();
        matchBuilder = MatchUtils.createV4EtherMatchWithType(matchBuilder,srcMac,null,MatchUtils.ETHERTYPE_IPV4);
        matchBuilder = MatchUtils.addTcpSynMatch(matchBuilder);
        FlowBuilder flowBuilder = FlowUtils.createFlowBuilder(flowName, priority, matchBuilder, getTable());
        addPipelineInstruction(flowBuilder, null, true);
        NodeBuilder nodeBuilder = FlowUtils.createNodeBuilder(dpidLong);
        syncFlow(flowBuilder, nodeBuilder, write);
    }
    private void egressVMDrop(Long dpidLong, String segmentationId, String srcMac,
            boolean write, Integer priority) {
        String flowName = "Egress_Drop_" + segmentationId + "_" + srcMac + "_DROP";
        MatchBuilder matchBuilder = new MatchBuilder();
        matchBuilder = MatchUtils.createV4EtherMatchWithoutType(matchBuilder,srcMac,null);
        FlowBuilder flowBuilder = FlowUtils.createFlowBuilder(flowName, priority, matchBuilder, getTable());
        addPipelineInstruction(flowBuilder, null, true);
        NodeBuilder nodeBuilder = FlowUtils.createNodeBuilder(dpidLong);
        syncFlow(flowBuilder, nodeBuilder, write);
    }

    private void addTcpSynFlagMatchIpv6Drop(Long dpidLong, String segmentationId, String srcMac,
                                        boolean write, Integer priority) {
        String flowName = "Egress_TCP_Ipv6_" + segmentationId + "_" + srcMac + "_DROP";
        MatchBuilder matchBuilder = new MatchBuilder();
        matchBuilder = MatchUtils.createV6EtherMatchWithType(matchBuilder,srcMac,null);
        matchBuilder = MatchUtils.addTcpSynMatch(matchBuilder);
        FlowBuilder flowBuilder = FlowUtils.createFlowBuilder(flowName, priority, matchBuilder, getTable());
        addPipelineInstruction(flowBuilder, null, true);
        NodeBuilder nodeBuilder = FlowUtils.createNodeBuilder(dpidLong);
        syncFlow(flowBuilder, nodeBuilder, write);
    }

    private void programArpRule(Long dpid, String segmentationId, long localPort, String attachedMac, boolean write) {
        MatchBuilder matchBuilder = new MatchBuilder();
        String flowId = "Egress_ARP_" + segmentationId + "_" + localPort + "_";
        MatchUtils.createV4EtherMatchWithType(matchBuilder,null,null,MatchUtils.ETHERTYPE_ARP);
        MatchUtils.addArpMacMatch(matchBuilder, attachedMac, null);
        FlowBuilder flowBuilder = FlowUtils.createFlowBuilder(flowId, Constants.PROTO_MATCH_PRIORITY,
                                                              matchBuilder, getTable());
        addPipelineInstruction(flowBuilder, null, false);
        NodeBuilder nodeBuilder = FlowUtils.createNodeBuilder(dpid);
        syncFlow(flowBuilder ,nodeBuilder, write);
    }

    private void programEgressAclFixedConntrackRule(Long dpid,
                                             String segmentationId, long localPort, String attachMac, boolean write) {
        try {
            programConntrackUntrackRule(dpid, segmentationId, localPort,attachMac,
                                        Constants.CT_STATE_UNTRACKED_PRIORITY, write );
            programConntrackTrackedPlusEstRule(dpid, segmentationId, localPort,
                                               Constants.CT_STATE_TRACKED_EXIST_PRIORITY, write );
            programConntrackTrackedPlusRelRule(dpid, segmentationId, localPort,
                                               Constants.CT_STATE_TRACKED_EXIST_PRIORITY, write );
            programConntrackNewDropRule(dpid, segmentationId, localPort,
                                        Constants.CT_STATE_NEW_PRIORITY_DROP, write );
            programConntrackInvDropRule(dpid, segmentationId, localPort,
                                        Constants.CT_STATE_NEW_PRIORITY_DROP, write );
            LOG.info("programEgressAclFixedConntrackRule :  default connection tracking rule are added.");
        } catch (Exception e) {
            LOG.error("Failed to add default conntrack rules : " , e);
        }
    }

    private void programConntrackUntrackRule(Long dpidLong, String segmentationId,
                                             long localPort, String attachMac, Integer priority, boolean write) {
        MatchBuilder matchBuilder = new MatchBuilder();
        String flowName = "Egress_Fixed_Conntrk_Untrk_" + segmentationId + "_" + localPort + "_";
        matchBuilder = MatchUtils.createV4EtherMatchWithType(matchBuilder, attachMac, null,MatchUtils.ETHERTYPE_IPV4);
        matchBuilder = MatchUtils.addCtState(matchBuilder,MatchUtils.UNTRACKED_CT_STATE,
                                             MatchUtils.UNTRACKED_CT_STATE_MASK);
        FlowBuilder flowBuilder = FlowUtils.createFlowBuilder(flowName, priority, matchBuilder, getTable());
        addInstructionWithConntrackRecirc(flowBuilder);
        NodeBuilder nodeBuilder = FlowUtils.createNodeBuilder(dpidLong);
        syncFlow(flowBuilder ,nodeBuilder, write);
    }

    private void programConntrackTrackedPlusEstRule(Long dpidLong, String segmentationId,
                                                    long localPort,Integer priority, boolean write) {
        MatchBuilder matchBuilder = new MatchBuilder();
        String flowName = "Egress_Fixed_Conntrk_TrkEst_" + segmentationId + "_" + localPort + "_";
        matchBuilder = MatchUtils.createInPortMatch(matchBuilder, dpidLong, localPort);
        matchBuilder = MatchUtils.addCtState(matchBuilder,MatchUtils.TRACKED_EST_CT_STATE,
                                             MatchUtils.TRACKED_CT_STATE_MASK);
        FlowBuilder flowBuilder = FlowUtils.createFlowBuilder(flowName, priority, matchBuilder, getTable());
        addPipelineInstruction(flowBuilder, null, false);
        NodeBuilder nodeBuilder = FlowUtils.createNodeBuilder(dpidLong);
        syncFlow(flowBuilder ,nodeBuilder, write);
    }

    private void programConntrackTrackedPlusRelRule(Long dpidLong, String segmentationId,
                                                    long localPort,Integer priority, boolean write) {
        MatchBuilder matchBuilder = new MatchBuilder();
        String flowName = "Egress_Fixed_Conntrk_TrkRel_" + segmentationId + "_" + localPort + "_";
        matchBuilder = MatchUtils.createInPortMatch(matchBuilder, dpidLong, localPort);
        matchBuilder = MatchUtils.addCtState(matchBuilder,MatchUtils.TRACKED_REL_CT_STATE,
                                             MatchUtils.TRACKED_CT_STATE_MASK);
        FlowBuilder flowBuilder = FlowUtils.createFlowBuilder(flowName, priority, matchBuilder, getTable());
        addPipelineInstruction(flowBuilder, null, false);
        NodeBuilder nodeBuilder = FlowUtils.createNodeBuilder(dpidLong);
        syncFlow(flowBuilder ,nodeBuilder, write);
    }

    private void programConntrackNewDropRule(Long dpidLong, String segmentationId,
                                             long localPort, Integer priority, boolean write) {
        MatchBuilder matchBuilder = new MatchBuilder();

        String flowName = "Egress_Fixed_Conntrk_NewDrop_" + segmentationId + "_" + localPort + "_";
        matchBuilder = MatchUtils.createInPortMatch(matchBuilder, dpidLong, localPort);
        matchBuilder = MatchUtils.addCtState(matchBuilder,MatchUtils.TRACKED_NEW_CT_STATE,
                                             MatchUtils.TRACKED_NEW_CT_STATE_MASK);
        FlowBuilder flowBuilder = FlowUtils.createFlowBuilder(flowName, priority, matchBuilder, getTable());
        addPipelineInstruction(flowBuilder, null, true);
        NodeBuilder nodeBuilder = FlowUtils.createNodeBuilder(dpidLong);
        syncFlow(flowBuilder ,nodeBuilder, write);
    }

    private void programConntrackInvDropRule(Long dpidLong, String segmentationId,
                                             long localPort, Integer priority, boolean write) {
        MatchBuilder matchBuilder = new MatchBuilder();
        String flowName = "Egress_Fixed_Conntrk_InvDrop_" + segmentationId + "_" + localPort + "_";
        matchBuilder = MatchUtils.createInPortMatch(matchBuilder, dpidLong, localPort);
        matchBuilder = MatchUtils.addCtState(matchBuilder,MatchUtils.TRACKED_INV_CT_STATE,
                                             MatchUtils.TRACKED_INV_CT_STATE_MASK);
        FlowBuilder flowBuilder = FlowUtils.createFlowBuilder(flowName, priority, matchBuilder, getTable());
        addPipelineInstruction(flowBuilder, null, true);
        NodeBuilder nodeBuilder = FlowUtils.createNodeBuilder(dpidLong);
        syncFlow(flowBuilder ,nodeBuilder, write);
    }

    /**
     * Allows IPv4/v6 packet egress from the src mac address.
     * @param dpidLong the dpid
     * @param isIpv6 whether the rule is for ipv6
     * @param segmentationId the segementation id
     * @param srcMac the src mac address
     * @param write add or remove
     * @param protoPortMatchPriority the protocol match priority.
     */
    private void egressAclIp(Long dpidLong, boolean isIpv6, String segmentationId, String srcMac,
                             NeutronSecurityRule portSecurityRule, String srcAddress,
                               boolean write, Integer protoPortMatchPriority ) {
        MatchBuilder matchBuilder = new MatchBuilder();
        String flowId = "Egress_IP" + segmentationId + "_" + srcMac + "_Permit_";
        if (isIpv6) {
            matchBuilder = MatchUtils.createV6EtherMatchWithType(matchBuilder,srcMac,null);
        } else {
            matchBuilder = MatchUtils.createV4EtherMatchWithType(matchBuilder,srcMac,null,MatchUtils.ETHERTYPE_IPV4);
        }
        if (null != srcAddress) {
            flowId = flowId + srcAddress;
            if (isIpv6) {
                matchBuilder = MatchUtils.addRemoteIpv6Prefix(matchBuilder,
                        MatchUtils.iPv6PrefixFromIPv6Address(srcAddress),null);
            } else {
                matchBuilder = MatchUtils.addRemoteIpPrefix(matchBuilder,
                        MatchUtils.iPv4PrefixFromIPv4Address(srcAddress),null);
            }
        } else {
            if (isIpv6) {
                flowId = flowId + "Ipv6";
            } else {
                flowId = flowId + "Ipv4";
            }
        }
        addConntrackMatch(matchBuilder, MatchUtils.TRACKED_NEW_CT_STATE,MatchUtils.TRACKED_NEW_CT_STATE_MASK);
        FlowBuilder flowBuilder = FlowUtils.createFlowBuilder(flowId, protoPortMatchPriority, matchBuilder, getTable());
        addInstructionWithConntrackCommit(flowBuilder, false);
        NodeBuilder nodeBuilder = FlowUtils.createNodeBuilder(dpidLong);
        syncFlow(flowBuilder ,nodeBuilder, write);
    }

    /**
     * Creates a egress match with src macaddress. If dest address is specified
     * destination specific match will be created. Otherwise a match with a
     * CIDR will be created.
     * @param dpidLong the dpid
     * @param segmentationId the segmentation id
     * @param srcMac the source mac address.
     * @param portSecurityRule the security rule in the SG
     * @param dstAddress the destination IP address
     * @param write add or delete
     * @param protoPortMatchPriority the protocol match priroty
     */
    private void egressAclTcp(Long dpidLong, String segmentationId, String srcMac,
                              NeutronSecurityRule portSecurityRule, String dstAddress,
                              boolean write, Integer protoPortMatchPriority) {
        boolean portRange = false;
        MatchBuilder matchBuilder = new MatchBuilder();
        String flowId = "Egress_TCP_" + segmentationId + "_" + srcMac + "_";
        boolean isIpv6 = NeutronSecurityRule.ETHERTYPE_IPV6.equals(portSecurityRule.getSecurityRuleEthertype());
        if (isIpv6) {
            matchBuilder = MatchUtils.createV6EtherMatchWithType(matchBuilder,srcMac,null);
        } else {
            matchBuilder = MatchUtils.createV4EtherMatchWithType(matchBuilder,srcMac,null,MatchUtils.ETHERTYPE_IPV4);
        }

        /* Custom TCP Match */
        if (portSecurityRule.getSecurityRulePortMin() != null && portSecurityRule.getSecurityRulePortMax() != null) {
            if (portSecurityRule.getSecurityRulePortMin().equals(portSecurityRule.getSecurityRulePortMax())) {
                flowId = flowId + portSecurityRule.getSecurityRulePortMin() + "_";
                matchBuilder = MatchUtils.addLayer4Match(matchBuilder, MatchUtils.TCP_SHORT, 0,
                        portSecurityRule.getSecurityRulePortMin());
            } else if (portSecurityRule.getSecurityRulePortMin().equals(PORT_RANGE_MIN)
                    && portSecurityRule.getSecurityRulePortMax().equals(PORT_RANGE_MAX)) {
                /* All TCP Match */
                flowId = flowId + portSecurityRule.getSecurityRulePortMin() + "_"
                        + portSecurityRule.getSecurityRulePortMax() + "_";
                matchBuilder = MatchUtils.addLayer4Match(matchBuilder, MatchUtils.TCP_SHORT, 0, 0);
            } else {
                portRange = true;
            }
        }
        if (null != dstAddress) {
            flowId = flowId + dstAddress;
            if (isIpv6) {
                matchBuilder = MatchUtils.addRemoteIpv6Prefix(matchBuilder,null,
                        MatchUtils.iPv6PrefixFromIPv6Address(dstAddress));
            } else {
                matchBuilder = MatchUtils.addRemoteIpPrefix(matchBuilder,null,
                        MatchUtils.iPv4PrefixFromIPv4Address(dstAddress));
            }
        } else if (null != portSecurityRule.getSecurityRuleRemoteIpPrefix()) {
            flowId = flowId + portSecurityRule.getSecurityRuleRemoteIpPrefix();
            if (isIpv6) {
                matchBuilder = MatchUtils.addRemoteIpv6Prefix(matchBuilder,null,
                        new Ipv6Prefix(portSecurityRule.getSecurityRuleRemoteIpPrefix()));
            } else {
                // Fix: Bug 6473
                // IP match removed if CIDR created as 0.0.0.0/0 in openstack security rule
                if (!portSecurityRule.getSecurityRuleRemoteIpPrefix().contains("/0")) {
                    matchBuilder = MatchUtils.addRemoteIpPrefix(matchBuilder,null,
                            new Ipv4Prefix(portSecurityRule
                                           .getSecurityRuleRemoteIpPrefix()));
                 }
            }
        }
        NodeBuilder nodeBuilder = FlowUtils.createNodeBuilder(dpidLong);
        if (portRange) {
            Map<Integer, Integer> portMaskMap = MatchUtils
                    .getLayer4MaskForRange(portSecurityRule.getSecurityRulePortMin(),
                                           portSecurityRule.getSecurityRulePortMax());
            for (Integer port: portMaskMap.keySet()) {
                String rangeflowId = flowId + port + "_" + portMaskMap.get(port) + "_";
                rangeflowId = rangeflowId + "_Permit";
                MatchUtils.addLayer4MatchWithMask(matchBuilder, MatchUtils.TCP_SHORT,
                                                  0, port, portMaskMap.get(port));
                addConntrackMatch(matchBuilder, MatchUtils.TRACKED_NEW_CT_STATE,MatchUtils.TRACKED_NEW_CT_STATE_MASK);
                FlowBuilder flowBuilder = FlowUtils.createFlowBuilder(rangeflowId, protoPortMatchPriority,
                                                                      matchBuilder, getTable());
                addInstructionWithLearnConntrackCommit(portSecurityRule, flowBuilder, null, null);
                syncFlow(flowBuilder ,nodeBuilder, write);
            }
        } else {
            flowId = flowId + "_Permit";
            addConntrackMatch(matchBuilder, MatchUtils.TRACKED_NEW_CT_STATE,MatchUtils.TRACKED_NEW_CT_STATE_MASK);
            FlowBuilder flowBuilder = FlowUtils.createFlowBuilder(flowId, protoPortMatchPriority,
                                                                  matchBuilder, getTable());
            addInstructionWithLearnConntrackCommit(portSecurityRule, flowBuilder, null, null);
            syncFlow(flowBuilder ,nodeBuilder, write);
        }
    }

    private void addTcpSynMatch(MatchBuilder matchBuilder) {
        if (!securityServicesManager.isConntrackEnabled()) {
            MatchUtils.createTcpProtoSynMatch(matchBuilder);
        }
    }

    private void egressAclIcmp(Long dpidLong, String segmentationId, String srcMac,
            NeutronSecurityRule portSecurityRule, String dstAddress,
            boolean write, Integer protoPortMatchPriority) {

        boolean isIpv6 = NeutronSecurityRule.ETHERTYPE_IPV6.equals(portSecurityRule.getSecurityRuleEthertype());
        if (isIpv6) {
            egressAclIcmpV6(dpidLong, segmentationId, srcMac, portSecurityRule, dstAddress, write,
                            protoPortMatchPriority);
        } else {
            egressAclIcmpV4(dpidLong, segmentationId, srcMac, portSecurityRule, dstAddress, write,
                            protoPortMatchPriority);
        }
    }

    /**
     * Creates a icmp egress match with src macaddress. If dest address is specified
     * destination specific match will be created. Otherwise a match with a
     * CIDR will be created.
     * @param dpidLong the dpid
     * @param segmentationId the segmentation id
     * @param srcMac the source mac address.
     * @param portSecurityRule the security rule in the SG
     * @param dstAddress the source IP address
     * @param write add or delete
     * @param protoPortMatchPriority the protocol match priority
     */
    private void egressAclIcmpV4(Long dpidLong, String segmentationId, String srcMac,
                                 NeutronSecurityRule portSecurityRule, String dstAddress,
                                 boolean write, Integer protoPortMatchPriority) {

        MatchBuilder matchBuilder = new MatchBuilder();
        boolean isIcmpAll = false;
        String flowId = "Egress_ICMP_" + segmentationId + "_" + srcMac + "_";
        matchBuilder = MatchUtils.createV4EtherMatchWithType(matchBuilder,srcMac,null,MatchUtils.ETHERTYPE_IPV4);
        /*Custom ICMP Match */
        if (portSecurityRule.getSecurityRulePortMin() != null
                && portSecurityRule.getSecurityRulePortMax() != null) {
            flowId = flowId + portSecurityRule.getSecurityRulePortMin().shortValue() + "_"
                    + portSecurityRule.getSecurityRulePortMax().shortValue() + "_";
            matchBuilder = MatchUtils.createICMPv4Match(matchBuilder,
                    portSecurityRule.getSecurityRulePortMin().shortValue(),
                    portSecurityRule.getSecurityRulePortMax().shortValue());
        } else {
            isIcmpAll = true;
            /* All ICMP Match */ // We are getting from neutron NULL for both min and max
            flowId = flowId + "all" + "_" ;
            matchBuilder = MatchUtils.createICMPv4Match(matchBuilder, MatchUtils.ALL_ICMP, MatchUtils.ALL_ICMP);
        }
        if (null != dstAddress) {
            flowId = flowId + dstAddress;
            matchBuilder = MatchUtils.addRemoteIpPrefix(matchBuilder,null,
                    MatchUtils.iPv4PrefixFromIPv4Address(dstAddress));
        } else if (null != portSecurityRule.getSecurityRuleRemoteIpPrefix()) {
            flowId = flowId + portSecurityRule.getSecurityRuleRemoteIpPrefix();
            if (!portSecurityRule.getSecurityRuleRemoteIpPrefix().contains("/0")) {
                matchBuilder = MatchUtils.addRemoteIpPrefix(matchBuilder,null,
                    new Ipv4Prefix(portSecurityRule.getSecurityRuleRemoteIpPrefix()));
            }
        }
        NodeBuilder nodeBuilder = FlowUtils.createNodeBuilder(dpidLong);
        //matchBuilder = MatchUtils.createICMPv4Match(matchBuilder, portSecurityRule.getSecurityRulePortMin().shortValue(), portSecurityRule.getSecurityRulePortMax().shortValue());
        if(isIcmpAll)
        {
            Map<Integer, String> map = LearnConstants.ICMP_TYPE_MAP;
            for(Map.Entry<Integer, String> entry : map.entrySet()) {
                Icmpv4MatchBuilder icmpv4match = new Icmpv4MatchBuilder();
                icmpv4match.setIcmpv4Type(entry.getKey().shortValue());
                icmpv4match.setIcmpv4Code((short)0);
                matchBuilder.setIcmpv4Match(icmpv4match.build());
                String rangeflowId = flowId + "_" + entry.getKey() + "_" + entry.getValue();
                addConntrackMatch(matchBuilder, MatchUtils.TRACKED_NEW_CT_STATE,MatchUtils.TRACKED_NEW_CT_STATE_MASK);
                FlowBuilder flowBuilder = FlowUtils.createFlowBuilder(rangeflowId, protoPortMatchPriority, matchBuilder, getTable());
                addInstructionWithLearnConntrackCommit(portSecurityRule, flowBuilder, entry.getValue(), "0");
                syncFlow(flowBuilder ,nodeBuilder, write);
            }
            addIcmpFlow(nodeBuilder, portSecurityRule, segmentationId, srcMac, dstAddress, write);
        } else {
            flowId = flowId + "_Permit";
            addConntrackMatch(matchBuilder, MatchUtils.TRACKED_NEW_CT_STATE,MatchUtils.TRACKED_NEW_CT_STATE_MASK);
            FlowBuilder flowBuilder = FlowUtils.createFlowBuilder(flowId, protoPortMatchPriority, matchBuilder, getTable());
             String icmpType = LearnConstants.ICMP_TYPE_MAP.get(portSecurityRule.getSecurityRulePortMin());
            if (icmpType == null){
                icmpType = Integer.toString(portSecurityRule.getSecurityRulePortMin());
            }
            addInstructionWithLearnConntrackCommit(portSecurityRule, flowBuilder, icmpType,
                    Integer.toString(portSecurityRule.getSecurityRulePortMax()));
            syncFlow(flowBuilder ,nodeBuilder, write);
        }
    }

    private void addIcmpFlow(NodeBuilder nodeBuilder, NeutronSecurityRule portSecurityRule, String segmentationId, String srcMac,
            String dstAddress, boolean write){
        MatchBuilder matchBuilder = new MatchBuilder();
        InstructionBuilder instructionBuilder = null;
        short learnTableId=getTable(Service.ACL_LEARN_SERVICE);
        short resubmitId=getTable(Service.LOAD_BALANCER);
        String flowId = "Ingress_ICMP_" + segmentationId + "_" + srcMac + "_";
        matchBuilder = MatchUtils.createV4EtherMatchWithType(matchBuilder,srcMac,null,MatchUtils.ETHERTYPE_IPV4);
        flowId = flowId + "all" + "_" ;
        matchBuilder = MatchUtils.createICMPv4Match(matchBuilder, MatchUtils.ALL_ICMP, MatchUtils.ALL_ICMP);
        if (null != dstAddress) {
            flowId = flowId + dstAddress;
            matchBuilder = MatchUtils.addRemoteIpPrefix(matchBuilder,null,
                    MatchUtils.iPv4PrefixFromIPv4Address(dstAddress));
        } else if (null != portSecurityRule.getSecurityRuleRemoteIpPrefix()) {
            flowId = flowId + portSecurityRule.getSecurityRuleRemoteIpPrefix();
            if (!portSecurityRule.getSecurityRuleRemoteIpPrefix().contains("/0")) {
                matchBuilder = MatchUtils.addRemoteIpPrefix(matchBuilder,null,
                    new Ipv4Prefix(portSecurityRule.getSecurityRuleRemoteIpPrefix()));
            }
        }
        Icmpv4MatchBuilder icmpv4match = new Icmpv4MatchBuilder();
        matchBuilder.setIcmpv4Match(icmpv4match.build());
        String rangeflowId = flowId;
        addConntrackMatch(matchBuilder, MatchUtils.TRACKED_NEW_CT_STATE,MatchUtils.TRACKED_NEW_CT_STATE_MASK);
        FlowBuilder flowBuilder = FlowUtils.createFlowBuilder(rangeflowId, Constants.PROTO_PORT_ICMP_MATCH_PRIORITY, matchBuilder, getTable());
        addPipelineInstruction(flowBuilder, null, false);
        syncFlow(flowBuilder ,nodeBuilder, write);

    }

    /**
     * Creates a icmpv6 egress match with src macaddress. If dest address is specified
     * destination specific match will be created. Otherwise a match with a
     * CIDR will be created.
     * @param dpidLong the dpid
     * @param segmentationId the segmentation id
     * @param srcMac the source mac address.
     * @param portSecurityRule the security rule in the SG
     * @param dstAddress the source IP address
     * @param write add or delete
     * @param protoPortMatchPriority the protocol match priority
     */
    private void egressAclIcmpV6(Long dpidLong, String segmentationId, String srcMac,
                                 NeutronSecurityRule portSecurityRule, String dstAddress,
                                 boolean write, Integer protoPortMatchPriority) {

        MatchBuilder matchBuilder = new MatchBuilder();
        String flowId = "Egress_ICMP_" + segmentationId + "_" + srcMac + "_";
        matchBuilder = MatchUtils.createV6EtherMatchWithType(matchBuilder,srcMac,null);

        /*Custom ICMP Match */
        if (portSecurityRule.getSecurityRulePortMin() != null
                && portSecurityRule.getSecurityRulePortMax() != null) {
            flowId = flowId + portSecurityRule.getSecurityRulePortMin().shortValue() + "_"
                    + portSecurityRule.getSecurityRulePortMax().shortValue() + "_";
            matchBuilder = MatchUtils.createICMPv6Match(matchBuilder,
                    portSecurityRule.getSecurityRulePortMin().shortValue(),
                    portSecurityRule.getSecurityRulePortMax().shortValue());
        } else {
            /* All ICMP Match */ // We are getting from neutron NULL for both min and max
            flowId = flowId + "all" + "_" ;
            matchBuilder = MatchUtils.createICMPv6Match(matchBuilder, MatchUtils.ALL_ICMP, MatchUtils.ALL_ICMP);
        }
        if (null != dstAddress) {
            flowId = flowId + dstAddress;
            matchBuilder = MatchUtils.addRemoteIpv6Prefix(matchBuilder,null,
                    MatchUtils.iPv6PrefixFromIPv6Address(dstAddress));
        } else if (null != portSecurityRule.getSecurityRuleRemoteIpPrefix()) {
            flowId = flowId + portSecurityRule.getSecurityRuleRemoteIpPrefix();
            matchBuilder = MatchUtils.addRemoteIpv6Prefix(matchBuilder,null,
                    new Ipv6Prefix(portSecurityRule.getSecurityRuleRemoteIpPrefix()));
        }
        flowId = flowId + "_Permit";
        addConntrackMatch(matchBuilder, MatchUtils.TRACKED_NEW_CT_STATE,MatchUtils.TRACKED_NEW_CT_STATE_MASK);
        NodeBuilder nodeBuilder = FlowUtils.createNodeBuilder(dpidLong);
        FlowBuilder flowBuilder = FlowUtils.createFlowBuilder(flowId, protoPortMatchPriority, matchBuilder, getTable());
        addInstructionWithConntrackCommit(flowBuilder, false);
        syncFlow(flowBuilder ,nodeBuilder, write);
    }

    /**
     * Creates a egress match with src macaddress. If dest address is specified
     * destination specific match will be created. Otherwise a match with a
     * CIDR will be created.
     * @param dpidLong the dpid
     * @param segmentationId the segmentation id
     * @param srcMac the source mac address.
     * @param portSecurityRule the security rule in the SG
     * @param dstAddress the source IP address
     * @param write add or delete
     * @param protoPortMatchPriority the protocol match priroty
     */
    private void egressAclUdp(Long dpidLong, String segmentationId, String srcMac,
                              NeutronSecurityRule portSecurityRule, String dstAddress,
                              boolean write, Integer protoPortMatchPriority) {
        boolean portRange = false;
        MatchBuilder matchBuilder = new MatchBuilder();
        String flowId = "Egress_UDP_" + segmentationId + "_" + srcMac + "_";
        boolean isIpv6 = NeutronSecurityRule.ETHERTYPE_IPV6.equals(portSecurityRule.getSecurityRuleEthertype());
        if (isIpv6) {
            matchBuilder = MatchUtils.createV6EtherMatchWithType(matchBuilder,srcMac,null);
        } else {
            matchBuilder = MatchUtils.createV4EtherMatchWithType(matchBuilder,srcMac,null,MatchUtils.ETHERTYPE_IPV4);
        }

        /* Custom UDP Match */
        if (portSecurityRule.getSecurityRulePortMin() != null && portSecurityRule.getSecurityRulePortMax() != null) {
            if (portSecurityRule.getSecurityRulePortMin().equals(portSecurityRule.getSecurityRulePortMax())) {
                flowId = flowId + portSecurityRule.getSecurityRulePortMin() + "_";
                matchBuilder = MatchUtils.addLayer4Match(matchBuilder, MatchUtils.UDP_SHORT, 0,
                        portSecurityRule.getSecurityRulePortMin());
            } else if (portSecurityRule.getSecurityRulePortMin().equals(PORT_RANGE_MIN)
                    && portSecurityRule.getSecurityRulePortMax().equals(PORT_RANGE_MAX)) {
                /* All UDP Match */
                flowId = flowId + portSecurityRule.getSecurityRulePortMin() + "_"
                        + portSecurityRule.getSecurityRulePortMax() + "_";
                matchBuilder = MatchUtils.addLayer4Match(matchBuilder, MatchUtils.UDP_SHORT, 0, 0);
            } else {
                portRange = true;
            }
        }
        if (null != dstAddress) {
            flowId = flowId + dstAddress;
            if (isIpv6) {
                matchBuilder = MatchUtils.addRemoteIpv6Prefix(matchBuilder,null,
                        MatchUtils.iPv6PrefixFromIPv6Address(dstAddress));
            } else {
                matchBuilder = MatchUtils.addRemoteIpPrefix(matchBuilder,null,
                        MatchUtils.iPv4PrefixFromIPv4Address(dstAddress));
            }
        } else if (null != portSecurityRule.getSecurityRuleRemoteIpPrefix()) {
            flowId = flowId + portSecurityRule.getSecurityRuleRemoteIpPrefix();
            if (isIpv6) {
                matchBuilder = MatchUtils.addRemoteIpv6Prefix(matchBuilder, null,
                        new Ipv6Prefix(portSecurityRule
                                       .getSecurityRuleRemoteIpPrefix()));
            } else {
                if (!portSecurityRule.getSecurityRuleRemoteIpPrefix().contains("/0")) {
                matchBuilder = MatchUtils.addRemoteIpPrefix(matchBuilder, null,
                        new Ipv4Prefix(portSecurityRule
                                       .getSecurityRuleRemoteIpPrefix()));
                }
            }
        }
        NodeBuilder nodeBuilder = FlowUtils.createNodeBuilder(dpidLong);
        if (portRange) {
            Map<Integer, Integer> portMaskMap = MatchUtils
                    .getLayer4MaskForRange(portSecurityRule.getSecurityRulePortMin(),
                                           portSecurityRule.getSecurityRulePortMax());
            for (Integer port: portMaskMap.keySet()) {
                String rangeflowId = flowId + port + "_" + portMaskMap.get(port) + "_";
                rangeflowId = rangeflowId + "_Permit";
                MatchUtils.addLayer4MatchWithMask(matchBuilder, MatchUtils.UDP_SHORT,
                                                  0, port, portMaskMap.get(port));
                addConntrackMatch(matchBuilder, MatchUtils.TRACKED_NEW_CT_STATE,MatchUtils.TRACKED_NEW_CT_STATE_MASK);
                FlowBuilder flowBuilder = FlowUtils.createFlowBuilder(rangeflowId, protoPortMatchPriority,
                                                                      matchBuilder, getTable());
                addInstructionWithLearnConntrackCommit(portSecurityRule, flowBuilder, null, null);
                syncFlow(flowBuilder ,nodeBuilder, write);
            }
        } else {
            flowId = flowId + "_Permit";
            addConntrackMatch(matchBuilder, MatchUtils.TRACKED_NEW_CT_STATE,MatchUtils.TRACKED_NEW_CT_STATE_MASK);
            FlowBuilder flowBuilder = FlowUtils.createFlowBuilder(flowId, protoPortMatchPriority,
                                                                  matchBuilder, getTable());
            addInstructionWithLearnConntrackCommit(portSecurityRule, flowBuilder, null, null);
            syncFlow(flowBuilder ,nodeBuilder, write);
        }
    }

    /**
     * Adds flow to allow any DHCP client traffic.
     *
     * @param dpidLong the dpid
     * @param write whether to write or delete the flow
     * @param localPort the local port.
     * @param priority the priority
     */
    private void egressAclDhcpAllowClientTrafficFromVm(Long dpidLong,
                                                       boolean write, long localPort, Integer priority) {
        String flowName = "Egress_DHCP_Client_"  + localPort + "_Permit_";
        MatchBuilder matchBuilder = new MatchBuilder();
        MatchUtils.createInPortMatch(matchBuilder, dpidLong, localPort);
        MatchUtils.createDhcpMatch(matchBuilder, DHCP_DESTINATION_PORT, DHCP_SOURCE_PORT);
        FlowBuilder flowBuilder = FlowUtils.createFlowBuilder(flowName, priority, matchBuilder, getTable());
        addPipelineInstruction(flowBuilder, null, false);
        NodeBuilder nodeBuilder = FlowUtils.createNodeBuilder(dpidLong);
        syncFlow(flowBuilder ,nodeBuilder, write);
    }

    /**
     * Adds flow to allow any DHCP IPv6 client traffic.
     *
     * @param dpidLong the dpid
     * @param write whether to write or delete the flow
     * @param localPort the local port
     * @param priority the priority
     */
    private void egressAclDhcpv6AllowClientTrafficFromVm(Long dpidLong,
                                                         boolean write, long localPort, Integer priority) {
        String flowName = "Egress_DHCPv6_Client_"  + localPort + "_Permit_";
        MatchBuilder matchBuilder = new MatchBuilder();
        MatchUtils.createInPortMatch(matchBuilder, dpidLong, localPort);
        MatchUtils.createDhcpv6Match(matchBuilder, DHCPV6_DESTINATION_PORT, DHCPV6_SOURCE_PORT);
        FlowBuilder flowBuilder = FlowUtils.createFlowBuilder(flowName, priority, matchBuilder, getTable());
        addPipelineInstruction(flowBuilder, null, false);
        NodeBuilder nodeBuilder = FlowUtils.createNodeBuilder(dpidLong);
        syncFlow(flowBuilder ,nodeBuilder, write);
    }

    /**
     * Adds rule to prevent DHCP spoofing by the vm attached to the port.
     *
     * @param dpidLong the dpid
     * @param localPort the local port
     * @param write is write or delete
     * @param priority  the priority
     */
    private void egressAclDhcpDropServerTrafficfromVm(Long dpidLong, long localPort,
                                                      boolean write, Integer priority) {
        String flowName = "Egress_DHCP_Server_" + localPort + "_DROP";
        MatchBuilder matchBuilder = new MatchBuilder();
        MatchUtils.createInPortMatch(matchBuilder, dpidLong, localPort);
        MatchUtils.createDhcpMatch(matchBuilder, DHCP_SOURCE_PORT, DHCP_DESTINATION_PORT);
        FlowBuilder flowBuilder = FlowUtils.createFlowBuilder(flowName, priority, matchBuilder, getTable());
        addPipelineInstruction(flowBuilder, null, true);
        NodeBuilder nodeBuilder = FlowUtils.createNodeBuilder(dpidLong);
        syncFlow(flowBuilder ,nodeBuilder, write);
    }

    /**
     * Adds rule to prevent DHCPv6 spoofing by the vm attached to the port.
     *
     * @param dpidLong the dpid
     * @param localPort the local port
     * @param write is write or delete
     * @param priority  the priority
     */
    private void egressAclDhcpv6DropServerTrafficfromVm(Long dpidLong, long localPort,
                                                        boolean write, Integer priority) {

        String flowName = "Egress_DHCPv6_Server_" + "_" + localPort + "_DROP";
        MatchBuilder matchBuilder = new MatchBuilder();
        MatchUtils.createInPortMatch(matchBuilder, dpidLong, localPort);
        MatchUtils.createDhcpv6Match(matchBuilder, DHCPV6_SOURCE_PORT, DHCPV6_DESTINATION_PORT);
        FlowBuilder flowBuilder = FlowUtils.createFlowBuilder(flowName, priority, matchBuilder, getTable());
        addPipelineInstruction(flowBuilder, null, true);
        NodeBuilder nodeBuilder = FlowUtils.createNodeBuilder(dpidLong);
        syncFlow(flowBuilder ,nodeBuilder, write);
    }

    /**
     * Adds rule to check legitimate ip/mac pair for each packet from the vm.
     *
     * @param dpidLong the dpid
     * @param localPort the local port
     * @param srcIp the vm ip address
     * @param attachedMac the vm mac address
     * @param priority  the priority
     * @param write is write or delete
     */
    private void egressAclAllowTrafficFromVmIpMacPair(Long dpidLong, long localPort,
                                                      String attachedMac, String srcIp,
                                                      Integer priority, boolean write) {
        MatchBuilder matchBuilder = new MatchBuilder();
        MatchUtils.createSrcL3Ipv4MatchWithMac(matchBuilder, new Ipv4Prefix(srcIp),new MacAddress(attachedMac));
        MatchUtils.createInPortMatch(matchBuilder, dpidLong, localPort);
        LOG.debug("egressAclAllowTrafficFromVmIpMacPair: MatchBuilder contains: {}", matchBuilder);
        String flowName = "Egress_Allow_VM_IP_MAC" + "_" + localPort + attachedMac + "_Permit_";
        FlowBuilder flowBuilder = FlowUtils.createFlowBuilder(flowName, priority, matchBuilder, getTable());
        addPipelineInstruction(flowBuilder, null, false);
        NodeBuilder nodeBuilder = FlowUtils.createNodeBuilder(dpidLong);
        syncFlow(flowBuilder ,nodeBuilder, write);
    }

    /**
     * Adds rule to check legitimate ip/mac pair for each packet from the vm.
     *
     * @param dpidLong the dpid
     * @param localPort the local port
     * @param srcIp the vm ip address
     * @param attachedMac the vm mac address
     * @param priority  the priority
     * @param write is write or delete
     */
    private void egressAclAllowTrafficFromVmIpV6MacPair(Long dpidLong, long localPort,
                                                        String attachedMac, String srcIp,
                                                        Integer priority, boolean write) {
        MatchBuilder matchBuilder = new MatchBuilder();
        MatchUtils.createSrcL3Ipv6MatchWithMac(matchBuilder, new Ipv6Prefix(srcIp),new MacAddress(attachedMac));
        MatchUtils.createInPortMatch(matchBuilder, dpidLong, localPort);
        LOG.debug("egressAclAllowTrafficFromVmIpMacPair: MatchBuilder contains: {}", matchBuilder);
        String flowName = "Egress_Allow_VM_IPv6_MAC" + "_" + localPort + attachedMac + "_Permit_";
        FlowBuilder flowBuilder = FlowUtils.createFlowBuilder(flowName, priority, matchBuilder, getTable());
        addPipelineInstruction(flowBuilder, null, false);
        NodeBuilder nodeBuilder = FlowUtils.createNodeBuilder(dpidLong);
        syncFlow(flowBuilder ,nodeBuilder, write);
    }

    private void addConntrackMatch(MatchBuilder matchBuilder, int state, int mask) {
        if (securityServicesManager.isConntrackEnabled()) {
            MatchUtils.addCtState(matchBuilder, state, mask );
        }

    }

    private FlowBuilder addInstructionWithConntrackCommit( FlowBuilder flowBuilder , boolean isDrop) {
        InstructionBuilder instructionBuilder = null;
        if (securityServicesManager.isConntrackEnabled()) {
            Action conntrackAction = ActionUtils.nxConntrackAction(1, 0L, 0, (short)0xff);
            instructionBuilder = InstructionUtils
                    .createInstructionBuilder(ActionUtils.conntrackActionBuilder(conntrackAction), 1, false);
        }
        return addPipelineInstruction(flowBuilder,instructionBuilder, isDrop);
    }
    private FlowBuilder addInstructionWithLearnConntrackCommit(NeutronSecurityRule portSecurityRule, FlowBuilder flowBuilder, String icmpType, String icmpCode) {
        InstructionBuilder instructionBuilder = null;
        short learnTableId=getTable(Service.ACL_LEARN_SERVICE);
        short resubmitId=getTable(Service.LOAD_BALANCER);
        if (securityServicesManager.isConntrackEnabled()) {
            Action conntrackAction = ActionUtils.nxConntrackAction(1, 0L, 0, (short)0xff);
            instructionBuilder = InstructionUtils
                    .createInstructionBuilder(ActionUtils.conntrackActionBuilder(conntrackAction), 1, false);
            return addPipelineInstruction(flowBuilder,instructionBuilder, false);
        }
        if (portSecurityRule.getSecurityRuleProtocol().equalsIgnoreCase(MatchUtils.TCP) || portSecurityRule.getSecurityRuleProtocol().equalsIgnoreCase(MatchUtils.TCP_PROTOCOL)) {
            return EgressAclLearnServiceUtil.programEgressAclLearnRuleForTcp(flowBuilder,instructionBuilder,learnTableId,resubmitId);
        } else if (portSecurityRule.getSecurityRuleProtocol().equalsIgnoreCase(MatchUtils.UDP)  || portSecurityRule.getSecurityRuleProtocol().equalsIgnoreCase(MatchUtils.UDP_PROTOCOL)) {
            return EgressAclLearnServiceUtil.programEgressAclLearnRuleForUdp(flowBuilder,instructionBuilder,learnTableId,resubmitId);
        } else if (portSecurityRule.getSecurityRuleProtocol().equalsIgnoreCase(MatchUtils.ICMP)  || portSecurityRule.getSecurityRuleProtocol().equalsIgnoreCase(MatchUtils.ICMP_PROTOCOL)) {
            return EgressAclLearnServiceUtil.programEgressAclLearnRuleForIcmp(flowBuilder,instructionBuilder, icmpType, icmpCode,learnTableId,resubmitId);
        }
        return flowBuilder;
    }

    private FlowBuilder addInstructionWithConntrackRecirc( FlowBuilder flowBuilder) {
        InstructionBuilder instructionBuilder = null;
        if (securityServicesManager.isConntrackEnabled()) {
            Action conntrackAction = ActionUtils.nxConntrackAction(0, 0L, 0, (short)0x0);

            instructionBuilder = InstructionUtils
                    .createInstructionBuilder(ActionUtils.conntrackActionBuilder(conntrackAction), 1, false);
            List<Instruction> instructionsList = Lists.newArrayList();
            instructionsList.add(instructionBuilder.build());
            InstructionsBuilder isb = new InstructionsBuilder();
            isb.setInstruction(instructionsList);
            flowBuilder.setInstructions(isb.build());
        }
        return flowBuilder;
    }

    private FlowBuilder addPipelineInstruction( FlowBuilder flowBuilder ,
                                                InstructionBuilder instructionBuilder,boolean isDrop) {
        InstructionBuilder pipeLineIndstructionBuilder = createPipleLineInstructionBuilder(isDrop);
        List<Instruction> instructionsList = Lists.newArrayList();
        instructionsList.add(pipeLineIndstructionBuilder.build());
        if (null != instructionBuilder) {
            instructionsList.add(instructionBuilder.build());
        }
        InstructionsBuilder isb = new InstructionsBuilder();
        isb.setInstruction(instructionsList);
        flowBuilder.setInstructions(isb.build());
        return flowBuilder;
    }

    private InstructionBuilder createPipleLineInstructionBuilder(boolean drop) {
        InstructionBuilder ib = this.getMutablePipelineInstructionBuilder();
        if (drop) {
            InstructionUtils.createDropInstructions(ib);
        }
        ib.setOrder(0);
        List<Instruction> instructionsList = Lists.newArrayList();
        ib.setKey(new InstructionKey(0));
        instructionsList.add(ib.build());
        return ib;
    }
    /**
     * Add or remove flow to the node.
     * @param flowBuilder the flow builder
     * @param nodeBuilder the node builder
     * @param write whether it is a write
     */
    private void syncFlow(FlowBuilder flowBuilder, NodeBuilder nodeBuilder,
                          boolean write) {
        if (write) {
            writeFlow(flowBuilder, nodeBuilder);
        } else {
            removeFlow(flowBuilder, nodeBuilder);
        }
    }

    private List<NeutronSecurityRule> getSecurityRulesforGroup(NeutronSecurityGroup securityGroup) {
        List<NeutronSecurityRule> securityRules = new ArrayList<>();
        List<NeutronSecurityRule> rules = neutronSecurityRule.getAllNeutronSecurityRules();
        for (NeutronSecurityRule securityRule : rules) {
            if (securityGroup.getID().equals(securityRule.getSecurityRuleGroupID())) {
                securityRules.add(securityRule);
            }
        }
        return securityRules;
    }

    @Override
    public void setDependencies(BundleContext bundleContext, ServiceReference serviceReference) {
        super.setDependencies(bundleContext.getServiceReference(EgressAclProvider.class.getName()), this);
        securityServicesManager =
                (SecurityServicesManager) ServiceHelper.getGlobalInstance(SecurityServicesManager.class, this);
        securityGroupCacheManger =
                (SecurityGroupCacheManger) ServiceHelper.getGlobalInstance(SecurityGroupCacheManger.class, this);
        neutronSecurityRule = (INeutronSecurityRuleCRUD) ServiceHelper.getGlobalInstance(INeutronSecurityRuleCRUD.class, this);
    }

    @Override
    public void setDependencies(Object impl) {}
}
