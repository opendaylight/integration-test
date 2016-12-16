/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.elan.utils;



import com.google.common.base.Optional;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.WriteTransaction;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.interfacemanager.globals.InterfaceInfo;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.PhysAddress;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.instances.ElanInstance;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.forwarding.entries.MacEntry;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.forwarding.entries.MacEntryBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.forwarding.entries.MacEntryKey;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


public class ElanForwardingEntriesHandler {

    private static final Logger LOG = LoggerFactory.getLogger(ElanForwardingEntriesHandler.class);

    private final DataBroker broker;
    private ElanUtils elanUtils;

    public ElanForwardingEntriesHandler(DataBroker dataBroker) {
        this.broker = dataBroker;
    }

    public void setElanUtils(ElanUtils elanUtils) {
        this.elanUtils = elanUtils;
    }

    public void updateElanInterfaceForwardingTablesList(String elanInstanceName, String interfaceName,
            String existingInterfaceName, MacEntry mac, WriteTransaction tx) {
        if (existingInterfaceName.equals(interfaceName)) {
            LOG.error(String.format(
                    "Static MAC address %s has already been added for the same ElanInstance "
                            + "%s on the same Logical Interface Port %s."
                            + " No operation will be done.",
                    mac.getMacAddress().toString(), elanInstanceName, interfaceName));
        } else {
            LOG.warn(String.format(
                    "Static MAC address %s had already been added for ElanInstance %s on Logical Interface Port %s. "
                            + "This would be considered as MAC movement scenario and old static mac will be removed "
                            + "and new static MAC will be added"
                            + "for ElanInstance %s on Logical Interface Port %s",
                    mac.getMacAddress().toString(), elanInstanceName, interfaceName, elanInstanceName, interfaceName));
            //Update the  ElanInterface Forwarding Container & ElanForwarding Container
            deleteElanInterfaceForwardingTablesList(existingInterfaceName, mac, tx);
            createElanInterfaceForwardingTablesList(interfaceName, mac, tx);
            updateElanForwardingTablesList(elanInstanceName, interfaceName, mac, tx);
        }

    }

    public void addElanInterfaceForwardingTableList(ElanInstance elanInstance, String interfaceName,
            PhysAddress physAddress, WriteTransaction tx) {
        MacEntry macEntry = new MacEntryBuilder().setIsStaticAddress(true).setMacAddress(physAddress)
                .setInterface(interfaceName).setKey(new MacEntryKey(physAddress)).build();
        createElanForwardingTablesList(elanInstance.getElanInstanceName(), macEntry, tx);
        createElanInterfaceForwardingTablesList(interfaceName, macEntry, tx);
    }

    public void deleteElanInterfaceForwardingTablesList(String interfaceName, MacEntry mac, WriteTransaction tx) {
        InstanceIdentifier<MacEntry> existingMacEntryId = ElanUtils
                .getInterfaceMacEntriesIdentifierOperationalDataPath(interfaceName, mac.getMacAddress());
        MacEntry existingInterfaceMacEntry = elanUtils
                .getInterfaceMacEntriesOperationalDataPathFromId(existingMacEntryId);
        if (existingInterfaceMacEntry != null) {
            tx.delete(LogicalDatastoreType.OPERATIONAL, existingMacEntryId);
        }
    }

    public void createElanInterfaceForwardingTablesList(String interfaceName, MacEntry mac, WriteTransaction tx) {
        InstanceIdentifier<MacEntry> existingMacEntryId = ElanUtils
                .getInterfaceMacEntriesIdentifierOperationalDataPath(interfaceName, mac.getMacAddress());
        MacEntry existingInterfaceMacEntry = elanUtils
                .getInterfaceMacEntriesOperationalDataPathFromId(existingMacEntryId);
        if (existingInterfaceMacEntry == null) {
            MacEntry macEntry = new MacEntryBuilder().setMacAddress(mac.getMacAddress()).setInterface(interfaceName)
                    .setIsStaticAddress(true).setKey(new MacEntryKey(mac.getMacAddress())).build();
            tx.put(LogicalDatastoreType.OPERATIONAL, existingMacEntryId, macEntry);

        }
    }

    public void updateElanForwardingTablesList(String elanName, String interfaceName, MacEntry mac,
            WriteTransaction tx) {
        InstanceIdentifier<MacEntry> macEntryId = ElanUtils.getMacEntryOperationalDataPath(elanName,
                mac.getMacAddress());
        MacEntry existingMacEntry = elanUtils.getMacEntryFromElanMacId(macEntryId);
        if (existingMacEntry != null) {
            // Fix for TR HU71400.
            // ElanUtils.delete(broker, LogicalDatastoreType.OPERATIONAL, macEntryId);
            MacEntry newMacEntry = new MacEntryBuilder().setInterface(interfaceName).setIsStaticAddress(true)
                    .setMacAddress(mac.getMacAddress()).setKey(new MacEntryKey(mac.getMacAddress())).build();
            tx.put(LogicalDatastoreType.OPERATIONAL, macEntryId, newMacEntry);
        }
    }

    private void createElanForwardingTablesList(String elanName, MacEntry macEntry, WriteTransaction tx) {
        InstanceIdentifier<MacEntry> macEntryId = ElanUtils.getMacEntryOperationalDataPath(elanName,
                macEntry.getMacAddress());
        Optional<MacEntry> existingMacEntry = elanUtils.read(broker, LogicalDatastoreType.OPERATIONAL, macEntryId);
        if (!existingMacEntry.isPresent()) {
            tx.put(LogicalDatastoreType.OPERATIONAL, macEntryId, macEntry);
        }
    }

    public void deleteElanInterfaceForwardingEntries(ElanInstance elanInfo, InterfaceInfo interfaceInfo,
            MacEntry macEntry, WriteTransaction tx) {
        InstanceIdentifier<MacEntry> macEntryId = ElanUtils
                .getMacEntryOperationalDataPath(elanInfo.getElanInstanceName(), macEntry.getMacAddress());
        tx.delete(LogicalDatastoreType.OPERATIONAL, macEntryId);
        deleteElanInterfaceForwardingTablesList(interfaceInfo.getInterfaceName(), macEntry, tx);
        WriteTransaction deleteFlowtx = broker.newWriteOnlyTransaction();
        elanUtils.deleteMacFlows(elanInfo, interfaceInfo, macEntry, deleteFlowtx);
        deleteFlowtx.submit();
    }

    public void deleteElanInterfaceMacForwardingEntries(String interfaceName, PhysAddress physAddress,
            WriteTransaction tx) {
        InstanceIdentifier<MacEntry> macEntryId = ElanUtils
                .getInterfaceMacEntriesIdentifierOperationalDataPath(interfaceName, physAddress);
        tx.delete(LogicalDatastoreType.OPERATIONAL, macEntryId);
    }


}
