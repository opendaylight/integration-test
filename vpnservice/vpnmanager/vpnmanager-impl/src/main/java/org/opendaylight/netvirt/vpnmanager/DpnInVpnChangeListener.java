/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.vpnmanager;

import java.math.BigInteger;
import java.util.Collection;
import java.util.List;
import java.util.concurrent.ExecutionException;

import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.WriteTransaction;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.controller.md.sal.common.api.data.TransactionCommitFailedException;
import org.opendaylight.genius.mdsalutil.NwConstants;
import org.opendaylight.genius.mdsalutil.interfaces.IMdsalApiManager;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.AddDpnEvent;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.OdlL3vpnListener;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.RemoveDpnEvent;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.add.dpn.event.AddEventData;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.remove.dpn.event.RemoveEventData;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.op.data.VpnInstanceOpDataEntry;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.op.data.vpn.instance.op.data.entry.VpnToDpnList;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.google.common.base.Optional;
import com.google.common.util.concurrent.CheckedFuture;

public class DpnInVpnChangeListener implements OdlL3vpnListener {
    private static final Logger LOG = LoggerFactory.getLogger(DpnInVpnChangeListener.class);
    private final DataBroker dataBroker;
    private final IMdsalApiManager mdsalManager;

    public DpnInVpnChangeListener(DataBroker dataBroker, IMdsalApiManager mdsalManager) {
        this.dataBroker = dataBroker;
        this.mdsalManager = mdsalManager;
    }

    public void onAddDpnEvent(AddDpnEvent notification) {
        AddEventData addEventData = notification.getAddEventData();
        String vpnName = addEventData.getVpnName();
        BigInteger dpId = addEventData.getDpnId();
        setupSubnetGwMacEntriesOnDpn(vpnName, dpId, NwConstants.ADD_FLOW);
    }

    private void setupSubnetGwMacEntriesOnDpn(String vpnName, BigInteger dpId, int addOrRemove) {
        Optional<List<String>> macAddressesOptional = VpnUtil.getAllSubnetGatewayMacAddressesforVpn(dataBroker, vpnName);
        if (!macAddressesOptional.isPresent()) {
            return;
        }
        long vpnId = VpnUtil.getVpnId(dataBroker, vpnName);
        WriteTransaction writeTx = dataBroker.newWriteOnlyTransaction();
        for (String gwMacAddress: macAddressesOptional.get()) {
            VpnUtil.addGwMacIntoTx(mdsalManager, gwMacAddress, writeTx, addOrRemove, vpnId, dpId);
        }
        writeTx.submit();
    }

    public void onRemoveDpnEvent(RemoveDpnEvent notification) {

        RemoveEventData eventData = notification.getRemoveEventData();
        final String rd = eventData.getRd();
        final String vpnName = eventData.getVpnName();
        BigInteger dpnId = eventData.getDpnId();

        LOG.trace("Remove Dpn Event notification received for rd {} VpnName {} DpnId {}", rd , vpnName, dpnId);

        synchronized (vpnName.intern()) {
            InstanceIdentifier<VpnInstanceOpDataEntry> id = VpnUtil.getVpnInstanceOpDataIdentifier(rd);
            Optional<VpnInstanceOpDataEntry> vpnOpValue = VpnUtil.read(dataBroker, LogicalDatastoreType.OPERATIONAL, id);

            if (vpnOpValue.isPresent()) {
                VpnInstanceOpDataEntry vpnInstOpData = vpnOpValue.get();
                List<VpnToDpnList> vpnToDpnList = vpnInstOpData.getVpnToDpnList();
                boolean flushDpnsOnVpn = true;
                for (VpnToDpnList dpn: vpnToDpnList) {
                    if (dpn.getDpnState() == VpnToDpnList.DpnState.Active) {
                        flushDpnsOnVpn = false;
                        break;
                    }
                }
                if (flushDpnsOnVpn) {
                    WriteTransaction writeTxn = dataBroker.newWriteOnlyTransaction();
                    deleteDpn(vpnToDpnList , rd , writeTxn);
                    CheckedFuture<Void, TransactionCommitFailedException> futures = writeTxn.submit();
                    try {
                        futures.get();
                    } catch (InterruptedException | ExecutionException e) {
                        LOG.error("Error removing dpnToVpnList for vpn {} ", vpnName);
                        throw new RuntimeException(e.getMessage());
                    }
                }
            }
        }
        setupSubnetGwMacEntriesOnDpn(vpnName, dpnId, NwConstants.DEL_FLOW);
    }

    protected void deleteDpn(Collection<VpnToDpnList> vpnToDpnList, String rd, WriteTransaction writeTxn) {
        for (final VpnToDpnList curDpn : vpnToDpnList) {
            InstanceIdentifier<VpnToDpnList> VpnToDpnId = VpnUtil.getVpnToDpnListIdentifier(rd, curDpn.getDpnId());
            writeTxn.delete(LogicalDatastoreType.OPERATIONAL, VpnToDpnId);
        }
    }
}

