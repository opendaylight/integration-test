/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.vpnmanager;

import java.util.ArrayList;
import java.util.List;


import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.mdsalutil.MDSALUtil;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.port.op.data.PortOpDataEntry;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.port.op.data.PortOpDataEntryBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.port.op.data.PortOpDataEntryKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.subnet.op.data.subnet.op.data.entry.subnet.to.dpn.VpnInterfaces;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.subnet.op.data.subnet.op.data.entry.subnet.to.dpn.VpnInterfacesBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.subnet.op.data.subnet.op.data.entry.subnet.to.dpn.VpnInterfacesKey;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.PortOpData;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.SubnetOpData;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.subnet.op.data.SubnetOpDataEntry;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.subnet.op.data.SubnetOpDataEntryKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.subnet.op.data.subnet.op.data.entry.SubnetToDpn;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.subnet.op.data.subnet.op.data.entry.SubnetToDpnBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.subnet.op.data.subnet.op.data.entry.SubnetToDpnKey;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;

import java.math.BigInteger;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.google.common.base.Optional;


public class SubnetOpDpnManager {
    private static final Logger logger = LoggerFactory.getLogger(SubnetOpDpnManager.class);

    private final DataBroker broker;

    public SubnetOpDpnManager(final DataBroker db) {
        broker = db;
    }

    private SubnetToDpn addDpnToSubnet(Uuid subnetId, BigInteger dpnId) {
        SubnetToDpn subDpn = null;
        try {
            InstanceIdentifier<SubnetOpDataEntry> subOpIdentifier = InstanceIdentifier.builder(SubnetOpData.class).
                    child(SubnetOpDataEntry.class, new SubnetOpDataEntryKey(subnetId)).build();
            InstanceIdentifier<SubnetToDpn> dpnOpId = subOpIdentifier.child(SubnetToDpn.class, new SubnetToDpnKey(dpnId));
            Optional<SubnetToDpn> optionalSubDpn = VpnUtil.read(broker, LogicalDatastoreType.OPERATIONAL, dpnOpId);
            if (optionalSubDpn.isPresent()) {
                logger.error("Cannot create, SubnetToDpn for subnet " + subnetId.getValue() +
                        " as DPN " + dpnId + " already seen in datastore");
                return null;
            }
            SubnetToDpnBuilder subDpnBuilder = new SubnetToDpnBuilder().setKey(new SubnetToDpnKey(dpnId));
            List<VpnInterfaces> vpnIntfList = new ArrayList<VpnInterfaces>();
            subDpnBuilder.setVpnInterfaces(vpnIntfList);
            subDpn = subDpnBuilder.build();
            logger.trace("Creating SubnetToDpn entry for subnet  " + subnetId.getValue() + " with DPNId "+ dpnId);
            MDSALUtil.syncWrite(broker, LogicalDatastoreType.OPERATIONAL, dpnOpId, subDpn);
        } catch (Exception ex) {
            logger.error("Creation of SubnetToDpn for subnet " +
                    subnetId.getValue() + " with DpnId " + dpnId + " failed {}" + ex);
            return null;
        } finally {
        }
        return subDpn;
    }

    private void removeDpnFromSubnet(Uuid subnetId, BigInteger dpnId) {
        try {
            InstanceIdentifier<SubnetOpDataEntry> subOpIdentifier = InstanceIdentifier.builder(SubnetOpData.class).
                    child(SubnetOpDataEntry.class, new SubnetOpDataEntryKey(subnetId)).build();
            InstanceIdentifier<SubnetToDpn> dpnOpId =subOpIdentifier.child(SubnetToDpn.class, new SubnetToDpnKey(dpnId));
            Optional<SubnetToDpn> optionalSubDpn = VpnUtil.read(broker, LogicalDatastoreType.OPERATIONAL, dpnOpId);
            if (!optionalSubDpn.isPresent()) {
                logger.warn("Cannot delete, SubnetToDpn for subnet " + subnetId.getValue() +
                        " DPN " + dpnId + " not available in datastore");
                return;
            }
            logger.trace("Deleting SubnetToDpn entry for subnet  " + subnetId.getValue() + " with DPNId "+ dpnId);
            MDSALUtil.syncDelete(broker, LogicalDatastoreType.OPERATIONAL, dpnOpId);
        } catch (Exception ex) {
            logger.error("Deletion of SubnetToDpn for subnet " +
                    subnetId.getValue() + " with DPN " + dpnId + " failed {}" + ex);
        } finally {
        }
    }

