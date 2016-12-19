/*
 * Copyright (c) 2015 - 2016 HPE and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.neutronvpn;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.fail;

import static org.mockito.Matchers.any;
import static org.mockito.Mockito.doAnswer;
import static org.mockito.Mockito.doReturn;
import static org.mockito.Mockito.when;

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import org.junit.After;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.Mock;
import org.mockito.invocation.InvocationOnMock;
import org.mockito.runners.MockitoJUnitRunner;
import org.mockito.stubbing.Answer;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.DataChangeListener;
import org.opendaylight.controller.md.sal.binding.api.ReadOnlyTransaction;
import org.opendaylight.controller.md.sal.binding.api.WriteTransaction;
import org.opendaylight.controller.md.sal.common.api.data.AsyncDataBroker;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.IpAddress;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.IpPrefix;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.Interfaces;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.InterfacesBuilder;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.state.Interface;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.state.InterfaceBuilder;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.meta.rev160406.bridge.ref.info.BridgeRefEntry;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.meta.rev160406.bridge.ref.info.BridgeRefEntryBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rev160406.ParentRefs;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rev160406.ParentRefsBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rev160406.TunnelTypeBase;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rev160406.TunnelTypeVxlan;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.rev160406.TransportZones;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.rev160406.transport.zones.TransportZone;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.rev160406.transport.zones.TransportZoneBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.rev160406.transport.zones.transport.zone.Subnets;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.rev160406.transport.zones.transport.zone.SubnetsBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.rev160406.transport.zones.transport.zone.subnets.Vteps;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.rev160406.transport.zones.transport.zone.subnets.VtepsBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.neutron.router.dpns.RouterDpnList;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.neutron.router.dpns.RouterDpnListBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.neutron.router.dpns.router.dpn.list.DpnVpninterfacesList;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.neutron.router.dpns.router.dpn.list.DpnVpninterfacesListBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.subnetmaps.Subnetmap;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.subnetmaps.SubnetmapBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.networks.rev150712.NetworkTypeBase;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.networks.rev150712.NetworkTypeVlan;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.networks.rev150712.NetworkTypeVxlan;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.networks.rev150712.networks.attributes.networks.Network;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.networks.rev150712.networks.attributes.networks.NetworkBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.port.attributes.FixedIps;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.port.attributes.FixedIpsBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.ports.attributes.ports.Port;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.ports.attributes.ports.PortBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.provider.ext.rev150712.NetworkProviderExtension;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.provider.ext.rev150712.NetworkProviderExtensionBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.rev150105.OvsdbBridgeAugmentation;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.rev150105.OvsdbBridgeRef;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.rev150105.OvsdbNodeAugmentation;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.rev150105.OvsdbNodeAugmentationBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.rev150105.ovsdb.node.attributes.OpenvswitchOtherConfigs;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.rev150105.ovsdb.node.attributes.OpenvswitchOtherConfigsBuilder;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.Node;
import org.opendaylight.yangtools.concepts.ListenerRegistration;
import org.opendaylight.yangtools.yang.binding.DataObject;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;

import com.google.common.base.Optional;
import com.google.common.util.concurrent.Futures;

@RunWith(MockitoJUnitRunner.class)
public class ToTransportZoneTest {

    private static final String PHYS_PORT_NAME = "tap12345-67";

    private static final Long DPN_ID = 1234567890L;
    
    private static final BigInteger DPN_ID_2 = BigInteger.valueOf(1234567891L);

    private static final String PORT_NAME = "12345678-1234-1234-1234-123456789012";

    private static final String PORT_IP = "1.1.1.1";
    
    private static final String NETWORK_ID = "12345678-1234-1234-1234-123456789012";

    private static final String SUBNET = "0.0.0.0/0";

    private static final String OVS_IP = "10.0.0.1";
    
    private static final IpAddress OVS_IP_2 = new IpAddress("10.0.0.2".toCharArray());
    
    private static final String VTEP_PORT = "tunnel_port";

    private static final String ROUTER_ID = "10345678-1234-1234-1234-123456789012"; 

    @Mock
    private DataBroker dataBroker;
    @Mock
    private NeutronvpnManager nVpnMgr;
    @Mock
    private ListenerRegistration<DataChangeListener> dataChangeListenerRegistration;
    @Mock
    private WriteTransaction mockWriteTx;
    @Mock
    private ReadOnlyTransaction mockReadTx;
    @Mock
    private Node node;
    
    private Interfaces interf;

    private Port port;

    private List<Vteps> expectedVteps = new ArrayList<>();
    
    InterfaceStateToTransportZoneListener interfaceStateToTransportZoneChangeListener;
    
    NeutronRouterDpnsToTransportZoneListener neutronRouterDpnsToTransportZoneListener;

    private Network network;

    @Before
    public void setUp() {
        when(dataBroker.registerDataChangeListener(any(LogicalDatastoreType.class), //
                any(InstanceIdentifier.class), //
                any(DataChangeListener.class), //
                any(AsyncDataBroker.DataChangeScope.class))). //
                thenReturn(dataChangeListenerRegistration);
        doReturn(mockWriteTx).when(dataBroker).newWriteOnlyTransaction();
        doAnswer(new Answer<Void>() {
            @Override
            public Void answer(InvocationOnMock invocation) throws Throwable {
                testTZ(invocation);
                return null;
            }
        }).when(mockWriteTx).put(any(), any(), any(), any(Boolean.class));
        doReturn(Futures.immediateCheckedFuture(null)).when(mockWriteTx).submit();
        doReturn(mockReadTx).when(dataBroker).newReadOnlyTransaction();
        
        Subnetmap subnetMap = new SubnetmapBuilder().setSubnetIp(SUBNET).build();
        
        when(nVpnMgr.updateSubnetmapNodeWithPorts(any(Uuid.class), any(Uuid.class), any(Uuid.class)))
                .thenReturn(subnetMap);

        when(mockReadTx.<DataObject>read(any(LogicalDatastoreType.class), any(InstanceIdentifier.class))).
        thenReturn(Futures.immediateCheckedFuture(Optional.absent()));
        interfaceStateToTransportZoneChangeListener = new InterfaceStateToTransportZoneListener(dataBroker, nVpnMgr);
        neutronRouterDpnsToTransportZoneListener = new NeutronRouterDpnsToTransportZoneListener(dataBroker, nVpnMgr);
    }
    
    @After
    public void afterTestCleanup(){
        expectedVteps.clear();
    }

    

    @Test
    public void addInterfaceState_FirstTZ() throws Exception {
        List<org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.Interface> interfaces = new ArrayList<>();
        interfaces.add(new org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.InterfaceBuilder().setName(PORT_NAME)
                .addAugmentation(ParentRefs.class, new ParentRefsBuilder().setParentInterface(PHYS_PORT_NAME).build()).build());
        interf = new InterfacesBuilder().setInterface(interfaces).build();
        port = buildPort(PORT_IP);
        buildNode();
        when(mockReadTx.<DataObject>read(any(LogicalDatastoreType.class), any(InstanceIdentifier.class))).
        thenReturn(Futures.immediateCheckedFuture(Optional.of(interf))).
        thenReturn(Futures.immediateCheckedFuture(Optional.of(port))).
        thenReturn(Futures.immediateCheckedFuture(Optional.absent())).
        thenReturn(Futures.immediateCheckedFuture(Optional.of(getBridgeRefForNode()))).
        thenReturn(Futures.immediateCheckedFuture(Optional.of(node))).
        thenReturn(Futures.immediateCheckedFuture(Optional.absent()));
        InterfaceBuilder intBuilder = new InterfaceBuilder();
        intBuilder.setName(PHYS_PORT_NAME);
        intBuilder.setLowerLayerIf(new ArrayList<>(Arrays.asList(new String[] {"int:"+DPN_ID})));//NetworkId(new Uuid("12345678-1234-1234-1234-123456789012"));
        expectedVteps.add(buildVtep(BigInteger.valueOf(DPN_ID), new IpAddress(OVS_IP.toCharArray()), VTEP_PORT));
        interfaceStateToTransportZoneChangeListener.add(InstanceIdentifier.create(Interface.class), intBuilder.build());
    }
    
    @Test
    public void addInterfaceState_ExistingTZ() throws Exception {
        List<org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.Interface> interfaces = new ArrayList<>();
        interfaces.add(new org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.InterfaceBuilder().setName(PORT_NAME)
                .addAugmentation(ParentRefs.class, new ParentRefsBuilder().setParentInterface(PHYS_PORT_NAME).build()).build());
        interf = new InterfacesBuilder().setInterface(interfaces).build();
        port = buildPort(PORT_IP);
        network = buildNetwork(NetworkTypeVxlan.class);
        TransportZone tz = new TransportZoneBuilder().setZoneName(NETWORK_ID).setTunnelType(TunnelTypeVxlan.class).setSubnets(new ArrayList<>()).build();
        buildNode();
        when(mockReadTx.<DataObject>read(any(LogicalDatastoreType.class), any(InstanceIdentifier.class))).
        thenReturn(Futures.immediateCheckedFuture(Optional.of(interf))).
        thenReturn(Futures.immediateCheckedFuture(Optional.of(port))).
        thenReturn(Futures.immediateCheckedFuture(Optional.of(network))).
        thenReturn(Futures.immediateCheckedFuture(Optional.of(tz))).
        thenReturn(Futures.immediateCheckedFuture(Optional.of(getBridgeRefForNode()))).
        thenReturn(Futures.immediateCheckedFuture(Optional.of(node))).
        thenReturn(Futures.immediateCheckedFuture(Optional.absent()));
        InterfaceBuilder intBuilder = new InterfaceBuilder();
        intBuilder.setName(PHYS_PORT_NAME);
        intBuilder.setLowerLayerIf(new ArrayList<>(Arrays.asList(new String[] {"int:"+DPN_ID})));//NetworkId(new Uuid("12345678-1234-1234-1234-123456789012"));
        expectedVteps.add(buildVtep(BigInteger.valueOf(DPN_ID), new IpAddress(OVS_IP.toCharArray()), VTEP_PORT));
        interfaceStateToTransportZoneChangeListener.add(InstanceIdentifier.create(Interface.class), intBuilder.build());
    }
    
    @Test
    public void addInterfaceState_MultipleVtepsInTZ() throws Exception {
        List<org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.Interface> interfaces = new ArrayList<>();
        interfaces.add(new org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.InterfaceBuilder().setName(PORT_NAME)
                .addAugmentation(ParentRefs.class, new ParentRefsBuilder().setParentInterface(PHYS_PORT_NAME).build()).build());
        interf = new InterfacesBuilder().setInterface(interfaces).build();
        port = buildPort(PORT_IP);
        network = buildNetwork(NetworkTypeVxlan.class);
        TransportZone tz = new TransportZoneBuilder().setZoneName(NETWORK_ID).setTunnelType(TunnelTypeVxlan.class).setSubnets(new ArrayList<>()).build();
        buildNode();
        when(mockReadTx.<DataObject>read(any(LogicalDatastoreType.class), any(InstanceIdentifier.class))).
        thenReturn(Futures.immediateCheckedFuture(Optional.of(interf))).
        thenReturn(Futures.immediateCheckedFuture(Optional.of(port))).
        thenReturn(Futures.immediateCheckedFuture(Optional.of(network))).
        thenReturn(Futures.immediateCheckedFuture(Optional.of(tz))).
        thenReturn(Futures.immediateCheckedFuture(Optional.of(getBridgeRefForNode()))).
        thenReturn(Futures.immediateCheckedFuture(Optional.of(node))).
        thenReturn(Futures.immediateCheckedFuture(Optional.absent()));
        InterfaceBuilder intBuilder = new InterfaceBuilder();
        intBuilder.setName(PHYS_PORT_NAME);
        intBuilder.setLowerLayerIf(new ArrayList<>(Arrays.asList(new String[] {"int:"+DPN_ID})));//NetworkId(new Uuid("12345678-1234-1234-1234-123456789012"));
        expectedVteps.add(buildVtep(BigInteger.valueOf(DPN_ID), new IpAddress(OVS_IP.toCharArray()), VTEP_PORT));
        interfaceStateToTransportZoneChangeListener.add(InstanceIdentifier.create(Interface.class), intBuilder.build());
    }

    @Test
    public void addInterfaceState_VLAN_Network() throws Exception {
        List<org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.Interface> interfaces = new ArrayList<>();
        interfaces.add(new org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.InterfaceBuilder().setName(PORT_NAME)
                .addAugmentation(ParentRefs.class, new ParentRefsBuilder().setParentInterface(PHYS_PORT_NAME).build()).build());
        interf = new InterfacesBuilder().setInterface(interfaces).build();
        port = buildPort(PORT_IP);
        network = buildNetwork(NetworkTypeVlan.class);
        TransportZone tz = new TransportZoneBuilder().setZoneName(NETWORK_ID).setTunnelType(TunnelTypeVxlan.class).setSubnets(buildSubnets()).build();
        buildNode();
        when(mockReadTx.<DataObject>read(any(LogicalDatastoreType.class), any(InstanceIdentifier.class))).
        thenReturn(Futures.immediateCheckedFuture(Optional.of(interf))).
        thenReturn(Futures.immediateCheckedFuture(Optional.of(port))).
        thenReturn(Futures.immediateCheckedFuture(Optional.of(network)));
        InterfaceBuilder intBuilder = new InterfaceBuilder();
        intBuilder.setName(PHYS_PORT_NAME);
        intBuilder.setLowerLayerIf(new ArrayList<>(Arrays.asList(new String[] {"int:"+DPN_ID})));//NetworkId(new Uuid("12345678-1234-1234-1234-123456789012"));
        interfaceStateToTransportZoneChangeListener.add(InstanceIdentifier.create(Interface.class), intBuilder.build());
    }
    
    @Test
    public void addRouter() throws Exception {
        when(mockReadTx.<DataObject>read(any(LogicalDatastoreType.class), any(InstanceIdentifier.class))).
        thenReturn(Futures.immediateCheckedFuture(Optional.absent()));
        RouterDpnListBuilder intBuilder = new RouterDpnListBuilder();
        RouterDpnList routerDpnList = buildRouterDpnList();
        expectedVteps.add(buildVtep(BigInteger.valueOf(DPN_ID), new IpAddress(OVS_IP.toCharArray()), VTEP_PORT));
        expectedVteps.add(buildVtep(DPN_ID_2, OVS_IP_2, VTEP_PORT));
        neutronRouterDpnsToTransportZoneListener.add(InstanceIdentifier.create(RouterDpnList.class), routerDpnList);
    }
    
    private RouterDpnList buildRouterDpnList() {
        RouterDpnListBuilder routerDpnBuilder = new RouterDpnListBuilder();
        routerDpnBuilder.setRouterId(ROUTER_ID);
        List<DpnVpninterfacesList> list = new ArrayList<DpnVpninterfacesList>();
        list.add(new DpnVpninterfacesListBuilder().setDpnId(BigInteger.valueOf(DPN_ID)).build());
        list.add(new DpnVpninterfacesListBuilder().setDpnId(DPN_ID_2).build());
        routerDpnBuilder.setDpnVpninterfacesList(list);
        return routerDpnBuilder.build();
    }

    private Network buildNetwork(Class<? extends NetworkTypeBase> networkType) {
        NetworkBuilder builder = new NetworkBuilder();
        NetworkProviderExtensionBuilder augBuilder = new NetworkProviderExtensionBuilder();
        augBuilder.setNetworkType(networkType);
        builder.addAugmentation(NetworkProviderExtension.class, augBuilder.build());
        return builder.build();
    }

    private List<Subnets> buildSubnets() {
        List<Subnets> subnets = new ArrayList<>();
        SubnetsBuilder subnetsBuilder = new SubnetsBuilder();
        List<Vteps> vteps = new ArrayList<Vteps>();
        
        vteps.add(buildVtep(DPN_ID_2, OVS_IP_2, VTEP_PORT));
        subnetsBuilder.setVteps(vteps);
        subnetsBuilder.setPrefix(new IpPrefix(SUBNET.toCharArray()));
        
        subnets.add(subnetsBuilder.build());
        return subnets;
    }



    private Vteps buildVtep(BigInteger dpnId, IpAddress portIp, String portName) {
        VtepsBuilder vtepBuilder = new VtepsBuilder();
        vtepBuilder.setDpnId(dpnId);
        vtepBuilder.setIpAddress(portIp);
        vtepBuilder.setPortname(portName);
        return vtepBuilder.build();
    }



    private BridgeRefEntry getBridgeRefForNode() {
        BridgeRefEntryBuilder breb = new BridgeRefEntryBuilder();
        InstanceIdentifier<OvsdbBridgeAugmentation> path = InstanceIdentifier.create(Node.class).augmentation(OvsdbBridgeAugmentation.class);
        breb.setBridgeReference(new OvsdbBridgeRef(path));
        return breb.build();
    }

    private void buildNode() {
        List<OpenvswitchOtherConfigs> list = new ArrayList<>();
        list.add(new OpenvswitchOtherConfigsBuilder().setOtherConfigKey("local_ip").setOtherConfigValue(OVS_IP).build());
        OvsdbNodeAugmentation ovsdbNode = new OvsdbNodeAugmentationBuilder().setOpenvswitchOtherConfigs(list).build();
        when(node.getAugmentation(OvsdbNodeAugmentation.class)).
        thenReturn(ovsdbNode);
    }

    private Port buildPort(String portIp) {
        PortBuilder portBuilder = new PortBuilder();
        portBuilder.setFixedIps(new ArrayList<>(Arrays.asList(new FixedIps[] {new FixedIpsBuilder().setIpAddress(new IpAddress(portIp.toCharArray())).build()})));
        portBuilder.setNetworkId(new Uuid(NETWORK_ID));
        return portBuilder.build();
    }
    
    protected void testTZ(InvocationOnMock invocation) {
        TransportZones tzs = (TransportZones) invocation.getArguments()[2];
        assertNotNull(tzs);
        List<TransportZone> tzList = tzs.getTransportZone();
        assertNotNull(tzList);
        assertEquals(1, tzList.size());
        TransportZone tz = tzList.get(0);
        assertTZ(tz);
    }

    private void assertTZ(TransportZone tz) {
        assertSubnets(tz.getSubnets());
        assertTunnelType(tz.getTunnelType());
        assertZoneName(tz.getZoneName());
    }



    private void assertZoneName(String zoneName) {
        assertEquals(NETWORK_ID, zoneName);
    }



    private void assertTunnelType(Class<? extends TunnelTypeBase> tunnelType) {
        assertEquals(TunnelTypeVxlan.class, tunnelType);
    }



    private void assertSubnets(List<Subnets> subnets) {
        assertNotNull(subnets);
        assertEquals(1, subnets.size());
        assertSubnet(subnets.get(0));
    }



    private void assertSubnet(Subnets subnets) {
        assertEquals(new IpPrefix(SUBNET.toCharArray()), subnets.getPrefix());
        assertNotNull(subnets.getVteps());
        
        assertVtep(expectedVteps, subnets.getVteps());
        
    }



    private void assertVtep(List<Vteps> expectedVteps, List<Vteps> vteps) {
        assertNotNull(vteps);
        assertEquals(expectedVteps.size(), vteps.size());
        outer_loop: for(Vteps expectedVtep : expectedVteps){
            for(Vteps vtep : vteps){
                boolean flag = true;
                flag &= expectedVtep.getDpnId().equals(vtep.getDpnId());
                flag &= expectedVtep.getIpAddress().equals(vtep.getIpAddress());
                flag &= expectedVtep.getPortname().equals(vtep.getPortname());
                if(flag){
                    continue outer_loop;
                }
            }
            fail();
        }
    }

}
