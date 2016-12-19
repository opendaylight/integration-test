/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.vpnmanager.intervpnlink;

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.function.Predicate;
import java.util.stream.Collectors;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.genius.mdsalutil.NWUtil;
import org.opendaylight.netvirt.vpnmanager.VpnUtil;
import org.opendaylight.netvirt.vpnmanager.api.intervpnlink.InterVpnLinkCache;
import org.opendaylight.netvirt.vpnmanager.api.intervpnlink.InterVpnLinkDataComposite;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.op.data.VpnInstanceOpDataEntry;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.op.data.vpn.instance.op.data.entry.VpnTargets;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.op.data.vpn.instance.op.data.entry.vpntargets.VpnTarget;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.netvirt.inter.vpn.link.rev160311.inter.vpn.links.InterVpnLink;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class InterVpnLinkService {

    private static final Logger LOG = LoggerFactory.getLogger(InterVpnLinkService.class);
    private static final String NBR_OF_DPNS_PROPERTY_NAME = "vpnservice.intervpnlink.number.dpns";

    private final DataBroker dataBroker;

    public InterVpnLinkService(final DataBroker dataBroker) {
        this.dataBroker = dataBroker;
    }

    /**
     * Retrieves a list of randomly selected DPNs avoiding to select DPNs
     * where there is already an InterVpnLink of the same group (i.e., an
     * InterVpnLink that links similar L3VPNs).
     *
     * @param interVpnLink InterVpnLink to find suitable DPNs for.
     * @return the list of the selected DPN Ids
     */
    public List<BigInteger> selectSuitableDpns(InterVpnLink interVpnLink) {
        int numberOfDpns = Integer.getInteger(NBR_OF_DPNS_PROPERTY_NAME, 1);
        List<BigInteger> dpnIdPool = NWUtil.getOperativeDPNs(dataBroker);
        LOG.trace("selectSuitableDpns for {} with numberOfDpns={} and availableDpns={}",
                  interVpnLink.getName(), numberOfDpns, dpnIdPool);
        int poolSize = dpnIdPool.size();
        if (poolSize <= numberOfDpns) {
            // You requested more than there is, I give you all I have.
            return dpnIdPool;
        }

        List<InterVpnLinkDataComposite> allInterVpnLinks = InterVpnLinkCache.getAllInterVpnLinks();

        // 1st criteria is to select those DPNs where there is no InterVpnLink at all
        List<BigInteger> dpnsWithNoIVL = findDPNsWithNoInterVpnLink(dpnIdPool, allInterVpnLinks);
        if ( dpnsWithNoIVL.size() >= numberOfDpns ) {
            return dpnsWithNoIVL.subList(0, numberOfDpns); // Best case scenario
        }

        // Not enough. 2nd criteria is to avoid DPNs where there are InterVpnLinks of the same group
        List<BigInteger> result = new ArrayList<>(dpnsWithNoIVL);
        dpnIdPool.removeAll(result);
        int pendingDPNs = numberOfDpns - result.size();

        List<BigInteger> dpnsToAvoid = findDpnsWithSimilarIVpnLinks(interVpnLink, allInterVpnLinks);
        result.addAll(dpnIdPool.stream().filter(dpId -> dpnsToAvoid == null || !dpnsToAvoid.contains(dpId))
                               .limit(pendingDPNs).collect(Collectors.toList()));

        int currentNbrOfItems = result.size();
        if (currentNbrOfItems < numberOfDpns) {
            // Still not enough. 3rd criteria: whatever is available
            dpnIdPool.removeAll(result);
            pendingDPNs = numberOfDpns - currentNbrOfItems;
            result.addAll(dpnIdPool.subList(0, Math.max(dpnIdPool.size(), pendingDPNs)));
        }
        return result;
    }

    /*
     * Given a list of Dpn Ids and a list of InterVpnLinks, this method finds
     * the DPNs in the first list where no InterVpnLink is instantiated there.
     *
     * @param dpnList A list of DPN IDs
     * @param interVpnLinks A List of InterVpnLinks to avoid
     *
     * @return the list of available DPNs among the specified ones
     */
    private List<BigInteger> findDPNsWithNoInterVpnLink(List<BigInteger> dpnList,
                                                        List<InterVpnLinkDataComposite> interVpnLinks) {
        List<BigInteger> occupiedDpns = new ArrayList<>();
        for ( InterVpnLinkDataComposite ivl : interVpnLinks ) {
            if ( ivl.isActive() ) {
                occupiedDpns.addAll(ivl.getFirstEndpointDpns());
                occupiedDpns.addAll(ivl.getSecondEndpointDpns());
            }
        }

        List<BigInteger> result = new ArrayList<>(dpnList);
        result.removeAll(occupiedDpns);
        return result;
    }

    /*
     * Given an InterVpnLink, this method finds those DPNs where there is an
     * InterVpnLink of the same group. Two InterVpnLinks are in the same group
     * if they link 2 L3VPNs that are from the same group, and 2 L3VPNs are in
     * the same group if their iRTs match.
     *
     * @param interVpnLink InterVpnLink to be checked
     * @return the list of dpnIds where the specified InterVpnLink should not
     *     be installed
     */
    private List<BigInteger> findDpnsWithSimilarIVpnLinks(InterVpnLink interVpnLink,
                                                          List<InterVpnLinkDataComposite> allInterVpnLinks) {
        List<InterVpnLinkDataComposite> sameGroupInterVpnLinks = findInterVpnLinksSameGroup(interVpnLink,
                                                                                            allInterVpnLinks);
        Set<BigInteger> resultDpns = new HashSet<>();
        for ( InterVpnLinkDataComposite ivl : sameGroupInterVpnLinks ) {
            resultDpns.addAll(ivl.getFirstEndpointDpns());
            resultDpns.addAll(ivl.getSecondEndpointDpns());
        }
        return new ArrayList<>(resultDpns);
    }

    private List<String> getRts(VpnInstanceOpDataEntry vpnInstance, VpnTarget.VrfRTType rtType) {
        String name = vpnInstance.getVpnInstanceName();
        VpnTargets targets = vpnInstance.getVpnTargets();
        if (targets == null) {
            LOG.trace("vpn targets not available for {}", name);
            return new ArrayList<>();
        }
        List<VpnTarget> vpnTargets = targets.getVpnTarget();
        if (vpnTargets == null) {
            LOG.trace("vpnTarget values not available for {}", name);
            return new ArrayList<>();
        }
        return vpnTargets.stream()
                         .filter(target-> target.getVrfRTType().equals(rtType) ||
                                          target.getVrfRTType().equals(VpnTarget.VrfRTType.Both))
                         .map(target-> target.getVrfRTValue())
                         .collect(Collectors.toList());
    }

    private List<String> getIRTsByVpnName(String vpnName) {
        String vpn1Rd = VpnUtil.getVpnRd(dataBroker, vpnName);
        final VpnInstanceOpDataEntry vpnInstance = VpnUtil.getVpnInstanceOpData(dataBroker, vpn1Rd);
        return getRts(vpnInstance, VpnTarget.VrfRTType.ImportExtcommunity);
    }

    private boolean haveSameIRTs(List<String> irts1, List<String> irts2) {
        if ( irts1 == null && irts2 == null ) {
            return true;
        }
        if ( (irts1 == null && irts2 != null) || (irts1 != null && irts2 == null) ) {
            return false;
        }
        if ( irts1.size() != irts2.size() ) {
            return false;
        }
        irts1.sort(/*comparator*/ null);
        irts2.sort(/*comparator*/ null);
        return irts1.equals(irts2);
    }

    public List<InterVpnLinkDataComposite> findInterVpnLinksSameGroup(InterVpnLink ivpnLinkToMatch,
                                                                      List<InterVpnLinkDataComposite> interVpnLinks) {

        List<String> vpnToMatch1IRTs = getIRTsByVpnName(ivpnLinkToMatch.getFirstEndpoint().getVpnUuid().getValue());
        List<String> vpnToMatch2IRTs = getIRTsByVpnName(ivpnLinkToMatch.getSecondEndpoint().getVpnUuid().getValue());

        Predicate<InterVpnLinkDataComposite> areSameGroup = (ivl) -> {
            if ( ivl.getInterVpnLinkName().equals(ivpnLinkToMatch.getName())) {
                return false; // ivl and ivpnLinlToMatch are the same InterVpnLink
            }
            String vpn1Name = ivl.getFirstEndpointVpnUuid().orNull();
            String vpn2Name = ivl.getSecondEndpointVpnUuid().orNull();
            if ( vpn1Name == null ) {
                return false;
            }
            List<String> vpn1IRTs = getIRTsByVpnName(vpn1Name);
            List<String> vpn2IRTs = getIRTsByVpnName(vpn2Name);
            return (haveSameIRTs(vpn1IRTs, vpnToMatch1IRTs) && haveSameIRTs(vpn2IRTs, vpnToMatch2IRTs)
                    || (haveSameIRTs(vpn1IRTs, vpnToMatch2IRTs) && haveSameIRTs(vpn2IRTs, vpnToMatch1IRTs)) );
        };

        return interVpnLinks.stream().filter(areSameGroup).collect(Collectors.toList());
    }

}
