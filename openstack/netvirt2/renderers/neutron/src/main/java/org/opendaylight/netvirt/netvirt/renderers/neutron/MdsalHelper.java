/*
 * Copyright (c) 2015 Red Hat Communications Systems, Inc. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.netvirt.renderers.neutron;

import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.devices.rev151227.Devices;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.devices.rev151227.devices.Device;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.devices.rev151227.devices.DeviceKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l2.networks.rev151227.L2Networks;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l2.networks.rev151227.l2.networks.L2Network;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l2.networks.rev151227.l2.networks.L2NetworkKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.ports.rev151227.Ports;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.ports.rev151227.ports.Port;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.ports.rev151227.ports.PortKey;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;

public class MdsalHelper {
    public static InstanceIdentifier<Port> createPortInstanceIdentifier(Uuid portUuid) {
        return InstanceIdentifier.create(Ports.class)
                .child(Port.class, new PortKey(portUuid));
    }

    public static InstanceIdentifier<L2Network> createL2NetworkInstanceIdentifier(Uuid networkUuid) {
        return InstanceIdentifier.create(L2Networks.class)
                .child(L2Network.class, new L2NetworkKey(networkUuid));
    }

    public static InstanceIdentifier<Device> createDeviceInstanceIdentifier(Uuid deviceUuid) {
        return InstanceIdentifier.create(Devices.class)
                .child(Device.class, new DeviceKey(deviceUuid));
    }
}
