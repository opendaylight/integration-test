/*
 * Copyright (c) 2016 Red Hat, Inc. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.it;

import com.google.common.collect.ImmutableBiMap;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.ovsdb.utils.mdsal.utils.MdsalUtils;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.IpPrefix;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.constants.rev150712.DirectionBase;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.constants.rev150712.DirectionEgress;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.constants.rev150712.DirectionIngress;

import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.secgroups.rev150712.SecurityRuleAttributes.Protocol;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.secgroups.rev150712.security.groups.attributes.security.groups.SecurityGroupBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.secgroups.rev150712.security.rules.attributes.SecurityRules;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.secgroups.rev150712.security.rules.attributes.security.rules.SecurityRule;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.secgroups.rev150712.security.rules.attributes.security.rules.SecurityRuleBuilder;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;

public class NeutronSecurityGroupUtils {
    private final MdsalUtils mdsalUtils;

    private final ImmutableBiMap<String, Class<? extends DirectionBase>> directionMap = ImmutableBiMap.of(
            "egress", DirectionEgress.class,
            "ingress", DirectionIngress.class);
    private Map<Uuid, List<SecurityRule>> securityGroupMap = new HashMap<>();

    public NeutronSecurityGroupUtils(MdsalUtils mdsalUtils) {
        this.mdsalUtils = mdsalUtils;
    }

    public Uuid createDefaultSG()
            throws Exception {
        SecurityGroupBuilder securityGroupBuilder = new SecurityGroupBuilder();

        securityGroupBuilder.setName("DefaultSG");
        securityGroupBuilder.setUuid(new Uuid(generateUuid()));

        String sgUuid = generateUuid();
        syncSg(createIpv4EtherRule(sgUuid, "ingress", null, sgUuid),true);
        syncSg(createIpv4EtherRule(sgUuid, "egress", NetvirtITConstants.PREFIX_ALL_NETWORK, null), true);
        syncSg(createIpv6EtherRule(sgUuid, "ingress", null, sgUuid),true);
        syncSg(createIpv6EtherRule(sgUuid, "egress", NetvirtITConstants.PREFIX_ALL_IPV6_NETWORK, null), true);
        return new Uuid(sgUuid);

    }

    public SecurityRule createIpv4EtherRule(String sgUuid, String direction, String remoteIpPrefix,
            String remoteSgUuid) {

        SecurityRuleBuilder secRule = createCommonAttr(sgUuid, direction, remoteIpPrefix, remoteSgUuid);
        secRule.setDirection(directionMap.get(direction));
        secRule.setEthertype(NetvirtITConstants.ETHER_TYPE_V4);
        secRule.setProtocol(null);
        return secRule.build();
    }

    public SecurityRule createIpv6EtherRule(String sgUuid, String direction, String remoteIpPrefix,
                                            String remoteSgUuid) {

        SecurityRuleBuilder secRule = createCommonAttr(sgUuid, direction, remoteIpPrefix, remoteSgUuid);
        secRule.setDirection(directionMap.get(direction));
        secRule.setEthertype(NetvirtITConstants.ETHER_TYPE_V6);
        secRule.setProtocol(null);
        return secRule.build();
    }

    public void createIpv4TcpRule(String sgUuid, String direction, String remoteIpPrefix, String remoteSgUuid) {

        SecurityRuleBuilder secRule = createCommonAttr(sgUuid, direction, remoteIpPrefix, remoteSgUuid);
        secRule.setDirection(directionMap.get(direction));
        secRule.setEthertype(NetvirtITConstants.ETHER_TYPE_V4);
        secRule.setProtocol(new Protocol(NetvirtITConstants.PROTOCOL_TCP.toCharArray()));
    }

    public void createIpv4UdpRule(String sgUuid, String direction, String remoteIpPrefix, String remoteSgUuid) {

        SecurityRuleBuilder secRule = createCommonAttr(sgUuid, direction, remoteIpPrefix, remoteSgUuid);
        secRule.setDirection(directionMap.get(direction));
        secRule.setEthertype(NetvirtITConstants.ETHER_TYPE_V4);
        secRule.setProtocol(new Protocol(NetvirtITConstants.PROTOCOL_UDP.toCharArray()));
    }

    public void createIpv4IcmpRule(String sgUuid, String direction, String remoteIpPrefix, String remoteSgUuid) {

        SecurityRuleBuilder secRule = createCommonAttr(sgUuid, direction, remoteIpPrefix, remoteSgUuid);
        secRule.setDirection(directionMap.get(direction));
        secRule.setEthertype(NetvirtITConstants.ETHER_TYPE_V4);
        secRule.setProtocol(new Protocol(NetvirtITConstants.PROTOCOL_ICMP.toCharArray()));
    }

    public SecurityRuleBuilder createCommonAttr(String sgUuid, String direction, String remoteIpPrefix,
            String remoteSgUuid) {
        SecurityRuleBuilder secRule = new SecurityRuleBuilder();
        secRule.setSecurityGroupId(new Uuid(sgUuid));
        if (null != remoteSgUuid) {
            secRule.setRemoteGroupId(new Uuid(remoteSgUuid));
        }
        if (null != remoteIpPrefix) {
            secRule.setRemoteIpPrefix(new IpPrefix(remoteIpPrefix.toCharArray()));
        }
        secRule.setUuid(new Uuid(generateUuid()));
        return secRule;
    }

    public String generateUuid() {
        return UUID.randomUUID().toString();
    }

    public void syncSg(SecurityRule securityRule, boolean write) {
        if (write) {
            addToSgMap(securityRule);
            mdsalUtils.put(LogicalDatastoreType.CONFIGURATION, InstanceIdentifier
                    .create(org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.rev150712.Neutron.class)
                    .child(SecurityRules.class).child(SecurityRule.class, securityRule.getKey()), securityRule);
        } else {
            mdsalUtils.delete(LogicalDatastoreType.CONFIGURATION, InstanceIdentifier
                .create(org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.rev150712.Neutron.class)
                .child(SecurityRules.class).child(SecurityRule.class, securityRule.getKey()));
        }
    }

    public void addToSgMap(SecurityRule securityRule) {

        List<SecurityRule> securityRuleList = securityGroupMap.get(securityRule.getSecurityGroupId());
        if (null == securityRuleList) {
            securityRuleList = new ArrayList<>();
        }
        securityRuleList.add(securityRule);
        securityGroupMap.put(securityRule.getSecurityGroupId(), securityRuleList);
    }

    public void deleteFromSgMap(SecurityRule securityRule) {

        securityGroupMap.remove(securityRule.getSecurityGroupId());
    }

}
