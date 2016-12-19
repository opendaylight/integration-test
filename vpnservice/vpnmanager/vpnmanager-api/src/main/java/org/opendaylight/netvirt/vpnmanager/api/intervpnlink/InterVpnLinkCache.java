/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others. All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.vpnmanager.api.intervpnlink;

import java.util.Collections;
import java.util.List;
import java.util.concurrent.ConcurrentHashMap;

import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.utils.cache.CacheUtil;
import org.opendaylight.genius.mdsalutil.MDSALUtil;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.netvirt.inter.vpn.link.rev160311.InterVpnLinkStates;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.netvirt.inter.vpn.link.rev160311.InterVpnLinks;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.netvirt.inter.vpn.link.rev160311.inter.vpn.link.states.InterVpnLinkState;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.netvirt.inter.vpn.link.rev160311.inter.vpn.links.InterVpnLink;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.google.common.base.Optional;

/**
 * Manages some utility caches in order to speed (avoid) reads from MD-SAL.
 * InterVpnLink is something that rarely changes and is frequently queried.
 *
 *
 */
public class InterVpnLinkCache {

    // Cache that maps endpoints with their respective InterVpnLinkComposite
    public static final String ENDPOINT_2_IVPNLINK_CACHE_NAME = "EndpointToInterVpnLinkCache";

    // Cache that maps Vpn UUIDs with their respective InterVpnLinkComposite
    public static final String UUID_2_IVPNLINK_CACHE_NAME = "UuidToInterVpnLinkCache";

    // It maps InterVpnLink names with their corresponding InterVpnLinkComposite.
    public static final String IVPNLINK_NAME_2_IVPNLINK_CACHE_NAME = "NameToInterVpnLinkCache";

    private static final Logger LOG = LoggerFactory.getLogger(InterVpnLinkCache.class);

    ///////////////////////////////////
    //  Initialization / Destruction  //
    ///////////////////////////////////

    public static synchronized void createInterVpnLinkCaches(DataBroker dataBroker) {
        boolean emptyCaches = true;
        if (CacheUtil.getCache(ENDPOINT_2_IVPNLINK_CACHE_NAME) == null) {
            CacheUtil.createCache(ENDPOINT_2_IVPNLINK_CACHE_NAME);
        } else {
            emptyCaches = false;
        }

        if (CacheUtil.getCache(UUID_2_IVPNLINK_CACHE_NAME) == null) {
            CacheUtil.createCache(UUID_2_IVPNLINK_CACHE_NAME);
        } else {
            emptyCaches = false;
        }

        if (CacheUtil.getCache(IVPNLINK_NAME_2_IVPNLINK_CACHE_NAME) == null) {
            CacheUtil.createCache(IVPNLINK_NAME_2_IVPNLINK_CACHE_NAME);
        } else {
            emptyCaches = false;
        }

        if ( emptyCaches ) {
            initialFeed(dataBroker);
        }
    }

    public static synchronized void destroyCaches() {
        if (CacheUtil.getCache(ENDPOINT_2_IVPNLINK_CACHE_NAME) != null) {
            CacheUtil.destroyCache(ENDPOINT_2_IVPNLINK_CACHE_NAME);
        }

        if (CacheUtil.getCache(UUID_2_IVPNLINK_CACHE_NAME) != null) {
            CacheUtil.destroyCache(UUID_2_IVPNLINK_CACHE_NAME);
        }

        if (CacheUtil.getCache(IVPNLINK_NAME_2_IVPNLINK_CACHE_NAME) != null) {
            CacheUtil.destroyCache(IVPNLINK_NAME_2_IVPNLINK_CACHE_NAME);
        }
    }

    /////////////////////
    //      feeding    //
    /////////////////////

