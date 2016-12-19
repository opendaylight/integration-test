/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others. All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.vpnmanager.api.intervpnlink;

import com.google.common.base.Optional;
import java.math.BigInteger;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.netvirt.inter.vpn.link.rev160311.inter.vpn.link.states.InterVpnLinkState;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.netvirt.inter.vpn.link.rev160311.inter.vpn.link.states.InterVpnLinkState.State;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.netvirt.inter.vpn.link.rev160311.inter.vpn.links.InterVpnLink;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * It holds all info about an InterVpnLink, combining both configurational
 * and stateful.
 */
public class InterVpnLinkDataComposite {

    private static final Logger LOG = LoggerFactory.getLogger(InterVpnLinkDataComposite.class);

    private InterVpnLink interVpnLinkCfg;
    private InterVpnLinkState interVpnLinkState;

    public InterVpnLinkDataComposite(InterVpnLink interVpnLink) {
        this.interVpnLinkCfg = interVpnLink;
    }

    public InterVpnLinkDataComposite(InterVpnLinkState interVpnLinkState) {
        this.interVpnLinkState = interVpnLinkState;
    }

    public InterVpnLinkDataComposite(InterVpnLink interVpnLink, InterVpnLinkState interVpnLinkState) {
        this.interVpnLinkCfg = interVpnLink;
        this.interVpnLinkState = interVpnLinkState;
    }

    public InterVpnLink getInterVpnLinkConfig() {
        return this.interVpnLinkCfg;
    }

    public void setInterVpnLinkConfig(InterVpnLink interVpnLink) {
        this.interVpnLinkCfg = interVpnLink;
    }

    public InterVpnLinkState getInterVpnLinkState() {
        return this.interVpnLinkState;
    }

    public void setInterVpnLinkState(InterVpnLinkState interVpnLinkState) {
        this.interVpnLinkState = interVpnLinkState;
    }

    public boolean isComplete() {
        return interVpnLinkCfg != null && interVpnLinkState != null
                 && interVpnLinkState.getFirstEndpointState() != null
                 && interVpnLinkState.getSecondEndpointState() != null;
    }

    public Optional<InterVpnLinkState.State> getState() {
        return this.interVpnLinkState == null ? Optional.absent()
                                              : Optional.fromNullable(this.interVpnLinkState.getState());
    }

    public boolean isActive() {
        return isComplete() && getState().isPresent() && getState().get() == InterVpnLinkState.State.Active;
    }

    public boolean isFirstEndpointVpnName(String vpnName) {
        return interVpnLinkCfg != null
               && interVpnLinkCfg.getFirstEndpoint().getVpnUuid().getValue().equals(vpnName);
    }

    public boolean isSecondEndpointVpnName(String vpnName) {
        return interVpnLinkCfg != null
               && interVpnLinkCfg.getSecondEndpoint().getVpnUuid().getValue().equals(vpnName);
    }

    public boolean isFirstEndpointIpAddr(String endpointIp) {
        return interVpnLinkCfg != null
               && interVpnLinkCfg.getFirstEndpoint().getIpAddress().getValue().equals(endpointIp);
    }

    public boolean isSecondEndpointIpAddr(String endpointIp) {
        return interVpnLinkCfg != null
               && interVpnLinkCfg.getSecondEndpoint().getIpAddress().getValue().equals(endpointIp);
    }

    public boolean isIpAddrTheOtherVpnEndpoint(String ipAddr, String vpnUuid) {
        return (vpnUuid.equals(getFirstEndpointVpnUuid().orNull())
                    && ipAddr.equals(getSecondEndpointIpAddr().orNull()))
               || ( vpnUuid.equals(getSecondEndpointVpnUuid().orNull())
                     && ipAddr.equals(getFirstEndpointIpAddr().orNull() ) );
    }

    public String getInterVpnLinkName() {
        return (interVpnLinkCfg != null) ? interVpnLinkCfg.getName() : interVpnLinkState.getInterVpnLinkName();
    }

    public Optional<String> getFirstEndpointVpnUuid() {
        if ( this.interVpnLinkCfg == null ) {
            return Optional.absent();
        }
        return Optional.of(this.interVpnLinkCfg.getFirstEndpoint().getVpnUuid().getValue());
    }

