/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others. All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.vpnmanager.intervpnlink.tasks;

import com.google.common.base.Optional;
import com.google.common.util.concurrent.ListenableFuture;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.concurrent.TimeoutException;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.genius.datastoreutils.AbstractDataStoreJob;
import org.opendaylight.genius.datastoreutils.InvalidJobException;
import org.opendaylight.netvirt.fibmanager.api.RouteOrigin;
import org.opendaylight.netvirt.vpnmanager.VpnUtil;
import org.opendaylight.netvirt.vpnmanager.intervpnlink.InterVpnLinkUtil;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.vrfentries.VrfEntry;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.netvirt.inter.vpn.link.rev160311.inter.vpn.link.states.InterVpnLinkState;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.netvirt.inter.vpn.link.rev160311.inter.vpn.links.InterVpnLink;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * This Task is in charge of checking that all stuff related to a given
 * InterVpnLink has been removed, like the stateful information, leaked
 * vrfEntries, etc.
 *
 */
public class InterVpnLinkCleanedCheckerTask extends AbstractDataStoreJob {

    private static final Logger LOG = LoggerFactory.getLogger(InterVpnLinkCleanedCheckerTask.class);
    protected static final long MAX_WAIT_FOR_REMOVAL = 10000; // 10 seconds

    private final DataBroker dataBroker;
    private final InterVpnLink iVpnLinkToCheck;
    private final String jobKey;
    private final long maxWaitInMillis;

    public InterVpnLinkCleanedCheckerTask(DataBroker dataBroker, InterVpnLink iVpnLink, String specificJobKey,
                                          long maxWaitMs) {
        this.dataBroker = dataBroker;
        this.iVpnLinkToCheck = iVpnLink;
        this.jobKey = specificJobKey;
        this.maxWaitInMillis = maxWaitMs;
    }

    public InterVpnLinkCleanedCheckerTask(DataBroker dataBroker, InterVpnLink iVpnLink, String specificJobKey) {
        this(dataBroker, iVpnLink, specificJobKey, MAX_WAIT_FOR_REMOVAL);
    }

    public InterVpnLinkCleanedCheckerTask(DataBroker dataBroker, InterVpnLink iVpnLink) {
        this(dataBroker, iVpnLink, "IVPNLINK.CLEANED.CHECKER" + iVpnLink.getName(), MAX_WAIT_FOR_REMOVAL);
    }

    @Override
    public String getJobQueueKey() {
        return this.jobKey;
    }

    @Override
    public void validate() throws InvalidJobException {
    }

    @Override
    public List<ListenableFuture<Void>> call() throws Exception {

        LOG.debug("Checking if InterVpnLink {} is fully cleaned. MaxWaitInMillis={}",
                  iVpnLinkToCheck.getName(), maxWaitInMillis);

        // Check that the State has also been deleted
        Optional<InterVpnLinkState> optIVpnLinkState =
            InterVpnLinkUtil.getInterVpnLinkState(dataBroker, iVpnLinkToCheck.getName());
        long t0 = System.currentTimeMillis();
        long elapsedTime = t0;
        while (optIVpnLinkState.isPresent() && (elapsedTime - t0) < maxWaitInMillis ) {
            LOG.debug("InterVpnLink {} State has not yet been removed after {}ms.",
                      iVpnLinkToCheck.getName(), (elapsedTime-t0));
            Thread.sleep(50);
            optIVpnLinkState = InterVpnLinkUtil.getInterVpnLinkState(dataBroker, iVpnLinkToCheck.getName());
            elapsedTime = System.currentTimeMillis();
        }

        if ( optIVpnLinkState.isPresent() ) {
            throw new TimeoutException("InterVpnLink " + iVpnLinkToCheck.getName()
                                       + " has not been completely removed after " + maxWaitInMillis + " ms");
        }

        LOG.debug("InterVpnLink {} State has been removed. Now checking leaked routes", iVpnLinkToCheck.getName());
        String vpn1Rd = VpnUtil.getVpnRd(dataBroker, iVpnLinkToCheck.getFirstEndpoint().getVpnUuid().getValue());
        List<VrfEntry> leakedVrfEntries =
            VpnUtil.getVrfEntriesByOrigin(dataBroker, vpn1Rd, Collections.singletonList(RouteOrigin.INTERVPN));

        while ( !leakedVrfEntries.isEmpty() && (t0 - elapsedTime) < maxWaitInMillis ) {
            leakedVrfEntries = VpnUtil.getVrfEntriesByOrigin(dataBroker, vpn1Rd,
                                                             Collections.singletonList(RouteOrigin.INTERVPN));
            elapsedTime = System.currentTimeMillis();
        }
        if ( !leakedVrfEntries.isEmpty() ) {
            LOG.info("InterVpnLink {} leaked routes have not been removed after {} ms",
                     iVpnLinkToCheck.getName(), maxWaitInMillis);
            throw new TimeoutException("InterVpnLink " + iVpnLinkToCheck.getName()
                                       + " has not been completely removed after " + maxWaitInMillis + " ms");
        }

        LOG.debug("InterVpnLink {} State and leaked routes are now fully removed", iVpnLinkToCheck.getName());

        return new ArrayList<>();
    }

}
