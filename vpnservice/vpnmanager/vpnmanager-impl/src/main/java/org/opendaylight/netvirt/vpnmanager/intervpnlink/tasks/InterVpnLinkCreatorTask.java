/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others. All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.vpnmanager.intervpnlink.tasks;

import com.google.common.util.concurrent.ListenableFuture;
import java.util.ArrayList;
import java.util.List;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.WriteTransaction;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.datastoreutils.AbstractDataStoreJob;
import org.opendaylight.genius.datastoreutils.InvalidJobException;
import org.opendaylight.netvirt.vpnmanager.intervpnlink.InterVpnLinkUtil;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.netvirt.inter.vpn.link.rev160311.inter.vpn.links.InterVpnLink;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class InterVpnLinkCreatorTask extends AbstractDataStoreJob {

    private static final Logger LOG = LoggerFactory.getLogger(InterVpnLinkCreatorTask.class);

    private final DataBroker dataBroker;
    private final InterVpnLink iVpnLinkToPersist;
    private final String jobKey;

    public InterVpnLinkCreatorTask(DataBroker dataBroker, InterVpnLink iVpnLink, String specificJobKey) {
        this.dataBroker = dataBroker;
        this.iVpnLinkToPersist = iVpnLink;
        this.jobKey = specificJobKey;
    }

    public InterVpnLinkCreatorTask(DataBroker dataBroker, InterVpnLink iVpnLink) {
        this(dataBroker, iVpnLink, "IVpnLink.creation." + iVpnLink.getName());
    }

    @Override
    public List<ListenableFuture<Void>> call() throws Exception {
        LOG.debug("Persisting InterVpnLink {} with 1stEndpoint=[ vpn={}, ipAddr={} ] and 2ndEndpoint=[ vpn={}, ipAddr={} ]",
                  iVpnLinkToPersist.getName(), iVpnLinkToPersist.getFirstEndpoint().getVpnUuid(),
                  iVpnLinkToPersist.getFirstEndpoint().getIpAddress(),
                  iVpnLinkToPersist.getSecondEndpoint().getVpnUuid(),
                  iVpnLinkToPersist.getSecondEndpoint().getIpAddress() );

        List<ListenableFuture<Void>> result = new ArrayList<>();

        WriteTransaction writeTx = dataBroker.newWriteOnlyTransaction();
        writeTx.merge(LogicalDatastoreType.CONFIGURATION,
                      InterVpnLinkUtil.getInterVpnLinkPath(iVpnLinkToPersist.getName()),
                      iVpnLinkToPersist,
                      true /* create missing parents */);
        result.add(writeTx.submit());
        return result;
    }

    @Override
    public String getJobQueueKey() {
        return this.jobKey;
    }

    @Override
    public void validate() throws InvalidJobException {

    }

}
