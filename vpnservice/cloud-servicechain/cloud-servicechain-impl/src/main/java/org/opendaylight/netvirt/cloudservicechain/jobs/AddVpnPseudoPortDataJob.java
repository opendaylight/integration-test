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
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.cloud.servicechain.state.rev170511.vpn.to.pseudo.port.list.VpnToPseudoPortDataBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.cloud.servicechain.state.rev170511.vpn.to.pseudo.port.list.VpnToPseudoPortDataKey;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class AddVpnPseudoPortDataJob extends VpnPseudoPortDataBaseJob {

    private static final Logger LOG = LoggerFactory.getLogger(AddVpnPseudoPortDataJob.class);

    protected final long vpnPseudoLportTag;
    private final short scfTableIdToGo;
    private final int scfTag;

    public AddVpnPseudoPortDataJob(DataBroker dataBroker, String vpnRd, long vpnPseudoLportTag, short scfTableToGo,
                                   int scfTag) {
        super(dataBroker, vpnRd);

        this.vpnPseudoLportTag = vpnPseudoLportTag;
        this.scfTag = scfTag;
        this.scfTableIdToGo = scfTableToGo;
    }

    @Override
    public List<ListenableFuture<Void>> call() throws Exception {
        LOG.debug("Adding VpnToPseudoPortMap: vpnRd={}  vpnPseudoLportTag={}  scfTag={}  scfTable={}",
                  super.vpnRd, vpnPseudoLportTag, scfTag, scfTableIdToGo);

        WriteTransaction writeTxn = super.dataBroker.newWriteOnlyTransaction();
        if ( writeTxn == null ) {
            throw new Exception("Could not create a proper WriteTransaction");
        }
        VpnToPseudoPortData newValue =
            new VpnToPseudoPortDataBuilder().setKey(new VpnToPseudoPortDataKey(super.vpnRd)).setVrfId(super.vpnRd)
                                            .setScfTableId(scfTableIdToGo).setScfTag(scfTag)
                                            .setVpnLportTag(vpnPseudoLportTag).build();
        LOG.trace("Adding lportTag={} to VpnToLportTag map for VPN with rd={}", vpnPseudoLportTag, vpnRd);
        InstanceIdentifier<VpnToPseudoPortData> path = VpnServiceChainUtils.getVpnToPseudoPortTagIid(vpnRd);
        writeTxn.put(LogicalDatastoreType.CONFIGURATION, path, newValue, true);

        return Collections.singletonList(writeTxn.submit());
    }
}
