/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.elan.internal;

import com.google.common.base.Optional;
import com.google.common.util.concurrent.FutureCallback;
import com.google.common.util.concurrent.Futures;
import com.google.common.util.concurrent.ListenableFuture;
import java.math.BigInteger;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.WriteTransaction;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.interfacemanager.globals.InterfaceInfo;
import org.opendaylight.genius.interfacemanager.interfaces.IInterfaceManager;
import org.opendaylight.genius.mdsalutil.MetaDataUtil;
import org.opendaylight.genius.mdsalutil.NwConstants;
import org.opendaylight.netvirt.elan.utils.ElanUtils;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.PhysAddress;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.service.rev130819.FlowAdded;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.service.rev130819.FlowRemoved;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.service.rev130819.FlowUpdated;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.service.rev130819.NodeErrorNotification;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.service.rev130819.NodeExperimenterErrorNotification;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.service.rev130819.SalFlowListener;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.service.rev130819.SwitchFlowRemoved;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.meta.rev160406._if.indexes._interface.map.IfIndexInterface;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.tag.name.map.ElanTagName;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.forwarding.entries.MacEntry;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@SuppressWarnings("deprecation")
public class ElanSmacFlowEventListener implements SalFlowListener {

    private static final Logger LOG = LoggerFactory.getLogger(ElanSmacFlowEventListener.class);

    private final DataBroker broker;
    private final IInterfaceManager interfaceManager;
    private final ElanUtils elanUtils;

    public ElanSmacFlowEventListener(DataBroker broker, IInterfaceManager interfaceManager, ElanUtils elanUtils) {
        this.broker = broker;
        this.interfaceManager = interfaceManager;
        this.elanUtils = elanUtils;
    }

    @Override
    public void onFlowAdded(FlowAdded arg0) {
        // TODO Auto-generated method stub

    }

    @Override
    public void onFlowRemoved(FlowRemoved flowRemoved) {
        short tableId = flowRemoved.getTableId();
        if (tableId == NwConstants.ELAN_SMAC_TABLE) {
            BigInteger metadata = flowRemoved.getMatch().getMetadata().getMetadata();
            long elanTag = MetaDataUtil.getElanTagFromMetadata(metadata);
            ElanTagName elanTagInfo = elanUtils.getElanInfoByElanTag(elanTag);
            if (elanTagInfo == null) {
                return;
            }
            final String srcMacAddress = flowRemoved.getMatch().getEthernetMatch()
                .getEthernetSource().getAddress().getValue().toUpperCase();
            int portTag = MetaDataUtil.getLportFromMetadata(metadata).intValue();
            if (portTag == 0) {
                LOG.debug(String.format("Flow removed event on SMAC flow entry. But having port Tag as 0 "));
                return;
            }
            Optional<IfIndexInterface> existingInterfaceInfo = elanUtils.getInterfaceInfoByInterfaceTag(portTag);
            if (!existingInterfaceInfo.isPresent()) {
                LOG.debug("Interface is not available for port Tag {}", portTag);
                return;
            }
            String interfaceName = existingInterfaceInfo.get().getInterfaceName();
            PhysAddress physAddress = new PhysAddress(srcMacAddress);
            if (interfaceName == null) {
                LOG.error(String.format("LPort record not found for tag %d", portTag));
                return;
            }
            MacEntry macEntry = elanUtils.getInterfaceMacEntriesOperationalDataPath(interfaceName, physAddress);
            InterfaceInfo interfaceInfo = interfaceManager.getInterfaceInfo(interfaceName);
            if (macEntry != null && interfaceInfo != null) {
                WriteTransaction deleteFlowTx = broker.newWriteOnlyTransaction();
                elanUtils.deleteMacFlows(ElanUtils.getElanInstanceByName(broker, elanTagInfo.getName()), interfaceInfo,
                        macEntry, deleteFlowTx);
                ListenableFuture<Void> result = deleteFlowTx.submit();
                addCallBack(result, srcMacAddress);
            }
            InstanceIdentifier<MacEntry> macEntryIdForElanInterface = ElanUtils
                    .getInterfaceMacEntriesIdentifierOperationalDataPath(interfaceName, physAddress);
            InstanceIdentifier<MacEntry> macEntryIdForElanInstance = ElanUtils
                    .getMacEntryOperationalDataPath(elanTagInfo.getName(), physAddress);
            WriteTransaction tx = broker.newWriteOnlyTransaction();
            tx.delete(LogicalDatastoreType.OPERATIONAL, macEntryIdForElanInterface);
            tx.delete(LogicalDatastoreType.OPERATIONAL, macEntryIdForElanInstance);
            ListenableFuture<Void> writeResult = tx.submit();
            addCallBack(writeResult, srcMacAddress);
        }

    }

    private void addCallBack(ListenableFuture<Void> writeResult, String srcMacAddress) {
        //WRITE Callback
        Futures.addCallback(writeResult, new FutureCallback<Void>() {
            @Override
            public void onSuccess(Void noarg) {
                LOG.debug("Successfully removed macEntry {} from Operational Datastore", srcMacAddress);
            }

            @Override
            public void onFailure(Throwable error) {
                LOG.debug("Error {} while removing macEntry {} from Operational Datastore", error, srcMacAddress);
            }
        });
    }

    @Override
    public void onFlowUpdated(FlowUpdated arg0) {
        // TODO Auto-generated method stub

    }

    @Override
    public void onNodeErrorNotification(NodeErrorNotification arg0) {
        // TODO Auto-generated method stub

    }

    @Override
    public void onNodeExperimenterErrorNotification(NodeExperimenterErrorNotification arg0) {
        // TODO Auto-generated method stub

    }

    @Override
    public void onSwitchFlowRemoved(SwitchFlowRemoved switchFlowRemoved) {

    }


}
