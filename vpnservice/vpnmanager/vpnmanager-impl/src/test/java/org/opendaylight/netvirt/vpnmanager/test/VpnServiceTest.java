/*
 * Copyright (c) 2015 - 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.vpnmanager.test;

import static org.mockito.Matchers.any;
import static org.mockito.Mockito.when;

import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.Mock;
import org.mockito.runners.MockitoJUnitRunner;
import org.opendaylight.netvirt.bgpmanager.api.IBgpManager;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.DataChangeListener;
import org.opendaylight.controller.md.sal.common.api.data.AsyncDataBroker.DataChangeScope;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.vpn.af.config.VpnTargets;
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.vpn.af.config.VpnTargetsBuilder;
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.vpn.af.config.apply.label.apply
        .label.mode.PerRouteBuilder;
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.vpn.af.config.vpntargets.VpnTarget;
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.vpn.af.config.vpntargets.VpnTargetBuilder;
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.vpn.af.config.vpntargets.VpnTargetKey;
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.vpn.instances.VpnInstance;
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.vpn.instances.VpnInstanceBuilder;
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.vpn.instances.VpnInstanceKey;
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.vpn.instances.vpn.instance.Ipv4Family;
import org.opendaylight.yangtools.concepts.ListenerRegistration;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier.InstanceIdentifierBuilder;
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.VpnInstances;
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.vpn.af.config.ApplyLabelBuilder;
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.vpn.instances.vpn.instance.Ipv4FamilyBuilder;

import java.util.ArrayList;
import java.util.List;

@RunWith(MockitoJUnitRunner.class)
public class VpnServiceTest {
    @Mock DataBroker dataBroker;
    @Mock IBgpManager bgpManager;
    @Mock ListenerRegistration<DataChangeListener> dataChangeListenerRegistration;
    MockDataChangedEvent event;

    @Before
    public void setUp() throws Exception {
        when(dataBroker.registerDataChangeListener(
                any(LogicalDatastoreType.class),
                any(InstanceIdentifier.class),
                any(DataChangeListener.class),
                any(DataChangeScope.class)))
                .thenReturn(dataChangeListenerRegistration);
        event = new MockDataChangedEvent();
    }

    @Test
    public void test() {

        List<VpnTarget> vpnTargetList = new ArrayList<>();

        VpnTarget vpneRTarget = new VpnTargetBuilder().setKey(new VpnTargetKey("100:1")).setVrfRTValue("100:1")
                .setVrfRTType(VpnTarget.VrfRTType.ExportExtcommunity).build();
        VpnTarget vpniRTarget = new VpnTargetBuilder().setKey(new VpnTargetKey("100:2")).setVrfRTValue("100:2")
                .setVrfRTType(VpnTarget.VrfRTType.ImportExtcommunity).build();

        vpnTargetList.add(vpneRTarget);
        vpnTargetList.add(vpniRTarget);

        VpnTargets vpnTargets = new VpnTargetsBuilder().setVpnTarget(vpnTargetList).build();

        Ipv4Family ipv4Family = new Ipv4FamilyBuilder().setRouteDistinguisher("100:1").setVpnTargets(vpnTargets)
                .setApplyLabel(new ApplyLabelBuilder().setApplyLabelMode(
                        new PerRouteBuilder().setApplyLabelPerRoute(true).build()).build()).build();

        VpnInstanceBuilder builder = new VpnInstanceBuilder().setKey(new VpnInstanceKey("Vpn1")).setIpv4Family
                (ipv4Family);
        VpnInstance instance = builder.build();
        event.created.put(createVpnId("Vpn1"), instance);
        //TODO: Need to enhance the test case to handle ds read/write ops
        //vpnManager.onDataChanged(event);
    }

    private InstanceIdentifier<VpnInstance> createVpnId(String name) {
       InstanceIdentifierBuilder<VpnInstance> idBuilder = 
           InstanceIdentifier.builder(VpnInstances.class).child(VpnInstance.class, new VpnInstanceKey(name));
       InstanceIdentifier<VpnInstance> id = idBuilder.build();
       return id;
    }

}