    private static void initialFeed(DataBroker broker) {
        // Read all InterVpnLinks and InterVpnLinkStates from MD-SAL.
        InstanceIdentifier<InterVpnLinks> interVpnLinksIid = InstanceIdentifier.builder(InterVpnLinks.class).build();

        Optional<InterVpnLinks> optIVpnLinksOpData =
            MDSALUtil.read(broker, LogicalDatastoreType.CONFIGURATION, interVpnLinksIid);

        if ( !optIVpnLinksOpData.isPresent() ) {
            return; // Nothing to be added to cache
        }
        InterVpnLinks interVpnLinks = optIVpnLinksOpData.get();
        for ( InterVpnLink iVpnLink : interVpnLinks.getInterVpnLink() ) {
            addInterVpnLinkToCaches(iVpnLink);
        }

        // Now the States
        InstanceIdentifier<InterVpnLinkStates> interVpnLinkStateIid =
            InstanceIdentifier.builder(InterVpnLinkStates.class).build();

        Optional<InterVpnLinkStates> optIVpnLinkStateOpData =
            MDSALUtil.read(broker, LogicalDatastoreType.CONFIGURATION, interVpnLinkStateIid);
        if ( !optIVpnLinkStateOpData.isPresent() ) {
            return;
        }
        InterVpnLinkStates iVpnLinkStates = optIVpnLinkStateOpData.get();
        for ( InterVpnLinkState iVpnLinkState : iVpnLinkStates.getInterVpnLinkState() ) {
            addInterVpnLinkStateToCaches(iVpnLinkState);
        }
    }

    public static void addInterVpnLinkToCaches(InterVpnLink iVpnLink) {

        LOG.debug("Adding InterVpnLink {} with vpn1=[id={} endpoint={}] and vpn2=[id={}  endpoint={}] ]",
                  iVpnLink.getName(), iVpnLink.getFirstEndpoint().getVpnUuid(),
                  iVpnLink.getFirstEndpoint().getIpAddress(), iVpnLink.getSecondEndpoint().getVpnUuid(),
                  iVpnLink.getSecondEndpoint().getIpAddress());

        InterVpnLinkDataComposite iVpnLinkComposite;

        Optional<InterVpnLinkDataComposite> optIVpnLinkComposite =
            getInterVpnLinkByName(iVpnLink.getName());

        if ( optIVpnLinkComposite.isPresent() ) {
            iVpnLinkComposite = optIVpnLinkComposite.get();
            iVpnLinkComposite.setInterVpnLinkConfig(iVpnLink);
        } else {
            iVpnLinkComposite = new InterVpnLinkDataComposite(iVpnLink);
            addToIVpnLinkNameCache(iVpnLinkComposite);
        }

        addToEndpointCache(iVpnLinkComposite);
        addToVpnUuidCache(iVpnLinkComposite);
    }


    public static void addInterVpnLinkStateToCaches(InterVpnLinkState iVpnLinkState) {

        LOG.debug("Adding InterVpnLinkState {} with vpn1=[{}]  and vpn2=[{}]",
                  iVpnLinkState.getInterVpnLinkName(), iVpnLinkState.getFirstEndpointState(),
                  iVpnLinkState.getSecondEndpointState());

        Optional<InterVpnLinkDataComposite> optIVpnLink = getInterVpnLinkByName(iVpnLinkState.getInterVpnLinkName());

        InterVpnLinkDataComposite iVpnLink;
        if ( optIVpnLink.isPresent() ) {
            iVpnLink = optIVpnLink.get();
            iVpnLink.setInterVpnLinkState(iVpnLinkState);
        } else {
            iVpnLink = new InterVpnLinkDataComposite(iVpnLinkState);
            addToIVpnLinkNameCache(iVpnLink);
        }

        addToEndpointCache(iVpnLink);
        addToVpnUuidCache(iVpnLink);
    }

    private static void addToEndpointCache(InterVpnLinkDataComposite iVpnLink) {
        ConcurrentHashMap<String, InterVpnLinkDataComposite> cache =
            (ConcurrentHashMap<String, InterVpnLinkDataComposite>) CacheUtil.getCache(ENDPOINT_2_IVPNLINK_CACHE_NAME);
        if ( cache == null ) {
            LOG.warn("Cache {} is not ready", ENDPOINT_2_IVPNLINK_CACHE_NAME);
            return;
        }
        if ( iVpnLink.getFirstEndpointIpAddr().isPresent() ) {
            cache.put(iVpnLink.getFirstEndpointIpAddr().get(), iVpnLink);
        }
        if ( iVpnLink.getSecondEndpointIpAddr().isPresent() ) {
            cache.put(iVpnLink.getSecondEndpointIpAddr().get(), iVpnLink);
        }
    }