    public Optional<String> getFirstEndpointIpAddr() {
        if ( this.interVpnLinkCfg == null ) {
            return Optional.absent();
        }
        return Optional.of(this.interVpnLinkCfg.getFirstEndpoint().getIpAddress().getValue());
    }

    public List<BigInteger> getFirstEndpointDpns() {
        return ( !isComplete() || this.interVpnLinkState.getFirstEndpointState().getDpId() == null )
                   ? Collections.<BigInteger>emptyList()
                   : this.interVpnLinkState.getFirstEndpointState().getDpId();
    }

    public Optional<String> getSecondEndpointVpnUuid() {
        if ( !isComplete() ) {
            return Optional.absent();
        }
        return Optional.of(this.interVpnLinkCfg.getSecondEndpoint().getVpnUuid().getValue());
    }

    public Optional<String> getSecondEndpointIpAddr() {
        if ( !isComplete() ) {
            return Optional.absent();
        }
        return Optional.of(this.interVpnLinkCfg.getSecondEndpoint().getIpAddress().getValue());
    }

    public List<BigInteger> getSecondEndpointDpns() {
        return (!isComplete() || this.interVpnLinkState.getSecondEndpointState().getDpId() == null )
                    ? Collections.<BigInteger>emptyList()
                    : this.interVpnLinkState.getSecondEndpointState().getDpId();
    }

    public Optional<Long> getEndpointLportTagByIpAddr(String endpointIp) {
        if ( !isComplete() ) {
            return Optional.absent();
        }

        return isFirstEndpointIpAddr(endpointIp)
                    ? Optional.fromNullable(interVpnLinkState.getFirstEndpointState().getLportTag())
                    : Optional.fromNullable(interVpnLinkState.getSecondEndpointState().getLportTag());
    }

    public Optional<Long> getOtherEndpointLportTagByVpnName(String vpnName) {
        if ( !isComplete() ) {
            return Optional.absent();
        }

        return isFirstEndpointVpnName(vpnName) ? Optional.of(interVpnLinkState.getSecondEndpointState().getLportTag())
                                               : Optional.of(interVpnLinkState.getFirstEndpointState().getLportTag());
    }

    public String getOtherEndpoint(String vpnUuid) {
        if ( !isFirstEndpointVpnName(vpnUuid) && !isSecondEndpointVpnName(vpnUuid)) {
            LOG.debug("VPN {} does not participate in InterVpnLink {}", vpnUuid, getInterVpnLinkName());
            return null;
        }

        Optional<String> optEndpointIpAddr = isFirstEndpointVpnName(vpnUuid) ? getSecondEndpointIpAddr()
                                                                             : getFirstEndpointIpAddr();
        return optEndpointIpAddr.orNull();
    }

    public List<BigInteger> getEndpointDpnsByVpnName(String vpnUuid) {
        if ( !isComplete() ) {
            return new ArrayList<>();
        }

        return isFirstEndpointVpnName(vpnUuid) ? interVpnLinkState.getFirstEndpointState().getDpId()
                                               : interVpnLinkState.getSecondEndpointState().getDpId();
    }

    public List<BigInteger> getOtherEndpointDpnsByVpnName(String vpnUuid) {
        List<BigInteger> result = new ArrayList<>();
        if ( !isComplete() ) {
            return result;
        }

        return isFirstEndpointVpnName(vpnUuid) ? interVpnLinkState.getSecondEndpointState().getDpId()
                                               : interVpnLinkState.getFirstEndpointState().getDpId();
    }

    public List<BigInteger> getEndpointDpnsByIpAddr(String endpointIp) {
        List<BigInteger> result = new ArrayList<>();
        if ( !isComplete()) {
            return result;
        }

        return isFirstEndpointIpAddr(endpointIp) ? this.interVpnLinkState.getFirstEndpointState().getDpId()
                                                 : this.interVpnLinkState.getSecondEndpointState().getDpId();
    }

    public List<BigInteger> getOtherEndpointDpnsByIpAddr(String endpointIp) {
        List<BigInteger> result = new ArrayList<>();
        if ( !isComplete()) {
            return result;
        }

        return isFirstEndpointIpAddr(endpointIp) ? this.interVpnLinkState.getSecondEndpointState().getDpId()
                                                 : this.interVpnLinkState.getFirstEndpointState().getDpId();
    }
}
