/*
 * Copyright (c) 2015, 2016 Ericsson India Global Services Pvt Ltd. and others. All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.fibmanager.test;

import java.math.BigInteger;

import org.junit.Before;
import org.junit.Test;

import static org.mockito.Matchers.any;
import static org.mockito.Mockito.when;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import org.junit.runner.RunWith;
import org.mockito.Mock;
import org.mockito.runners.MockitoJUnitRunner;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.DataChangeListener;
import org.opendaylight.controller.md.sal.binding.api.ReadOnlyTransaction;
import org.opendaylight.controller.md.sal.binding.api.WriteTransaction;
import org.opendaylight.controller.md.sal.common.api.data.AsyncDataBroker.DataChangeScope;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.netvirt.fibmanager.VrfEntryListener;
import org.opendaylight.netvirt.fibmanager.api.RouteOrigin;
import org.opendaylight.netvirt.vpnmanager.api.IVpnManager;
import org.opendaylight.genius.mdsalutil.interfaces.IMdsalApiManager;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.FibEntries;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.op.data.VpnInstanceOpDataEntry;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.op.data.VpnInstanceOpDataEntryKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.op.data.vpn.instance.op.data.entry.VpnToDpnList;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.op.data.vpn.instance.op.data.entry.VpnToDpnListKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.op.data.vpn.instance.op.data.entry.vpn.to.dpn.list.IpAddresses;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.op.data.vpn.instance.op.data.entry.vpn.to.dpn.list.VpnInterfaces;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.fibentries.VrfTables;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.fibentries.VrfTablesKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.vrfentries.VrfEntry;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.vrfentries.VrfEntryBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.vrfentries.VrfEntryKey;
import org.opendaylight.yangtools.concepts.ListenerRegistration;
import org.opendaylight.yangtools.yang.binding.Augmentation;
import org.opendaylight.yangtools.yang.binding.DataContainer;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier.InstanceIdentifierBuilder;

@RunWith(MockitoJUnitRunner.class)
public class FibManagerTest {

  @Mock
  DataBroker dataBroker;
  @Mock
  ListenerRegistration<DataChangeListener> dataChangeListenerRegistration;
  @Mock
  ReadOnlyTransaction mockReadTx;
  @Mock
  WriteTransaction mockWriteTx;
  @Mock
  IMdsalApiManager mdsalManager;
  @Mock
  IVpnManager vpnmanager;
  @Mock
  VrfTablesKey vrfTableKey;

  MockDataChangedEvent dataChangeEvent;
  VrfEntryListener fibmgr;
  private static final Long EgressPointer = 11L;
  VrfEntry vrfEntry;
  InstanceIdentifier<VrfEntry> identifier;
  VrfEntryBuilder vrfbuilder;
  private static final String testVpnInstanceName = "95486250-4ad7-418f-9030-2df37f98ad24";
  private static final String testRd = "100:1";
  private static final String prefix = "1.1.2.3";
  private static final String nexthop = "1.1.1.1";
  private static final int label = 10;
  RouteOrigin origin = RouteOrigin.STATIC;
  BigInteger Dpn;
  private static final long vpnId = 101L;
  private static final long vpnIntfCnt = 2;
  private static final Boolean isCleanupComplete = Boolean.FALSE;

  private void SetupMocks() {
    Dpn = BigInteger.valueOf(100000L);
    identifier = buildVrfEntryId(testRd, prefix);
    vrfEntry = buildVrfEntry(testRd, prefix, Arrays.asList(nexthop), label, origin);
    when(vrfTableKey.getRouteDistinguisher()).thenReturn(testRd);
  }

  @Before
  public void setUp() throws Exception {
    when(
            dataBroker.registerDataChangeListener(any(LogicalDatastoreType.class),
                    any(InstanceIdentifier.class), any(DataChangeListener.class),
                    any(DataChangeScope.class))).thenReturn(dataChangeListenerRegistration);
    dataChangeEvent = new MockDataChangedEvent();
    vrfbuilder = new VrfEntryBuilder();
    SetupMocks();
  }

  @Test
  public void testAdd() {
    dataChangeEvent.created.put(identifier, vrfEntry);
    //fibmgr.onDataChanged(dataChangeEvent);
    //Mockito.verify(mdsalManager, Mockito.times(2)).installFlow(any(FlowEntity.class));
  }

  private VrfEntry buildVrfEntry(String rd, String prefix, List<String> nextHopList, int label, RouteOrigin origin) {

    return new VrfEntryBuilder().setDestPrefix(prefix).setNextHopAddressList(nextHopList)
            .setLabel((long) label).setOrigin(origin.getValue()).build();
  }

  public static InstanceIdentifier<VrfTables> buildVrfTableId(String rd) {
    InstanceIdentifierBuilder<VrfTables> idBuilder =
            InstanceIdentifier.builder(FibEntries.class).child(VrfTables.class, new VrfTablesKey(rd));
    InstanceIdentifier<VrfTables> vrfTableId = idBuilder.build();
    return vrfTableId;
  }

  public static InstanceIdentifier<VrfEntry> buildVrfEntryId(String rd, String prefix) {
    InstanceIdentifierBuilder<VrfEntry> idBuilder =
            InstanceIdentifier.builder(FibEntries.class).child(VrfTables.class, new VrfTablesKey(rd))
                    .child(VrfEntry.class, new VrfEntryKey(prefix));
    InstanceIdentifier<VrfEntry> vrfEntryId = idBuilder.build();
    return vrfEntryId;
  }
}
