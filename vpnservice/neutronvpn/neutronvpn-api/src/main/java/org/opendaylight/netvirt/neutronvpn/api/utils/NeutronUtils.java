/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.neutronvpn.api.utils;

import java.util.List;

import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.binding.rev150712.PortBindingExtension;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.networks.rev150712.NetworkTypeBase;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.networks.rev150712.networks.attributes.networks.Network;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.ports.attributes.ports.Port;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.provider.ext.rev150712.NetworkProviderExtension;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.provider.ext.rev150712.neutron.networks.network.Segments;

public class NeutronUtils {
    public static final String VNIC_TYPE_NORMAL = "normal";

    public static boolean isPortVnicTypeNormal(Port port) {
        PortBindingExtension portBinding = port.getAugmentation(PortBindingExtension.class);
        if (portBinding == null || portBinding.getVnicType() == null) {
            // By default, VNIC_TYPE is NORMAL
            return true;
        }
        String vnicType = portBinding.getVnicType().trim().toLowerCase();
        return vnicType.equals(VNIC_TYPE_NORMAL);
    }

    public static String getSegmentationIdFromNeutronNetwork(Network network) {
        String segmentationId = null;
        NetworkProviderExtension providerExtension = network.getAugmentation(NetworkProviderExtension.class);
        if (providerExtension != null) {
            Class<? extends NetworkTypeBase> networkType = providerExtension.getNetworkType();
            segmentationId = getSegmentationIdFromNeutronNetwork(network, networkType);
        }

        return segmentationId;
    }

    public static <T extends NetworkTypeBase> String getSegmentationIdFromNeutronNetwork(Network network,
            Class<T> networkType) {
        String segmentationId = null;
        NetworkProviderExtension providerExtension = network.getAugmentation(NetworkProviderExtension.class);
        if (providerExtension != null) {
            segmentationId = providerExtension.getSegmentationId();
            if (segmentationId == null) {
                List<Segments> providerSegments = providerExtension.getSegments();
                if (providerSegments != null && providerSegments.size() > 0) {
                    for (Segments providerSegment: providerSegments) {
                        if (isNetworkSegmentType(providerSegment, networkType)) {
                            segmentationId = providerSegment.getSegmentationId();
                            break;
                        }
                    }
                }
            }
        }
        return segmentationId;
    }

    static <T extends NetworkTypeBase> boolean isNetworkSegmentType(Segments providerSegment,
            Class<T> expectedNetworkType) {
        Class<? extends NetworkTypeBase> networkType = providerSegment.getNetworkType();
        return (networkType != null && networkType.isAssignableFrom(expectedNetworkType));
    }
}
