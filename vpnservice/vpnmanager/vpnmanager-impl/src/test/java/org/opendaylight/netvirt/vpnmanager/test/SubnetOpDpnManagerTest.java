/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.vpnmanager.test;

import com.google.common.base.Optional;
import com.google.common.util.concurrent.Futures;

import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.Mock;
import org.mockito.runners.MockitoJUnitRunner;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.DataChangeListener;
import org.opendaylight.controller.md.sal.binding.api.ReadOnlyTransaction;
import org.opendaylight.controller.md.sal.binding.api.WriteTransaction;
import org.opendaylight.controller.md.sal.common.api.data.AsyncDataBroker;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.netvirt.vpnmanager.SubnetOpDpnManager;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.PortOpData;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.SubnetOpData;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.port.op.data.PortOpDataEntry;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.port.op.data.PortOpDataEntryBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.port.op.data.PortOpDataEntryKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.subnet.op.data.SubnetOpDataEntry;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.subnet.op.data.SubnetOpDataEntryKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.subnet.op.data.subnet.op.data.entry.SubnetToDpn;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.subnet.op.data.subnet.op.data.entry.SubnetToDpnBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.subnet.op.data.subnet.op.data.entry.SubnetToDpnKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.subnet.op.data.subnet.op.data.entry.subnet.to.dpn.VpnInterfaces;
import org.opendaylight.yangtools.concepts.ListenerRegistration;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.List;

import static org.mockito.Matchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.doReturn;
import static org.mockito.Mockito.when;



@RunWith(MockitoJUnitRunner.class)
public class SubnetOpDpnManagerTest {

    BigInteger dpId = BigInteger.valueOf(1);
    Uuid subnetId = Uuid.getDefaultInstance("067e6162-3b6f-4ae2-a171-2470b63dff00");
    String infName = "VPN";
    SubnetToDpn subnetToDpn = null;
    PortOpDataEntry portOp = null;
    String portId = "abc";

    InstanceIdentifier<SubnetOpDataEntry> subOpIdentifier = InstanceIdentifier.builder(SubnetOpData.class).
            child(SubnetOpDataEntry.class, new SubnetOpDataEntryKey(subnetId)).build();
    InstanceIdentifier<SubnetToDpn> dpnOpId = subOpIdentifier.child(SubnetToDpn.class, new SubnetToDpnKey(dpId));
    InstanceIdentifier<PortOpDataEntry> portOpIdentifier = InstanceIdentifier.builder(PortOpData.class).
            child(PortOpDataEntry.class, new PortOpDataEntryKey(infName)).build();

    @Mock DataBroker dataBroker;
    @Mock ListenerRegistration<DataChangeListener> dataChangeListenerRegistration;
    @Mock ReadOnlyTransaction mockReadTx;
    @Mock WriteTransaction mockWriteTx;

    SubnetOpDpnManager subOpDpnManager;

    Optional<SubnetToDpn> optionalSubDpn;
    Optional<PortOpDataEntry> optionalPortOp;

    @Before
    public void setUp() throws Exception {
        when(dataBroker.registerDataChangeListener(
                any(LogicalDatastoreType.class),
                any(InstanceIdentifier.class),
                any(DataChangeListener.class),
                any(AsyncDataBroker.DataChangeScope.class)))
                .thenReturn(dataChangeListenerRegistration);
        setupMocks();

        subOpDpnManager = new SubnetOpDpnManager(dataBroker);

        optionalSubDpn = Optional.of(subnetToDpn);
        optionalPortOp = Optional.of(portOp);

        doReturn(Futures.immediateCheckedFuture(optionalPortOp)).when(mockReadTx).read(LogicalDatastoreType
                .OPERATIONAL, portOpIdentifier);
        doReturn(Futures.immediateCheckedFuture(optionalSubDpn)).when(mockReadTx).read(LogicalDatastoreType
                .OPERATIONAL, dpnOpId);

    }

    private void setupMocks() {

        List<VpnInterfaces> vpnInterfaces = new ArrayList<>();
        subnetToDpn = new SubnetToDpnBuilder().setDpnId(dpId).setKey(new SubnetToDpnKey(dpId)).setVpnInterfaces
                (vpnInterfaces).build();
        portOp = new PortOpDataEntryBuilder().setDpnId(dpId).setKey(new PortOpDataEntryKey(infName)).setSubnetId
                (subnetId).setPortId(portId).build();
        doReturn(mockReadTx).when(dataBroker).newReadOnlyTransaction();
        doReturn(mockWriteTx).when(dataBroker).newWriteOnlyTransaction();
        doReturn(Futures.immediateCheckedFuture(null)).when(mockWriteTx).submit();
    }

    @Test
    public void testAddInterfaceToDpn() {

        subOpDpnManager.addInterfaceToDpn(subnetId, dpId, infName);

        verify(mockWriteTx).put(LogicalDatastoreType.OPERATIONAL, dpnOpId, subnetToDpn, true);

    }

    @Test
    public void testAddPortOpDataEntryPortOpPresent() {

        subOpDpnManager.addPortOpDataEntry(infName, subnetId, dpId);

        verify(mockWriteTx).put(LogicalDatastoreType.OPERATIONAL, portOpIdentifier, portOp, true);
    }

    @Test
    public void testAddPortOpDataEntryPortOpAbsent() {

        doReturn(Futures.immediateCheckedFuture(Optional.absent())).when(mockReadTx).read(LogicalDatastoreType
                .OPERATIONAL, portOpIdentifier);

        subOpDpnManager.addPortOpDataEntry(infName, subnetId, dpId);

        verify(mockWriteTx).put(LogicalDatastoreType.OPERATIONAL, portOpIdentifier, portOp, true);
    }

    @Test
    public void testRemoveInterfaceFromDpn() {

        subOpDpnManager.removeInterfaceFromDpn(subnetId, dpId, infName);

        verify(mockWriteTx).delete(LogicalDatastoreType.OPERATIONAL, dpnOpId);
    }

    @Test
    public void testRemovePortOpDataEntryPortOpPresent() {

        subOpDpnManager.removePortOpDataEntry(infName);

        verify(mockWriteTx).delete(LogicalDatastoreType.OPERATIONAL, portOpIdentifier);
    }

    @Test
    public void testRemovePortOpDataEntryPortOpAbsent() {

        doReturn(Futures.immediateCheckedFuture(Optional.absent())).when(mockReadTx).read(LogicalDatastoreType
                .OPERATIONAL, portOpIdentifier);

        subOpDpnManager.removePortOpDataEntry(infName);

        verify(mockReadTx).read(LogicalDatastoreType.OPERATIONAL, portOpIdentifier);

    }

    @Test
    public void testGetPortOpDataEntryPortOpPresent() {

        subOpDpnManager.getPortOpDataEntry(infName);

        verify(mockReadTx).read(LogicalDatastoreType.OPERATIONAL, portOpIdentifier);

    }

    @Test
    public void testGetPortOpDataEntryPortOpAbsent() {

        doReturn(Futures.immediateCheckedFuture(Optional.absent())).when(mockReadTx).read(LogicalDatastoreType
                .OPERATIONAL, portOpIdentifier);

        subOpDpnManager.getPortOpDataEntry(infName);

        verify(mockReadTx).read(LogicalDatastoreType.OPERATIONAL, portOpIdentifier);

    }

}