    private static void addToVpnUuidCache(InterVpnLinkDataComposite iVpnLink) {
        ConcurrentHashMap<String, InterVpnLinkDataComposite> cache =
            (ConcurrentHashMap<String, InterVpnLinkDataComposite>) CacheUtil.getCache(UUID_2_IVPNLINK_CACHE_NAME);
        if ( cache == null ) {
            LOG.warn("Cache {} is not ready", UUID_2_IVPNLINK_CACHE_NAME);
            return;
        }
        if ( iVpnLink.getFirstEndpointVpnUuid().isPresent() ) {
            cache.put(iVpnLink.getFirstEndpointVpnUuid().get(), iVpnLink);
        }
        if ( iVpnLink.getSecondEndpointVpnUuid().isPresent() ) {
            cache.put(iVpnLink.getSecondEndpointVpnUuid().get(), iVpnLink);
        }
    }

    private static void addToIVpnLinkNameCache(InterVpnLinkDataComposite iVpnLink) {
        ConcurrentHashMap<String, InterVpnLinkDataComposite> cache =
            (ConcurrentHashMap<String, InterVpnLinkDataComposite>) CacheUtil.getCache(IVPNLINK_NAME_2_IVPNLINK_CACHE_NAME);
        if ( cache == null ) {
            LOG.warn("Cache {} is not ready", IVPNLINK_NAME_2_IVPNLINK_CACHE_NAME);
            return;
        }
        cache.put(iVpnLink.getInterVpnLinkName(), iVpnLink);
        if ( iVpnLink.getSecondEndpointIpAddr().isPresent() ) {
            cache.put(iVpnLink.getSecondEndpointIpAddr().get(), iVpnLink);
        }
    }

    public static void removeInterVpnLinkFromCache(InterVpnLink iVpnLink) {
        ConcurrentHashMap<String, InterVpnLink> cache =
            (ConcurrentHashMap<String, InterVpnLink>) CacheUtil.getCache(ENDPOINT_2_IVPNLINK_CACHE_NAME);
        if ( cache != null ) {
            cache.remove(iVpnLink.getFirstEndpoint().getIpAddress().getValue());
            cache.remove(iVpnLink.getSecondEndpoint().getIpAddress().getValue());
        } else {
            LOG.warn("Cache {} is not ready", ENDPOINT_2_IVPNLINK_CACHE_NAME);
        }

        ConcurrentHashMap<String, InterVpnLink> cache2 =
            (ConcurrentHashMap<String, InterVpnLink>) CacheUtil.getCache(UUID_2_IVPNLINK_CACHE_NAME);
        if ( cache2 != null ) {
            cache2.remove(iVpnLink.getFirstEndpoint().getVpnUuid().getValue());
            cache2.remove(iVpnLink.getSecondEndpoint().getVpnUuid().getValue());
        } else {
            LOG.warn("Cache {} is not ready", UUID_2_IVPNLINK_CACHE_NAME);
        }
    }


    public static void removeInterVpnLinkStateFromCache(InterVpnLinkState iVpnLinkState) {
        Optional<InterVpnLinkDataComposite> optIVpnLinkComposite =
            getInterVpnLinkByName(iVpnLinkState.getInterVpnLinkName());

        if ( optIVpnLinkComposite.isPresent() ) {
            InterVpnLinkDataComposite iVpnLinkComposite = optIVpnLinkComposite.get();
            removeFromEndpointIpAddressCache(iVpnLinkComposite);
            removeFromVpnUuidCache(iVpnLinkComposite);
            removeFromInterVpnLinkNameCache(iVpnLinkComposite);
        }
    }

    private static void removeFromInterVpnLinkNameCache(InterVpnLinkDataComposite iVpnLinkComposite) {
        ConcurrentHashMap<String, InterVpnLinkDataComposite> cache =
            (ConcurrentHashMap<String, InterVpnLinkDataComposite>) CacheUtil.getCache(IVPNLINK_NAME_2_IVPNLINK_CACHE_NAME);
        if ( cache != null ) {
            cache.remove(iVpnLinkComposite.getInterVpnLinkName());
        } else {
            LOG.warn("removeFromInterVpnLinkNameCache: Cache {} is not ready", IVPNLINK_NAME_2_IVPNLINK_CACHE_NAME);
        }
    }