    public SubnetToDpn addInterfaceToDpn(Uuid subnetId, BigInteger dpnId, String intfName) {
        SubnetToDpn subDpn = null;
        try {
            // Create and add SubnetOpDataEntry object for this subnet to the SubnetOpData container
            InstanceIdentifier<SubnetOpDataEntry> subOpIdentifier = InstanceIdentifier.builder(SubnetOpData.class).
                    child(SubnetOpDataEntry.class, new SubnetOpDataEntryKey(subnetId)).build();
            //Please use a synchronize block here as we donot need a cluster-wide lock
            InstanceIdentifier<SubnetToDpn> dpnOpId = subOpIdentifier.child(SubnetToDpn.class, new SubnetToDpnKey(dpnId));
            Optional<SubnetToDpn> optionalSubDpn = VpnUtil.read(broker, LogicalDatastoreType.OPERATIONAL, dpnOpId);
            if (!optionalSubDpn.isPresent()) {
                // Create a new DPN Entry
                subDpn = addDpnToSubnet(subnetId, dpnId);
            } else {
                subDpn = optionalSubDpn.get();
            }
            SubnetToDpnBuilder subDpnBuilder = new SubnetToDpnBuilder(subDpn);
            List<VpnInterfaces> vpnIntfList = subDpnBuilder.getVpnInterfaces();
            VpnInterfaces vpnIntfs = new VpnInterfacesBuilder().setKey(new VpnInterfacesKey(intfName)).setInterfaceName(intfName).build();
            vpnIntfList.add(vpnIntfs);
            subDpnBuilder.setVpnInterfaces(vpnIntfList);
            subDpn = subDpnBuilder.build();

            logger.trace("Creating SubnetToDpn entry for subnet  " + subnetId.getValue() + " with DPNId "+ dpnId);
            MDSALUtil.syncWrite(broker, LogicalDatastoreType.OPERATIONAL, dpnOpId, subDpn);
        } catch (Exception ex) {
            logger.error("Addition of Interface " + intfName + " for SubnetToDpn on subnet " +
                    subnetId.getValue() + " with DPN " + dpnId + " failed {}" + ex);
            return null;
        } finally {
        }
        return subDpn;
    }

    public void addPortOpDataEntry(String intfName, Uuid subnetId, BigInteger dpnId)  {
        try {
            // Add to PortOpData as well.
            PortOpDataEntryBuilder portOpBuilder = null;
            PortOpDataEntry portOpEntry = null;

            InstanceIdentifier<PortOpDataEntry> portOpIdentifier = InstanceIdentifier.builder(PortOpData.class).
                    child(PortOpDataEntry.class, new PortOpDataEntryKey(intfName)).build();
            Optional<PortOpDataEntry> optionalPortOp = VpnUtil.read(broker, LogicalDatastoreType.OPERATIONAL, portOpIdentifier);
            if (!optionalPortOp.isPresent()) {
                // Create PortOpDataEntry only if not present
                portOpBuilder = new PortOpDataEntryBuilder().setKey(new PortOpDataEntryKey(intfName)).setPortId(intfName);
                portOpBuilder.setSubnetId(subnetId);
                portOpBuilder.setDpnId(dpnId);
                portOpEntry = portOpBuilder.build();
            } else {
                portOpBuilder = new PortOpDataEntryBuilder(optionalPortOp.get());
                portOpBuilder.setSubnetId(subnetId);
                portOpBuilder.setDpnId(dpnId);
                portOpEntry = portOpBuilder.build();
            }
            logger.trace("Creating PortOpData entry for port " + intfName + " with DPNId "+ dpnId);
            MDSALUtil.syncWrite(broker, LogicalDatastoreType.OPERATIONAL, portOpIdentifier, portOpEntry);
        } catch (Exception ex) {
          logger.error("Addition of Interface " + intfName + " for SubnetToDpn on subnet " +
                  subnetId.getValue() + " with DPN " + dpnId + " failed {}" + ex);
        } finally {
        }
    }

