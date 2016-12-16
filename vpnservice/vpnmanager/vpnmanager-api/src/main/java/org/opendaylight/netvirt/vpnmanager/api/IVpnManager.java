/*
 * Copyright (c) 2015 - 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.vpnmanager.api;

import java.math.BigInteger;
import java.util.Collection;
import java.util.List;

import org.opendaylight.controller.md.sal.binding.api.WriteTransaction;
import org.opendaylight.netvirt.fibmanager.api.IFibManager;
import org.opendaylight.netvirt.fibmanager.api.RouteOrigin;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;

public interface IVpnManager {
    void setFibManager(IFibManager fibManager);
    void addExtraRoute(String destination, String nextHop, String rd, String routerID, int label, RouteOrigin origin);
    void delExtraRoute(String destination, String nextHop, String rd, String routerID);

    /**
     * Returns true if the specified VPN exists
     *
     * @param vpnName it must match against the vpn-instance-name attrib in one of the VpnInstances
     *
     * @return
     */
    boolean existsVpn(String vpnName);
    boolean isVPNConfigured();

    long getArpCacheTimeoutMillis();
    /**
     * Retrieves the list of DPNs where the specified VPN has footprint
     *
     * @param vpnInstanceName The name of the Vpn instance
     * @return The list of DPNs
     */
    List<BigInteger> getDpnsOnVpn(String vpnInstanceName);

    /**
     * Updates the footprint that a VPN has on a given DPN by adding/removing
     * the specified interface
     *
     * @param dpId DPN where the VPN interface belongs to
     * @param vpnName Name of the VPN whose footprint is being modified
     * @param interfaceName Name of the VPN interface to be added/removed
     *          to/from the specified DPN
     * @param add true for addition, false for removal
     */
    void updateVpnFootprint(BigInteger dpId, String vpnName, String interfaceName, boolean add);

    void setupSubnetMacIntoVpnInstance(String vpnName, String srcMacAddress,
            BigInteger dpnId, WriteTransaction writeTx, int addOrRemove);

    void setupRouterGwMacFlow(String routerName, String routerGwMac, BigInteger dpnId, Uuid extNetworkId,
            WriteTransaction writeTx, int addOrRemove);

    void setupArpResponderFlowsToExternalNetworkIps(String id, Collection<String> fixedIps, String macAddress,
            BigInteger dpnId, Uuid extNetworkId, WriteTransaction writeTx, int addOrRemove);

    void setupArpResponderFlowsToExternalNetworkIps(String id, Collection<String> fixedIps, String routerGwMac,
            BigInteger dpnId, long vpnId, String extInterfaceName, int lPortTag, WriteTransaction writeTx,
            int addOrRemove);

}
