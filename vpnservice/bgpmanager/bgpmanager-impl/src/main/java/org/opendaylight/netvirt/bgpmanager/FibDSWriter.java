/*
 * Copyright (c) 2015 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.bgpmanager;

import com.google.common.base.Optional;
import com.google.common.base.Preconditions;
import java.util.List;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.WriteTransaction;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.netvirt.fibmanager.api.RouteOrigin;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.FibEntries;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.fibentries.VrfTables;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.fibentries.VrfTablesKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.vrfentries.VrfEntry;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.vrfentries.VrfEntryBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.vrfentries.VrfEntryKey;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier.InstanceIdentifierBuilder;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class FibDSWriter {
    private static final Logger logger = LoggerFactory.getLogger(FibDSWriter.class);
    private final DataBroker dataBroker;

    public FibDSWriter(final DataBroker dataBroker) {
        this.dataBroker = dataBroker;
    }

    public synchronized void addFibEntryToDS(String rd, String macAddress, String prefix, List<String> nextHopList,
                                             VrfEntry.EncapType encapType, int label, long l3vni, String gatewayMacAddress,
                                             RouteOrigin origin) {
        if (rd == null || rd.isEmpty() ) {
            logger.error("Prefix {} not associated with vpn", prefix);
            return;
        }

        Preconditions.checkNotNull(nextHopList, "NextHopList can't be null");

        for ( String nextHop: nextHopList){
            if (nextHop == null || nextHop.isEmpty()){
                logger.error("nextHop list contains null element");
                return;
            }
            logger.debug("Created vrfEntry for {} nexthop {} label {}", prefix, nextHop, label);

        }

        // Looking for existing prefix in MDSAL database
        try{
            InstanceIdentifier<VrfEntry> vrfEntryId =
                    InstanceIdentifier.builder(FibEntries.class)
                            .child(VrfTables.class, new VrfTablesKey(rd))
                            .child(VrfEntry.class, new VrfEntryKey(prefix)).build();
            Optional<VrfEntry> entry = BgpUtil.read(dataBroker, LogicalDatastoreType.CONFIGURATION, vrfEntryId);

            VrfEntryBuilder vrfEntryBuilder = new VrfEntryBuilder().setDestPrefix(prefix).setNextHopAddressList(nextHopList)
                                                     .setLabel((long)label).setOrigin(origin.getValue());
            buildVpnEncapSpecificInfo(vrfEntryBuilder, encapType, (long)label, l3vni, macAddress, gatewayMacAddress);
            BgpUtil.write(dataBroker, LogicalDatastoreType.CONFIGURATION, vrfEntryId, vrfEntryBuilder.build());
        } catch (Exception e) {
            logger.error("addFibEntryToDS: error ", e);
        }

    }

    private static void buildVpnEncapSpecificInfo(VrfEntryBuilder builder, VrfEntry.EncapType encapType, long label,
                                                  long l3vni, String macAddress, String gatewayMac) {
        if (encapType.equals(VrfEntry.EncapType.Mplsgre)) {
            builder.setLabel(label);
        } else {
            builder.setL3vni(l3vni).setMacAddress(macAddress).setGatewayMacAddress(gatewayMac);
        }
        builder.setEncapType(encapType);
    }

    public synchronized void removeFibEntryFromDS(String rd, String prefix) {

        if (rd == null || rd.isEmpty()) {
            logger.error("Prefix {} not associated with vpn", prefix);
            return;
        }
        logger.debug("Removing fib entry with destination prefix {} from vrf table for rd {}", prefix, rd);

        InstanceIdentifierBuilder<VrfEntry> idBuilder =
            InstanceIdentifier.builder(FibEntries.class).child(VrfTables.class, new VrfTablesKey(rd)).child(VrfEntry.class, new VrfEntryKey(prefix));
        InstanceIdentifier<VrfEntry> vrfEntryId = idBuilder.build();
        BgpUtil.delete(dataBroker, LogicalDatastoreType.CONFIGURATION, vrfEntryId);

    }

    public synchronized void removeVrfFromDS(String rd) {
        logger.debug("Removing vrf table for  rd {}", rd);

        InstanceIdentifierBuilder<VrfTables> idBuilder =
                InstanceIdentifier.builder(FibEntries.class).child(VrfTables.class, new VrfTablesKey(rd));
        InstanceIdentifier<VrfTables> vrfTableId = idBuilder.build();

        BgpUtil.delete(dataBroker, LogicalDatastoreType.CONFIGURATION, vrfTableId);

    }
}