    public boolean removeInterfaceFromDpn(Uuid subnetId, BigInteger dpnId, String intfName) {
        boolean dpnRemoved = false;
        try {
            InstanceIdentifier<SubnetOpDataEntry> subOpIdentifier = InstanceIdentifier.builder(SubnetOpData.class).
                    child(SubnetOpDataEntry.class, new SubnetOpDataEntryKey(subnetId)).build();
            InstanceIdentifier<SubnetToDpn> dpnOpId = subOpIdentifier.child(SubnetToDpn.class, new SubnetToDpnKey(dpnId));
            Optional<SubnetToDpn> optionalSubDpn = VpnUtil.read(broker, LogicalDatastoreType.OPERATIONAL, dpnOpId);
            if (!optionalSubDpn.isPresent()) {
                logger.warn("Cannot delete, SubnetToDpn for subnet " + subnetId.getValue() +
                        " DPN " + dpnId + " not available in datastore");
                return false;
            }

            SubnetToDpnBuilder subDpnBuilder = new SubnetToDpnBuilder(optionalSubDpn.get());
            List<VpnInterfaces> vpnIntfList = subDpnBuilder.getVpnInterfaces();
            VpnInterfaces vpnIntfs = new VpnInterfacesBuilder().setKey(new VpnInterfacesKey(intfName)).setInterfaceName(intfName).build();
            vpnIntfList.remove(vpnIntfs);
            if (vpnIntfList.isEmpty()) {
                // Remove the DPN as well
                removeDpnFromSubnet(subnetId, dpnId);
                dpnRemoved = true;
            } else {
                subDpnBuilder.setVpnInterfaces(vpnIntfList);
                MDSALUtil.syncWrite(broker, LogicalDatastoreType.OPERATIONAL, dpnOpId, subDpnBuilder.build());
            }
        } catch (Exception ex) {
            logger.error("Deletion of Interface " + intfName + " for SubnetToDpn on subnet " +
                    subnetId.getValue() + " with DPN " + dpnId + " failed {}" + ex);
            return false;
        } finally {
        }
        return dpnRemoved;
    }

    public PortOpDataEntry removePortOpDataEntry(String intfName) {
        // Remove PortOpData and return out
        InstanceIdentifier<PortOpDataEntry> portOpIdentifier = InstanceIdentifier.builder(PortOpData.class).
                child(PortOpDataEntry.class, new PortOpDataEntryKey(intfName)).build();
        PortOpDataEntry portOpEntry = null;
        Optional<PortOpDataEntry> optionalPortOp = VpnUtil.read(broker, LogicalDatastoreType.OPERATIONAL, portOpIdentifier);
        if (!optionalPortOp.isPresent()) {
            logger.error("Cannot delete, portOp for port " + intfName +
                    " is not available in datastore");
            return null;
        } else {
            portOpEntry = optionalPortOp.get();
            logger.trace("Deleting portOpData entry for port " + intfName);
            MDSALUtil.syncDelete(broker, LogicalDatastoreType.OPERATIONAL, portOpIdentifier);
        }
        return portOpEntry;
    }

    public PortOpDataEntry getPortOpDataEntry(String intfName) {
     // Remove PortOpData and return out
        InstanceIdentifier<PortOpDataEntry> portOpIdentifier = InstanceIdentifier.builder(PortOpData.class).
                child(PortOpDataEntry.class, new PortOpDataEntryKey(intfName)).build();
        Optional<PortOpDataEntry> optionalPortOp = VpnUtil.read(broker, LogicalDatastoreType.OPERATIONAL, portOpIdentifier);
        if (!optionalPortOp.isPresent()) {
            logger.error("Cannot get, portOp for port " + intfName +
                    " is not available in datastore");
            return null;
        }
        return optionalPortOp.get();
    }

}
