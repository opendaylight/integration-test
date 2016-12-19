/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.cloudservicechain.jobs;

import com.google.common.util.concurrent.ListenableFuture;
import java.util.Collections;
import java.util.List;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.WriteTransaction;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.netvirt.cloudservicechain.utils.VpnServiceChainUtils;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.cloud.servicechain.state.rev170511.vpn.to.pseudo.port.list.VpnToPseudoPortData;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class RemoveVpnPseudoPortDataJob extends VpnPseudoPortDataBaseJob {

    private static final Logger LOG = LoggerFactory.getLogger(AddVpnPseudoPortDataJob.class);

    public RemoveVpnPseudoPortDataJob(DataBroker dataBroker, String vpnRd) {
        super(dataBroker, vpnRd);
    }

    @Override
    public List<ListenableFuture<Void>> call() throws Exception {

        LOG.debug("Removing VpnToPseudoPortMap for vpn with Rd={}", super.vpnRd);

        InstanceIdentifier<VpnToPseudoPortData> path = VpnServiceChainUtils.getVpnToPseudoPortTagIid(vpnRd);

        WriteTransaction writeTxn = dataBroker.newWriteOnlyTransaction();
        if ( writeTxn == null ) {
            throw new Exception("Could not create a proper WriteTransaction");
        }

        LOG.trace("Removing VpnToLportTag entry for VPN with rd={}", super.vpnRd);
        writeTxn.delete(LogicalDatastoreType.CONFIGURATION, path);
        return Collections.singletonList(writeTxn.submit());
    }
}
