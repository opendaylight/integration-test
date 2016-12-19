/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.neutronvpn;

import com.google.common.collect.ImmutableBiMap;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.datastoreutils.AsyncDataTreeChangeListenerBase;
import org.opendaylight.genius.mdsalutil.MDSALUtil;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.access.control.list.rev160218.AccessLists;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.access.control.list.rev160218.access.lists.Acl;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.access.control.list.rev160218.access.lists.AclKey;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.access.control.list.rev160218.access.lists.acl.AccessListEntries;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.access.control.list.rev160218.access.lists.acl.access.list.entries.Ace;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.access.control.list.rev160218.access.lists.acl.access.list.entries.AceBuilder;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.access.control.list.rev160218.access.lists.acl.access.list.entries.AceKey;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.access.control.list.rev160218.access.lists.acl.access.list.entries.ace.ActionsBuilder;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.access.control.list.rev160218.access.lists.acl.access.list.entries.ace.MatchesBuilder;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.access.control.list.rev160218.access.lists.acl.access.list.entries.ace.actions.packet.handling.PermitBuilder;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.access.control.list.rev160218.access.lists.acl.access.list.entries.ace.matches.ace.type.AceIpBuilder;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.access.control.list.rev160218.access.lists.acl.access.list.entries.ace.matches.ace.type.ace.ip.ace.ip.version.AceIpv4Builder;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.access.control.list.rev160218.access.lists.acl.access.list.entries.ace.matches.ace.type.ace.ip.ace.ip.version.AceIpv6Builder;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.Ipv4Prefix;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.Ipv6Prefix;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.PortNumber;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.packet.fields.rev160218.acl.transport.header.fields.DestinationPortRangeBuilder;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.packet.fields.rev160218.acl.transport.header.fields.SourcePortRangeBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.aclservice.rev160608.SecurityRuleAttr;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.aclservice.rev160608.SecurityRuleAttrBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.constants.rev150712.DirectionBase;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.constants.rev150712.DirectionEgress;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.constants.rev150712.DirectionIngress;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.constants.rev150712.ProtocolBase;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.constants.rev150712.ProtocolIcmp;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.constants.rev150712.ProtocolIcmpV6;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.constants.rev150712.ProtocolTcp;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.constants.rev150712.ProtocolUdp;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.rev150712.Neutron;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.secgroups.rev150712.SecurityRuleAttributes;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.secgroups.rev150712.security.rules.attributes.SecurityRules;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.secgroups.rev150712.security.rules.attributes.security.rules.SecurityRule;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class NeutronSecurityRuleListener
        extends AsyncDataTreeChangeListenerBase<SecurityRule, NeutronSecurityRuleListener> {
    private static final Logger LOG = LoggerFactory.getLogger(NeutronSecurityRuleListener.class);
    private final DataBroker dataBroker;
    private static final ImmutableBiMap<Class<? extends DirectionBase>, Class<? extends org.opendaylight.yang.gen.
            v1.urn.opendaylight.netvirt.aclservice.rev160608.DirectionBase>> DIRECTION_MAP = ImmutableBiMap.of(
            DirectionEgress.class, NeutronSecurityRuleConstants.DIRECTION_EGRESS,
            DirectionIngress.class, NeutronSecurityRuleConstants.DIRECTION_INGRESS);
    private static final ImmutableBiMap<Class<? extends ProtocolBase>, Short> PROTOCOL_MAP = ImmutableBiMap.of(
            ProtocolIcmp.class, NeutronSecurityRuleConstants.PROTOCOL_ICMP,
            ProtocolTcp.class, NeutronSecurityRuleConstants.PROTOCOL_TCP,
            ProtocolUdp.class, NeutronSecurityRuleConstants.PROTOCOL_UDP,
            ProtocolIcmpV6.class, NeutronSecurityRuleConstants.PROTOCOL_ICMPV6);

    public NeutronSecurityRuleListener(final DataBroker dataBroker) {
        super(SecurityRule.class, NeutronSecurityRuleListener.class);
        this.dataBroker = dataBroker;
    }

    public void start() {
        LOG.info("{} start", getClass().getSimpleName());
        registerListener(LogicalDatastoreType.CONFIGURATION, dataBroker);
    }

    @Override
    protected InstanceIdentifier<SecurityRule> getWildCardPath() {
        return InstanceIdentifier.create(Neutron.class).child(SecurityRules.class).child(SecurityRule.class);
    }

    @Override
    protected void add(InstanceIdentifier<SecurityRule> instanceIdentifier, SecurityRule securityRule) {
        LOG.trace("added securityRule: {}", securityRule);
        try {
            Ace ace = toAceBuilder(securityRule).build();
            InstanceIdentifier<Ace> identifier = getAceInstanceIdentifier(securityRule);
            MDSALUtil.syncWrite(dataBroker, LogicalDatastoreType.CONFIGURATION, identifier, ace);
        } catch (Exception ex) {
            LOG.error("Exception occured while adding acl for security rule: ", ex);
        }
    }

    private InstanceIdentifier<Ace> getAceInstanceIdentifier(SecurityRule securityRule) {
        return InstanceIdentifier
                .builder(AccessLists.class)
                .child(Acl.class,
                        new AclKey(securityRule.getSecurityGroupId().getValue(), NeutronSecurityRuleConstants.ACLTYPE))
                .child(AccessListEntries.class)
                .child(Ace.class,
                        new AceKey(securityRule.getUuid().getValue()))
                .build();
    }

    private AceBuilder toAceBuilder(SecurityRule securityRule) {
        AceIpBuilder aceIpBuilder = new AceIpBuilder();
        SecurityRuleAttrBuilder securityRuleAttrBuilder = new SecurityRuleAttrBuilder();
        SourcePortRangeBuilder sourcePortRangeBuilder = new SourcePortRangeBuilder();
        DestinationPortRangeBuilder destinationPortRangeBuilder = new DestinationPortRangeBuilder();
        boolean isDirectionIngress = false;
        if (securityRule.getDirection() != null) {
            securityRuleAttrBuilder.setDirection(DIRECTION_MAP.get(securityRule.getDirection()));
            isDirectionIngress = securityRule.getDirection().equals(DirectionIngress.class);
        }
        if (securityRule.getPortRangeMax() != null) {
            destinationPortRangeBuilder.setUpperPort(new PortNumber(securityRule.getPortRangeMax()));

        }
        if (securityRule.getPortRangeMin() != null) {
            destinationPortRangeBuilder.setLowerPort(new PortNumber(securityRule.getPortRangeMin()));
            // set destination port range if lower port is specified as it is mandatory parameter in acl model
            aceIpBuilder.setDestinationPortRange(destinationPortRangeBuilder.build());
        }
        aceIpBuilder = handleRemoteIpPrefix(securityRule, aceIpBuilder, isDirectionIngress);
        if (securityRule.getRemoteGroupId() != null) {
            securityRuleAttrBuilder.setRemoteGroupId(securityRule.getRemoteGroupId());
        }
        if (securityRule.getProtocol() != null) {
            SecurityRuleAttributes.Protocol protocol = securityRule.getProtocol();
            if (protocol.getUint8() != null) {
                // uint8
                aceIpBuilder.setProtocol(protocol.getUint8());
            } else {
                // symbolic protocol name
                aceIpBuilder.setProtocol(PROTOCOL_MAP.get(protocol.getIdentityref()));
            }
        }

        MatchesBuilder matchesBuilder = new MatchesBuilder();
        matchesBuilder.setAceType(aceIpBuilder.build());
        // set acl action as permit for the security rule
        ActionsBuilder actionsBuilder = new ActionsBuilder();
        actionsBuilder.setPacketHandling(new PermitBuilder().setPermit(true).build());

        AceBuilder aceBuilder = new AceBuilder();
        aceBuilder.setKey(new AceKey(securityRule.getUuid().getValue()));
        aceBuilder.setRuleName(securityRule.getUuid().getValue());
        aceBuilder.setMatches(matchesBuilder.build());
        aceBuilder.setActions(actionsBuilder.build());
        aceBuilder.addAugmentation(SecurityRuleAttr.class, securityRuleAttrBuilder.build());
        return aceBuilder;
    }

    private AceIpBuilder handleEtherType(SecurityRule securityRule, AceIpBuilder aceIpBuilder) {
        if (NeutronSecurityRuleConstants.ETHERTYPE_IPV4.equals(securityRule.getEthertype())) {
            AceIpv4Builder aceIpv4Builder = new AceIpv4Builder();
            aceIpv4Builder.setSourceIpv4Network(new Ipv4Prefix(
                NeutronSecurityRuleConstants.IPV4_ALL_NETWORK));
            aceIpv4Builder.setDestinationIpv4Network(new Ipv4Prefix(
                NeutronSecurityRuleConstants.IPV4_ALL_NETWORK));
            aceIpBuilder.setAceIpVersion(aceIpv4Builder.build());
        } else {
            AceIpv6Builder aceIpv6Builder = new AceIpv6Builder();
            aceIpv6Builder.setSourceIpv6Network(new Ipv6Prefix(
                NeutronSecurityRuleConstants.IPV6_ALL_NETWORK));
            aceIpv6Builder.setDestinationIpv6Network(new Ipv6Prefix(
                NeutronSecurityRuleConstants.IPV6_ALL_NETWORK));
            aceIpBuilder.setAceIpVersion(aceIpv6Builder.build());

        }
        return aceIpBuilder;
    }

    private AceIpBuilder handleRemoteIpPrefix(SecurityRule securityRule, AceIpBuilder aceIpBuilder,
                                              boolean isDirectionIngress) {
        if (securityRule.getRemoteIpPrefix() != null) {
            if (securityRule.getRemoteIpPrefix().getIpv4Prefix() != null) {
                AceIpv4Builder aceIpv4Builder = new AceIpv4Builder();
                if (isDirectionIngress) {
                    aceIpv4Builder.setSourceIpv4Network(new Ipv4Prefix(securityRule
                        .getRemoteIpPrefix().getIpv4Prefix().getValue()));
                } else {
                    aceIpv4Builder.setDestinationIpv4Network(new Ipv4Prefix(securityRule
                        .getRemoteIpPrefix().getIpv4Prefix().getValue()));
                }
                aceIpBuilder.setAceIpVersion(aceIpv4Builder.build());
            } else {
                AceIpv6Builder aceIpv6Builder = new AceIpv6Builder();
                if (isDirectionIngress) {
                    aceIpv6Builder.setSourceIpv6Network(new Ipv6Prefix(
                        securityRule.getRemoteIpPrefix().getIpv6Prefix().getValue()));
                } else {
                    aceIpv6Builder.setDestinationIpv6Network(new Ipv6Prefix(
                        securityRule.getRemoteIpPrefix().getIpv6Prefix().getValue()));
                }
                aceIpBuilder.setAceIpVersion(aceIpv6Builder.build());
            }
        } else {
            if (securityRule.getEthertype() != null) {
                handleEtherType( securityRule, aceIpBuilder);
            }
        }

        return aceIpBuilder;
    }

    @Override
    protected void remove(InstanceIdentifier<SecurityRule> instanceIdentifier, SecurityRule securityRule) {
        LOG.trace("removed securityRule: {}", securityRule);
        try {
            InstanceIdentifier<Ace> identifier = getAceInstanceIdentifier(securityRule);
            MDSALUtil.syncDelete(dataBroker, LogicalDatastoreType.CONFIGURATION, identifier);
        } catch (Exception ex) {
            LOG.error("Exception occured while removing acl for security rule: ", ex);
        }
    }

    @Override
    protected void update(InstanceIdentifier<SecurityRule> instanceIdentifier, SecurityRule oldSecurityRule, SecurityRule updatedSecurityRule) {
        // security rule updation is not supported from openstack, so no need to handle update.
        LOG.trace("updates on security rules not supported.");
    }

    @Override
    protected NeutronSecurityRuleListener getDataTreeChangeListener() {
        return this;
    }
}
