/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.neutronvpn.interfaces;

import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.IpAddress;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.networks.rev150712.networks.attributes.networks.Network;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.ports.attributes.ports.Port;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.subnets.rev150712.subnets.attributes.subnets.Subnet;

import java.util.Collection;
import java.util.List;

public interface INeutronVpnManager {

    void addSubnetToVpn(Uuid vpnId, Uuid subnet);

    void removeSubnetFromVpn(Uuid vpnId, Uuid subnet);

    List<Uuid> getSubnetsforVpn(Uuid vpnid);

    List<String> showVpnConfigCLI(Uuid vuuid);

    List<String> showNeutronPortsCLI();

    Network getNeutronNetwork(Uuid networkId);

    Port getNeutronPort(String name);

    Subnet getNeutronSubnet(Uuid subnetId);

    Port getNeutronPort(Uuid portId);

    IpAddress getNeutronSubnetGateway(Uuid subnetId);

    String getVifPortName(Port port);

    Collection<Uuid> getSubnetIdsForGatewayIp(IpAddress ipAddress);

}