    private static void removeFromVpnUuidCache(InterVpnLinkDataComposite iVpnLinkComposite) {
        ConcurrentHashMap<String, InterVpnLink> cache =
            (ConcurrentHashMap<String, InterVpnLink>) CacheUtil.getCache(UUID_2_IVPNLINK_CACHE_NAME);
        if ( cache == null ) {
            LOG.warn("removeFromVpnUuidCache: Cache {} is not ready", UUID_2_IVPNLINK_CACHE_NAME);
            return;
        }
        Optional<String> opt1stEndpointUuid = iVpnLinkComposite.getFirstEndpointVpnUuid();
        if ( opt1stEndpointUuid.isPresent() ) {
            cache.remove(opt1stEndpointUuid.get());
        }
        Optional<String> opt2ndEndpointUuid = iVpnLinkComposite.getSecondEndpointVpnUuid();
        cache.remove(opt2ndEndpointUuid.get());
    }


    private static void removeFromEndpointIpAddressCache(InterVpnLinkDataComposite iVpnLinkComposite) {
        ConcurrentHashMap<String, InterVpnLink> cache =
            (ConcurrentHashMap<String, InterVpnLink>) CacheUtil.getCache(ENDPOINT_2_IVPNLINK_CACHE_NAME);
        if ( cache == null ) {
            LOG.warn("removeFromVpnUuidCache: Cache {} is not ready", ENDPOINT_2_IVPNLINK_CACHE_NAME);
            return;
        }
        Optional<String> opt1stEndpointIpAddr = iVpnLinkComposite.getFirstEndpointIpAddr();
        if ( opt1stEndpointIpAddr.isPresent() ) {
            cache.remove(opt1stEndpointIpAddr.get());
        }
        Optional<String> opt2ndEndpointIpAddr = iVpnLinkComposite.getSecondEndpointIpAddr();
        cache.remove(opt2ndEndpointIpAddr.get());
    }


    /////////////////////
    //  Cache Usage    //
    /////////////////////

    public static Optional<InterVpnLinkDataComposite> getInterVpnLinkByName(String iVpnLinkName) {
        ConcurrentHashMap<String, InterVpnLinkDataComposite> cache =
            (ConcurrentHashMap<String, InterVpnLinkDataComposite>) CacheUtil.getCache(IVPNLINK_NAME_2_IVPNLINK_CACHE_NAME);
        return (cache == null) ? Optional.<InterVpnLinkDataComposite>absent()
                               : Optional.fromNullable(cache.get(iVpnLinkName));
    }

    public static Optional<InterVpnLinkDataComposite> getInterVpnLinkByEndpoint(String endpointIp) {
        LOG.trace("Checking if {} is configured as an InterVpnLink endpoint", endpointIp);
        ConcurrentHashMap<String, InterVpnLinkDataComposite> cache =
            (ConcurrentHashMap<String, InterVpnLinkDataComposite>) CacheUtil.getCache(ENDPOINT_2_IVPNLINK_CACHE_NAME);
        return (cache == null) ? Optional.<InterVpnLinkDataComposite>absent()
                               : Optional.fromNullable(cache.get(endpointIp));
    }

    public static Optional<InterVpnLinkDataComposite> getInterVpnLinkByVpnId(String vpnId) {
        ConcurrentHashMap<String, InterVpnLinkDataComposite> cache =
            (ConcurrentHashMap<String, InterVpnLinkDataComposite>) CacheUtil.getCache(UUID_2_IVPNLINK_CACHE_NAME);
        return (cache == null) ? Optional.<InterVpnLinkDataComposite>absent() : Optional.fromNullable(cache.get(vpnId));
    }

    public static List<InterVpnLinkDataComposite> getAllInterVpnLinks() {
        ConcurrentHashMap<String, InterVpnLinkDataComposite> cache =
            (ConcurrentHashMap<String, InterVpnLinkDataComposite>) CacheUtil.getCache(UUID_2_IVPNLINK_CACHE_NAME);
        return (cache == null) ? Collections.<InterVpnLinkDataComposite>emptyList()
                               : Collections.list(cache.elements());
    }

}
