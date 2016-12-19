/*
 * Copyright (c) 2015 - 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.cloudservicechain.api;


public interface ICloudServiceChain {


    /**
     * Creates/removes the flows that send the packets from a VPN to the SCF
     * domain. These flows are programmed in all DPNs where the VPN has
     * footprint.
     *
     * @param vpnName Vpn instance name, typically the UUID
     * @param tableId Id of the SCF pipeline to where LPortDispatcher must send
     *           the packet. Typically it should by Uplink or Downlink Dynamic
     *           Subs Filter
     * @param scfTag ServiceChainForwarding Tag
     * @param lportTag LportTag of the VPN Pseudo Logical Port
     * @param addOrRemove states if pipeline must be created or removed
     */
    void programVpnToScfPipeline(String vpnName, short tableId, long scfTag, int lportTag, int addOrRemove);


    /**
     * Creates/removes the flows that handover packets from SCF pipeline to a
     * specific VPN. This happens when there is a ScHop with an egressPort that
     * is the VpnPseudoLPort.
     *
     * @param vpnName Vpn instance name, typically the UUID
     * @param scfTag ServiceChainForwarding Tag
     * @param servChainTag Service Chain Tag
     * @param dpnId DPN where the ingress Port of the ScHop is located
     * @param lportTag Lport tag of the VpnPseudoPort
     * @param isLastServiceChain Only considered in removal operations. States
     *            if there are no more ServiceChains using the VPNPseudoPort as
     *            egress port.
     * @param addOrRemove States if the flows must be added or removed
     */
    void programScfToVpnPipeline(String vpnName, long scfTag, int servChainTag, long dpnId, int lportTag,
                                 boolean isLastServiceChain, int addOrRemove);

    /**
     * Removes all Flow entries (LFIB + LPortDispatcher) that are related to a
     * given VpnPseudoLport.
     *
     * @param vpnInstanceName Name of the VPN, typically its UUID
     * @param vpnPseudoLportTag Lport tag of the VpnPseudoPort
     */
    void removeVpnPseudoPortFlows(String vpnInstanceName, int vpnPseudoLportTag);



    /**
     * Programs the needed flows for sending traffic to the SCF pipeline when
     * it is coming from an L2-GW (ELAN) and also for handing over that
     * traffic from SCF to ELAN when the packets does not match any Service
     * Chain.
     *
     * @param elanName Elan instance name, typically the UUID. Needed to
     *     retrieve the VNI and the elanTag.
     * @param scfTag ServiceChainForwarding Tag
     * @param elanLportTag LPortTag of the Elan Pseudo Port
     * @param isLastServiceChain Only considered in removal operations. States
     *     if there are no more ServiceChains using the ElanPseudoPort as
     *     ingress port.
     * @param addOrRemove States if the flows must be added or removed
     */
    void programElanScfPipeline(String elanName, short tableId, long scfTag, int elanLportTag,
                                boolean isLastServiceChain, int addOrRemove);

    // TODO: To be removed when sdnc is changed so that it calls the following API instead:
    void programElanScfPipeline(String elanName, short tableId, int scfTag, int elanLportTag, int addOrRemove);


    /**
     * Removes all Flow entries (ExtTunnelTable + LPortDispatcher) that are
     * related to a given ElanPseudoLport.
     *
     * @param elanName Name of the Elan Instance
     * @param elanPseudoLportTag Lport tag of the ElanPseudoPort
     */
    void removeElanPseudoPortFlows(String elanName, int elanPseudoLportTag);
}
