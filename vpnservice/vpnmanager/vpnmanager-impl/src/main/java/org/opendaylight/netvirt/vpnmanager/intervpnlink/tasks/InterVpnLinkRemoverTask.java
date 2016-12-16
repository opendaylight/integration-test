/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others. All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.vpnmanager.intervpnlink.tasks;

import com.google.common.util.concurrent.CheckedFuture;
import com.google.common.util.concurrent.ListenableFuture;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.Callable;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.WriteTransaction;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.controller.md.sal.common.api.data.TransactionCommitFailedException;
import org.opendaylight.genius.datastoreutils.AbstractDataStoreJob;
import org.opendaylight.genius.datastoreutils.InvalidJobException;
import org.opendaylight.genius.mdsalutil.MDSALUtil;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.netvirt.inter.vpn.link.rev160311.inter.vpn.links.InterVpnLink;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class InterVpnLinkRemoverTask extends AbstractDataStoreJob {

    private static final Logger LOG = LoggerFactory.getLogger(InterVpnLinkRemoverTask.class);

    private final InstanceIdentifier<InterVpnLink> iVpnLinkIid;
    private final String iVpnLinkName;
    private final String jobKey;
    private final DataBroker dataBroker;

    public InterVpnLinkRemoverTask(DataBroker dataBroker, InstanceIdentifier<InterVpnLink> iVpnLinkPath) {
        this(dataBroker, iVpnLinkPath, "REMOVE.INTERVPNLINK." + iVpnLinkPath.firstKeyOf(InterVpnLink.class).getName());
    }

    public InterVpnLinkRemoverTask(DataBroker dataBroker, InstanceIdentifier<InterVpnLink> iVpnLinkPath,
                                   String specificJobKey) {
        this.iVpnLinkIid = iVpnLinkPath;
        this.iVpnLinkName = iVpnLinkPath.firstKeyOf(InterVpnLink.class).getName();
        this.jobKey = specificJobKey;
        this.dataBroker = dataBroker;
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
        LOG.debug("Removing InterVpnLink {} from storage", iVpnLinkName);
        List<ListenableFuture<Void>> result = new ArrayList<>();
        WriteTransaction removeTx = dataBroker.newWriteOnlyTransaction();
        removeTx.delete(LogicalDatastoreType.CONFIGURATION, this.iVpnLinkIid);
        CheckedFuture<Void, TransactionCommitFailedException> removalFuture = removeTx.submit();
        result.add(removalFuture);
        return result;
    }

}
