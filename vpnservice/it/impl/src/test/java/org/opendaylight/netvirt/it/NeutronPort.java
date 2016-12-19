/*
 * Copyright (c) 2016 Red Hat, Inc. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.it;

import java.util.ArrayList;
import java.util.List;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.netvirt.neutronvpn.api.utils.NeutronConstants;
import org.opendaylight.ovsdb.utils.mdsal.utils.MdsalUtils;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.IpAddress;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.Ipv4Address;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.Ipv6Address;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.MacAddress;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.binding.rev150712.PortBindingExtension;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.binding.rev150712.PortBindingExtensionBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.port.attributes.FixedIps;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.port.attributes.FixedIpsBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.ports.attributes.Ports;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.ports.attributes.ports.Port;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.ports.attributes.ports.PortBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.portsecurity.rev150712.PortSecurityExtension;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.portsecurity.rev150712.PortSecurityExtensionBuilder;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;

public class NeutronPort {
    private final MdsalUtils mdsalUtils;
    private final String networkId;
    private Port port;

    NeutronPort(final MdsalUtils mdsalUtils, final String networkId) {
        this.mdsalUtils = mdsalUtils;
        this.networkId = networkId;
    }

    void createPort(PortInfo portInfo, String owner, String deviceId, boolean portSecurity,
            List<Uuid> securityGroupList) {
        FixedIpsBuilder fib = new FixedIpsBuilder();
        List<FixedIps> fixedIps = new ArrayList<>();
        for (PortInfo.PortIp portIp: portInfo.getPortFixedIps()) {
            IpAddress ipAddress;
            if (NetvirtITConstants.IPV4 == portIp.getIpVersion()) {
                ipAddress = new IpAddress(new Ipv4Address(portIp.getIpAddress()));
            } else {
                ipAddress = new IpAddress(new Ipv6Address(portIp.getIpAddress()));
            }
            fib.setIpAddress(ipAddress);
            fib.setSubnetId(new Uuid(portIp.getSubnetId()));
            fixedIps.add(fib.build());
        }

        PortBindingExtensionBuilder portBindingExtensionBuilder = new PortBindingExtensionBuilder();
        portBindingExtensionBuilder.setVifType(NeutronConstants.VIF_TYPE_OVS);
        portBindingExtensionBuilder.setVnicType(NeutronConstants.VNIC_TYPE_NORMAL);

        // port security
        PortSecurityExtensionBuilder portSecurityBuilder = new PortSecurityExtensionBuilder();
        portSecurityBuilder.setPortSecurityEnabled(portSecurity);

        port = new PortBuilder()
                .addAugmentation(PortSecurityExtension.class, portSecurityBuilder.build())
                .addAugmentation(PortBindingExtension.class, portBindingExtensionBuilder.build())
                .setStatus("ACTIVE")
                .setAdminStateUp(true)
                .setName(portInfo.id)
                .setDeviceOwner(owner)
                .setDeviceId((deviceId != null) ? deviceId : "")
                .setUuid(new Uuid(portInfo.id))
                .setMacAddress(new MacAddress(portInfo.mac))
                .setNetworkId(new Uuid(networkId))
                .setFixedIps(fixedIps)
                .setSecurityGroups(securityGroupList)
                .build();

        mdsalUtils.put(LogicalDatastoreType.CONFIGURATION, InstanceIdentifier
                .create(org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.rev150712.Neutron.class)
                .child(Ports.class).child(Port.class, port.getKey()), port);
    }

    void deletePort() {
        if (port == null) {
            return;
        }

        mdsalUtils.delete(LogicalDatastoreType.CONFIGURATION, InstanceIdentifier
                .create(org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.rev150712.Neutron.class)
                .child(Ports.class).child(Port.class, port.getKey()));
    }
}
