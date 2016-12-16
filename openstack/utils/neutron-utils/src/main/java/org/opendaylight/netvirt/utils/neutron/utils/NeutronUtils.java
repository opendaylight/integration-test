/*
 * Copyright © 2016 Red Hat, Inc. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.utils.neutron.utils;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;

import org.opendaylight.netvirt.openstack.netvirt.translator.NeutronNetwork;
import org.opendaylight.netvirt.openstack.netvirt.translator.NeutronPort;
import org.opendaylight.netvirt.openstack.netvirt.translator.NeutronSecurityGroup;
import org.opendaylight.netvirt.openstack.netvirt.translator.NeutronSecurityRule;
import org.opendaylight.netvirt.openstack.netvirt.translator.NeutronSubnet;
import org.opendaylight.netvirt.openstack.netvirt.translator.crud.INeutronNetworkCRUD;
import org.opendaylight.netvirt.openstack.netvirt.translator.crud.INeutronPortCRUD;
import org.opendaylight.netvirt.openstack.netvirt.translator.crud.INeutronSecurityGroupCRUD;
import org.opendaylight.netvirt.openstack.netvirt.translator.crud.INeutronSecurityRuleCRUD;
import org.opendaylight.netvirt.openstack.netvirt.translator.crud.INeutronSubnetCRUD;
import org.opendaylight.netvirt.utils.servicehelper.ServiceHelper;

public class NeutronUtils {
    public NeutronPort createNeutronPort(String networkId, String subnetId,
                                         String id, String owner, String ipaddr, String mac, NeutronSecurityGroup... secGroups) {
        INeutronPortCRUD iNeutronPortCRUD =
                (INeutronPortCRUD) ServiceHelper.getGlobalInstance(INeutronPortCRUD.class, this);
        NeutronPort np = new NeutronPort();
        np.initDefaults();
        np.setID(id);
        np.setDeviceOwner(owner);
        np.setMacAddress(mac);
        np.setNetworkUUID(networkId);
        List<org.opendaylight.netvirt.openstack.netvirt.translator.Neutron_IPs> srcAddressList =
                new ArrayList<>();
        org.opendaylight.netvirt.openstack.netvirt.translator.Neutron_IPs nip = new org.opendaylight.netvirt.openstack.netvirt.translator.Neutron_IPs();
        nip.setIpAddress(ipaddr);
        nip.setSubnetUUID(subnetId);
        srcAddressList.add(nip);
        np.setFixedIPs(srcAddressList);
        List<NeutronSecurityGroup> nsgs = Arrays.asList(secGroups);
        np.setSecurityGroups(nsgs);
        iNeutronPortCRUD.addPort(np);
        return np;
    }

    public boolean removeNeutronPort(String uuid) {
        INeutronPortCRUD iNeutronPortCRUD =
                (INeutronPortCRUD) ServiceHelper.getGlobalInstance(INeutronPortCRUD.class, this);
        return iNeutronPortCRUD.removePort(uuid);
    }

    public NeutronSubnet createNeutronSubnet(String subnetId, String tenantId,
                                              String networkId, String cidr) {
        INeutronSubnetCRUD iNeutronSubnetCRUD =
                (INeutronSubnetCRUD) ServiceHelper.getGlobalInstance(INeutronSubnetCRUD.class, this);
        NeutronSubnet ns = new NeutronSubnet();
        ns.setID(subnetId);
        ns.setCidr(cidr);
        ns.initDefaults();
        ns.setNetworkUUID(networkId);
        ns.setTenantID(tenantId);
        iNeutronSubnetCRUD.addSubnet(ns);
        return ns;
    }

    public boolean removeNeutronSubnet(String uuid) {
        INeutronSubnetCRUD iNeutronSubnetCRUD =
                (INeutronSubnetCRUD) ServiceHelper.getGlobalInstance(INeutronSubnetCRUD.class, this);
        return iNeutronSubnetCRUD.removeSubnet(uuid);
    }

    public NeutronNetwork createNeutronNetwork(String uuid, String tenantID, String networkTypeVxlan, String segId) {
        INeutronNetworkCRUD iNeutronNetworkCRUD =
                (INeutronNetworkCRUD) ServiceHelper.getGlobalInstance(INeutronNetworkCRUD.class, this);
        NeutronNetwork nn = new NeutronNetwork();
        nn.setID(uuid);
        nn.initDefaults();
        nn.setTenantID(tenantID);
        nn.setProviderNetworkType(networkTypeVxlan);
        nn.setProviderSegmentationID(segId);
        iNeutronNetworkCRUD.addNetwork(nn);
        return nn;
    }

    public boolean removeNeutronNetwork(String uuid) {
        INeutronNetworkCRUD iNeutronNetworkCRUD =
                (INeutronNetworkCRUD) ServiceHelper.getGlobalInstance(INeutronNetworkCRUD.class, this);
        return iNeutronNetworkCRUD.removeNetwork(uuid);

    }

    /**
     * Build a NeutronSecurityRule that can be passed in to createNeutronSecurityGroup.
     * @param direction e.g., "ingress". May be null.
     * @param ethertype e.g., "IPv4". May be null.
     * @param protocol e.g., "TCP". May be null.
     * @param ipPrefix e.g., "10.9.8.0/24". May be null.
     * @param portMin or null
     * @param portMax or null
     * @return A new NeutronSecurityRule
     */
    public NeutronSecurityRule buildNeutronSecurityRule(String direction, String ethertype, String protocol,
                                                         String ipPrefix, Integer portMin, Integer portMax) {
        NeutronSecurityRule rule = new NeutronSecurityRule();
        rule.setID(UUID.randomUUID().toString());
        rule.setSecurityRemoteGroupID(null);
        rule.setSecurityRuleDirection(direction);
        rule.setSecurityRuleEthertype(ethertype);
        rule.setSecurityRuleProtocol(protocol);
        rule.setSecurityRuleRemoteIpPrefix(ipPrefix);
        rule.setSecurityRulePortMin(portMin);
        rule.setSecurityRulePortMax(portMax);

        return rule;
    }

    /**
     * Create a new NeutronSecurityGroup and create the NeutronSecurityRules passed in. This method will first create
     * teh NeutronSecurityRules and then the NeutronSecurityGroup in md-sal.
     * @param tenantId The tenant ID for both the rules and groups
     * @param rules NeutronSecurityRules. You can create them with buildNeutronSecurityRule.
     * @return A new NeutronSecurityGroup
     */
    public NeutronSecurityGroup createNeutronSecurityGroup(String tenantId, NeutronSecurityRule... rules) {
        INeutronSecurityGroupCRUD groupCRUD =
                (INeutronSecurityGroupCRUD) ServiceHelper.getGlobalInstance(INeutronSecurityGroupCRUD.class, this);
        INeutronSecurityRuleCRUD ruleCRUD =
                (INeutronSecurityRuleCRUD) ServiceHelper.getGlobalInstance(INeutronSecurityRuleCRUD.class, this);

        String id = UUID.randomUUID().toString();
        NeutronSecurityGroup sg = new NeutronSecurityGroup();
        sg.setSecurityGroupName("SG-" + id);
        sg.setID(id);
        sg.setSecurityGroupTenantID(tenantId);

        List<NeutronSecurityRule> ruleList = new ArrayList<>(rules.length);
        for (NeutronSecurityRule rule : rules) {
            rule.setSecurityRuleTenantID(tenantId);
            rule.setSecurityRuleGroupID(id);
            ruleList.add(rule);
            ruleCRUD.addNeutronSecurityRule(rule);
        }

        groupCRUD.addNeutronSecurityGroup(sg);

        return sg;
    }

    /**
     * Remove the NeutronSecurityGroup and its associated NeutronSecurityRules from md-sal
     * @param sg NeutronSecurityGroup to remove
     */
    public void removeNeutronSecurityGroupAndRules(NeutronSecurityGroup sg) {
        INeutronSecurityGroupCRUD groupCRUD =
                (INeutronSecurityGroupCRUD) ServiceHelper.getGlobalInstance(INeutronSecurityGroupCRUD.class, this);

        groupCRUD.removeNeutronSecurityGroup(sg.getID());
    }

    /**
     * Get the NeutronSecurityRule and its associated NeutronSecurityGroup
     * @param sg NeutronSecurityGroup to to get the rules for
     * @return List of NeutronSecurityRule
     */
    public List<NeutronSecurityRule>  getNeutronSecurityGroupRules(NeutronSecurityGroup sg) {
        INeutronSecurityRuleCRUD ruleCRUD =
                (INeutronSecurityRuleCRUD) ServiceHelper.getGlobalInstance(INeutronSecurityRuleCRUD.class, this);

        List<NeutronSecurityRule> rules = new ArrayList<>();
        List<NeutronSecurityRule> securityRules = ruleCRUD.getAllNeutronSecurityRules();
        for (NeutronSecurityRule securityRule : securityRules) {
            if (sg.getID().equals(securityRule.getSecurityRuleGroupID())) {
                rules.add(securityRule);
            }
        }
        return rules;
    }
}
