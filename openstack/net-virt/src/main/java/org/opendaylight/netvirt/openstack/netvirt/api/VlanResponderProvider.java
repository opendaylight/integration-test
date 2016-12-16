/*
 * Copyright (c) 2016 NEC Corporation and others. All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.openstack.netvirt.api;

/**
 *  This interface allows Vlan flows to be written to devices
 */
public interface VlanResponderProvider {
    /**
     * Creates flow for OUTPUT instruction.
     * @param dpidLong dp Id
     * @param patchIntPort patch port of internal bridge
     * @param ofPortValue of port value
     * @param macAddress mac address
     * @param write - flag to indicate the operation
     */
    void programProviderNetworkOutput(Long dpidLong, Long patchIntPort, Long ofPortValue, String macAddress, boolean write);

    /**
     * Creates flow for POP Vlan instriction.
     * @param dpidLong dp Id
     * @param segmentationId segmentation id
     * @param patchIntPort patch port of internal bridge
     * @param ofPortValue of port value
     * @param write - flag to indicate the operation
     */
    void programProviderNetworkPopVlan(Long dpidLong, String segmentationId, Long patchIntPort, Long ofPortValue, boolean write);

    /**
     * Creates flow for Push VLAN instruction.
     * @param dpidLong dp Id
     * @param segmentationId Segmentation id
     * @param patchExtPort patch port of external bridge
     * @param macAddress mac address
     * @param write - flag indicate the operation
     */
    void programProviderNetworkPushVlan(Long dpidLong, String segmentationId, Long patchExtPort, String macAddress, boolean write);

    /**
     * Creates flow for Drop instruction.
     * @param dpidLong dp id
     * @param patchExtPort patch port of external bridge
     * @param write - flag indicate the operation
     */
    void programProviderNetworkDrop(Long dpidLong, Long patchExtPort, boolean write);
}
