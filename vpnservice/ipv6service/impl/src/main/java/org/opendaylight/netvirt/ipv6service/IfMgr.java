/*
 * Copyright (c) 2015 Dell Inc. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.ipv6service;

import com.google.common.net.InetAddresses;
import io.netty.util.Timeout;
import java.math.BigInteger;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.genius.mdsalutil.NwConstants;
import org.opendaylight.genius.mdsalutil.interfaces.IMdsalApiManager;
import org.opendaylight.netvirt.elanmanager.api.IElanService;
import org.opendaylight.netvirt.ipv6service.utils.Ipv6Constants;
import org.opendaylight.netvirt.ipv6service.utils.Ipv6Constants.Ipv6RtrAdvertType;
import org.opendaylight.netvirt.ipv6service.utils.Ipv6ServiceUtils;
import org.opendaylight.netvirt.ipv6service.utils.Ipv6TimerWheel;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.IpAddress;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.IpPrefix;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.Ipv6Address;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.MacAddress;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rpcs.rev160406.GetInterfaceFromIfIndexInput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rpcs.rev160406.GetInterfaceFromIfIndexInputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rpcs.rev160406.GetInterfaceFromIfIndexOutput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rpcs.rev160406.OdlInterfaceRpcService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.NodeConnectorId;
import org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.NodeConnectorRef;
import org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.NodeId;
import org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.Nodes;
import org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.node.NodeConnector;
import org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.node.NodeConnectorKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.nodes.Node;
import org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.nodes.NodeKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.instances.ElanInstance;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.ports.rev150712.port.attributes.FixedIps;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.opendaylight.yangtools.yang.common.RpcResult;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class IfMgr {
    static final Logger LOG = LoggerFactory.getLogger(IfMgr.class);

    private HashMap<Uuid, VirtualRouter> vrouters;
    private HashMap<Uuid, VirtualNetwork> vnetworks;
    private HashMap<Uuid, VirtualSubnet> vsubnets;
    private HashMap<Uuid, VirtualPort> vintfs;
    private HashMap<Uuid, VirtualPort> vrouterv6IntfMap;
    private HashMap<Uuid, List<VirtualPort>> unprocessedRouterIntfs;
    private HashMap<Uuid, List<VirtualPort>> unprocessedSubnetIntfs;
    private OdlInterfaceRpcService interfaceManagerRpc;
    private IElanService elanProvider;
    private IMdsalApiManager mdsalUtil;
    private Ipv6ServiceUtils ipv6ServiceUtils;
    private DataBroker dataBroker;

    private static IfMgr ifMgr;
    private Ipv6ServiceUtils ipv6Utils = Ipv6ServiceUtils.getInstance();

    private IfMgr() {
        init();
    }

    void init() {
        this.vrouters = new HashMap<>();
        this.vnetworks = new HashMap<>();
        this.vsubnets = new HashMap<>();
        this.vintfs = new HashMap<>();
        this.vrouterv6IntfMap = new HashMap<>();
        this.unprocessedRouterIntfs = new HashMap<>();
        this.unprocessedSubnetIntfs = new HashMap<>();
        this.ipv6ServiceUtils = new Ipv6ServiceUtils();
        LOG.info("IfMgr is enabled");
    }

    public static IfMgr getIfMgrInstance() {
        if (ifMgr == null) {
            ifMgr = new IfMgr();
        }
        return ifMgr;
    }

    public static void setIfMgrInstance(IfMgr ifMgr) {
        IfMgr.ifMgr = ifMgr;
    }

    public void setElanProvider(IElanService elanProvider) {
        this.elanProvider = elanProvider;
    }

    public void setDataBroker(DataBroker dataBroker) {
        this.dataBroker = dataBroker;
    }

    public void setMdsalUtilManager(IMdsalApiManager mdsalUtil) {
        this.mdsalUtil = mdsalUtil;
    }

    public void setInterfaceManagerRpc(OdlInterfaceRpcService interfaceManagerRpc) {
        LOG.trace("Registered interfaceManager successfully");
        this.interfaceManagerRpc = interfaceManagerRpc;
    }

    /**
     * Add router.
     *
     * @param rtrUuid router uuid
     * @param rtrName router name
     * @param tenantId tenant id
     * @param isAdminStateUp admin up
     */
    public void addRouter(Uuid rtrUuid, String rtrName, Uuid tenantId, Boolean isAdminStateUp) {

        VirtualRouter rtr = new VirtualRouter();
        if (rtr != null) {
            rtr.setTenantID(tenantId)
                    .setRouterUUID(rtrUuid)
                    .setName(rtrName);
            vrouters.put(rtrUuid, rtr);

            List<VirtualPort> intfList = unprocessedRouterIntfs.get(rtrUuid);

            if (intfList == null) {
                LOG.info("No unprocessed interfaces for the router {}", rtrUuid);
                return;
            }

            for (VirtualPort intf : intfList) {
                if (intf != null) {
                    intf.setRouter(rtr);
                    rtr.addInterface(intf);

                    for (VirtualSubnet snet : intf.getSubnets()) {
                        rtr.addSubnet(snet);
                    }
                }
            }

            removeUnprocessed(unprocessedRouterIntfs, rtrUuid);

        } else {
            LOG.error("Create router failed for :{}", rtrUuid);
        }

        return;
    }

    /**
     * Remove Router.
     *
     * @param rtrUuid router uuid
     */
    public void removeRouter(Uuid rtrUuid) {

        VirtualRouter rtr = vrouters.get(rtrUuid);
        if (rtr != null) {
            rtr.removeSelf();
            vrouters.remove(rtrUuid);
            removeUnprocessed(unprocessedRouterIntfs, rtrUuid);
            rtr = null;
        } else {
            LOG.error("Delete router failed for :{}", rtrUuid);
        }
        return;
    }

    /**
     * Add Subnet.
     *
     * @param snetId subnet id
     * @param name subnet name
     * @param networkId network id
     * @param tenantId tenant id
     * @param gatewayIp gateway ip address
     * @param ipVersion IP Version "IPv4 or IPv6"
     * @param subnetCidr subnet CIDR
     * @param ipV6AddressMode Address Mode of IPv6 Subnet
     * @param ipV6RaMode RA Mode of IPv6 Subnet.
     */
    public void addSubnet(Uuid snetId, String name, Uuid networkId, Uuid tenantId,
                          IpAddress gatewayIp, String ipVersion, IpPrefix subnetCidr,
                          String ipV6AddressMode, String ipV6RaMode) {

        // Save the gateway ipv6 address in its fully expanded format. We always store the v6Addresses
        // in expanded form and are used during Neighbor Discovery Support.
        if (gatewayIp != null) {
            Ipv6Address addr = new Ipv6Address(InetAddresses
                    .forString(gatewayIp.getIpv6Address().getValue()).getHostAddress());
            gatewayIp = new IpAddress(addr);
        }

        VirtualSubnet snet = new VirtualSubnet();
        if (snet != null) {
            snet.setTenantID(tenantId)
                    .setSubnetUUID(snetId)
                    .setName(name)
                    .setGatewayIp(gatewayIp)
                    .setIPVersion(ipVersion)
                    .setSubnetCidr(subnetCidr)
                    .setIpv6AddressMode(ipV6AddressMode)
                    .setIpv6RAMode(ipV6RaMode);

            vsubnets.put(snetId, snet);

            List<VirtualPort> intfList = unprocessedSubnetIntfs.get(snetId);
            if (intfList == null) {
                LOG.info("No unprocessed interfaces for the subnet {}", snetId);
                return;
            }
            for (VirtualPort intf : intfList) {
                if (intf != null) {
                    intf.setSubnet(snetId, snet);
                    snet.addInterface(intf);

                    VirtualRouter rtr = intf.getRouter();
                    if (rtr != null) {
                        rtr.addSubnet(snet);
                    }
                }
            }

            removeUnprocessed(unprocessedSubnetIntfs, snetId);

        } else {
            LOG.error("Create subnet failed for :{}", snetId);
        }
        return;
    }

    /**
     * Remove Subnet.
     *
     * @param snetId subnet id
     */
    public void removeSubnet(Uuid snetId) {

        VirtualSubnet snet = vsubnets.get(snetId);
        if (snet != null) {
            snet.removeSelf();
            vsubnets.remove(snetId);
            removeUnprocessed(unprocessedSubnetIntfs, snetId);
            snet = null;
        }
        return;
    }

    public void addRouterIntf(Uuid portId, Uuid rtrId, Uuid snetId,
                              Uuid networkId, IpAddress fixedIp, String macAddress,
                              String deviceOwner) {
        LOG.debug("addRouterIntf portId {}, rtrId {}, snetId {}, networkId {}, ip {}, mac {}",
            portId, rtrId, snetId, networkId, fixedIp, macAddress);
        //Save the interface ipv6 address in its fully expanded format
        Ipv6Address addr = new Ipv6Address(InetAddresses
                .forString(fixedIp.getIpv6Address().getValue()).getHostAddress());
        fixedIp = new IpAddress(addr);

        VirtualPort intf = vintfs.get(portId);
        boolean newIntf = false;
        if (intf == null) {
            intf = new VirtualPort();
            if (intf != null) {
                vintfs.put(portId, intf);
            } else {
                LOG.error("Create rtr intf failed for :{}", portId);
                return;
            }
            intf.setIntfUUID(portId)
                    .setSubnetInfo(snetId, fixedIp)
                    .setNetworkID(networkId)
                    .setMacAddress(macAddress)
                    .setRouterIntfFlag(true)
                    .setDeviceOwner(deviceOwner);
            intf.setPeriodicTimer();
            newIntf = true;
            MacAddress ifaceMac = MacAddress.getDefaultInstance(macAddress);
            Ipv6Address llAddr = ipv6Utils.getIpv6LinkLocalAddressFromMac(ifaceMac);
            /* A new router interface is created. This is basically triggered when an
            IPv6 subnet is associated to the router. Check if network is already hosting
            any VMs. If so, on all the hosts that have VMs on the network, program the
            icmpv6 punt flows in IPV6_TABLE(45).
             */
            programIcmpv6RSPuntFlows(intf, Ipv6Constants.ADD_FLOW);
            programIcmpv6NSPuntFlowForAddress(intf, llAddr, Ipv6Constants.ADD_FLOW);
        } else {
            intf.setSubnetInfo(snetId, fixedIp);
        }

        VirtualRouter rtr = vrouters.get(rtrId);
        VirtualSubnet snet = vsubnets.get(snetId);

        if (rtr != null && snet != null) {
            snet.setRouter(rtr);
            intf.setSubnet(snetId, snet);
            rtr.addSubnet(snet);
        } else if (snet != null) {
            intf.setSubnet(snetId, snet);
            addUnprocessed(unprocessedRouterIntfs, rtrId, intf);
        } else {
            addUnprocessed(unprocessedRouterIntfs, rtrId, intf);
            addUnprocessed(unprocessedSubnetIntfs, snetId, intf);
        }

        vrouterv6IntfMap.put(networkId, intf);
        programIcmpv6NSPuntFlowForAddress(intf, fixedIp.getIpv6Address(), Ipv6Constants.ADD_FLOW);

        if (newIntf) {
            LOG.debug("start the periodic RA Timer for routerIntf {}", portId);
            transmitUnsolicitedRA(intf);
        }
        return;
    }

    public void updateRouterIntf(Uuid portId, Uuid rtrId, List<FixedIps> fixedIpsList) {
        LOG.debug("updateRouterIntf portId {}, fixedIpsList {} ", portId, fixedIpsList);
        VirtualPort intf = vintfs.get(portId);
        if (intf == null) {
            LOG.info("Skip Router interface update for non-ipv6 port {}", portId);
            return;
        }

        List<Ipv6Address> existingIPv6AddressList = intf.getIpv6AddressesWithoutLLA();
        List<Ipv6Address> newlyAddedIpv6AddressList = new ArrayList<>();
        intf.clearSubnetInfo();
        for (FixedIps fip : fixedIpsList) {
            IpAddress fixedIp = fip.getIpAddress();

            if (fixedIp.getIpv4Address() != null) {
                continue;
            }

            //Save the interface ipv6 address in its fully expanded format
            Ipv6Address addr = new Ipv6Address(InetAddresses
                    .forString(fixedIp.getIpv6Address().getValue()).getHostAddress());
            fixedIp = new IpAddress(addr);
            intf.setSubnetInfo(fip.getSubnetId(), fixedIp);

            VirtualRouter rtr = vrouters.get(rtrId);
            VirtualSubnet snet = vsubnets.get(fip.getSubnetId());

            if (rtr != null && snet != null) {
                snet.setRouter(rtr);
                intf.setSubnet(fip.getSubnetId(), snet);
                rtr.addSubnet(snet);
            } else if (snet != null) {
                intf.setSubnet(fip.getSubnetId(), snet);
                addUnprocessed(unprocessedRouterIntfs, rtrId, intf);
            } else {
                addUnprocessed(unprocessedRouterIntfs, rtrId, intf);
                addUnprocessed(unprocessedSubnetIntfs, fip.getSubnetId(), intf);
            }
            vrouterv6IntfMap.put(intf.getNetworkID(), intf);

            if (existingIPv6AddressList.contains(fixedIp.getIpv6Address())) {
                existingIPv6AddressList.remove(fixedIp.getIpv6Address());
            } else {
                newlyAddedIpv6AddressList.add(fixedIp.getIpv6Address());
            }
        }

        /* This is a port update event for routerPort. Check if any IPv6 subnet is added
         or removed from the router port. Depending on subnet added/removed, we add/remove
         the corresponding flows from IPV6_TABLE(45).
         */
        for (Ipv6Address ipv6Address: newlyAddedIpv6AddressList) {
            // Some v6 subnets are associated to the routerPort add the corresponding NS Flows.
            programIcmpv6NSPuntFlowForAddress(intf, ipv6Address, Ipv6Constants.ADD_FLOW);
        }

        for (Ipv6Address ipv6Address: existingIPv6AddressList) {
            // Some v6 subnets are disassociated from the routerPort, remove the corresponding NS Flows.
            programIcmpv6NSPuntFlowForAddress(intf, ipv6Address, Ipv6Constants.DEL_FLOW);
        }
        return;
    }

    public void addHostIntf(Uuid portId, Uuid snetId, Uuid networkId,
                            IpAddress fixedIp, String macAddress, String deviceOwner) {
        LOG.debug("addHostIntf portId {}, snetId {}, networkId {}, ip {}, mac {}",
            portId, snetId, networkId, fixedIp, macAddress);

        //Save the interface ipv6 address in its fully expanded format
        Ipv6Address addr = new Ipv6Address(InetAddresses
                .forString(fixedIp.getIpv6Address().getValue()).getHostAddress());
        fixedIp = new IpAddress(addr);
        VirtualPort intf = vintfs.get(portId);
        if (intf == null) {
            intf = new VirtualPort();
            if (intf != null) {
                vintfs.put(portId, intf);
            } else {
                LOG.error("Create host intf failed for :{}", portId);
                return;
            }
            intf.setIntfUUID(portId)
                    .setSubnetInfo(snetId, fixedIp)
                    .setNetworkID(networkId)
                    .setMacAddress(macAddress)
                    .setRouterIntfFlag(false)
                    .setDeviceOwner(deviceOwner);
            Long elanTag = getNetworkElanTag(networkId);
            // Do service binding for the port and set the serviceBindingStatus to true.
            ipv6ServiceUtils.bindIpv6Service(dataBroker, portId.getValue(), elanTag, NwConstants.IPV6_TABLE);
            intf.setServiceBindingStatus(Boolean.TRUE);
        } else {
            intf.setSubnetInfo(snetId, fixedIp);
        }

        VirtualSubnet snet = vsubnets.get(snetId);

        if (snet != null) {
            intf.setSubnet(snetId, snet);
        } else {
            addUnprocessed(unprocessedSubnetIntfs, snetId, intf);
        }
        return;
    }

    public void updateHostIntf(Uuid portId, List<FixedIps> fixedIpsList) {
        LOG.debug("updateHostIntf portId {}, fixedIpsList {} ", portId, fixedIpsList);
        Boolean portIncludesV6Address = Boolean.FALSE;

        VirtualPort intf = vintfs.get(portId);
        if (intf == null) {
            LOG.warn("Update Host interface failed. Could not get Host interface details {}", portId);
            return;
        }

        intf.clearSubnetInfo();
        for (FixedIps fip : fixedIpsList) {
            IpAddress fixedIp = fip.getIpAddress();
            if (fixedIp.getIpv4Address() != null) {
                continue;
            }
            portIncludesV6Address = Boolean.TRUE;
            //Save the interface ipv6 address in its fully expanded format
            Ipv6Address addr = new Ipv6Address(InetAddresses
                    .forString(fixedIp.getIpv6Address().getValue()).getHostAddress());
            fixedIp = new IpAddress(addr);

            intf.setSubnetInfo(fip.getSubnetId(), fixedIp);

            VirtualSubnet snet = vsubnets.get(fip.getSubnetId());

            if (snet != null) {
                intf.setSubnet(fip.getSubnetId(), snet);
            } else {
                addUnprocessed(unprocessedSubnetIntfs, fip.getSubnetId(), intf);
            }
        }

        /* If the VMPort initially included an IPv6 address (along with IPv4 address) and IPv6 address
         was removed, we will have to unbind the service on the VM port. Similarly we do a ServiceBind
         if required.
          */
        if (portIncludesV6Address) {
            if (intf.getServiceBindingStatus() == Boolean.FALSE) {
                Long elanTag = getNetworkElanTag(intf.getNetworkID());
                ipv6ServiceUtils.bindIpv6Service(dataBroker, portId.getValue(), elanTag, NwConstants.IPV6_TABLE);
                intf.setServiceBindingStatus(Boolean.TRUE);
            }
        } else {
            ipv6ServiceUtils.unbindIpv6Service(dataBroker, portId.getValue());
            intf.setServiceBindingStatus(Boolean.FALSE);
        }
        return;
    }

    public void updateInterface(Uuid portId, BigInteger dpId, Long ofPort) {
        LOG.debug("in updateInterface portId {}, dpId {}, ofPort {}",
            portId, dpId, ofPort);
        VirtualPort intf = vintfs.get(portId);

        if (intf == null) {
            intf = new VirtualPort();
            intf.setIntfUUID(portId);
            if (intf != null) {
                vintfs.put(portId, intf);
            } else {
                LOG.error("updateInterface failed for :{}", portId);
            }
        }

        if (intf != null) {
            intf.setDpId(dpId.toString())
                    .setOfPort(ofPort);
        }

        // Update the network <--> List[dpnIds, List<ports>] cache.
        VirtualNetwork vnet = vnetworks.get(intf.getNetworkID());
        if (null != vnet) {
            vnet.updateDpnPortInfo(dpId, ofPort, Ipv6Constants.ADD_ENTRY);
        }

        return;
    }

    public void removePort(Uuid portId) {
        VirtualPort intf = vintfs.get(portId);
        if (intf != null) {
            intf.removeSelf();
            if (intf.getDeviceOwner().equalsIgnoreCase(Ipv6Constants.NETWORK_ROUTER_INTERFACE)) {
                MacAddress ifaceMac = MacAddress.getDefaultInstance(intf.getMacAddress());
                Ipv6Address llAddr = ipv6Utils.getIpv6LinkLocalAddressFromMac(ifaceMac);
                vrouterv6IntfMap.remove(intf.getNetworkID(), intf);
                /* Router port is deleted. Remove the corresponding icmpv6 punt flows on all
                the dpnIds which were hosting the VMs on the network.
                 */
                programIcmpv6RSPuntFlows(intf, Ipv6Constants.DEL_FLOW);
                for (Ipv6Address ipv6Address: intf.getIpv6Addresses()) {
                    programIcmpv6NSPuntFlowForAddress(intf, ipv6Address, Ipv6Constants.DEL_FLOW);
                }
                transmitRouterAdvertisement(intf, Ipv6RtrAdvertType.CEASE_ADVERTISEMENT);
                Ipv6TimerWheel timer = Ipv6TimerWheel.getInstance();
                timer.cancelPeriodicTransmissionTimeout(intf.getPeriodicTimeout());
                intf.resetPeriodicTimeout();
                LOG.debug("Reset the periodic RA Timer for intf {}", intf.getIntfUUID());
            } else {
                // Remove the serviceBinding entry for the port.
                ipv6ServiceUtils.unbindIpv6Service(dataBroker, portId.getValue());
                // Remove the portId from the (network <--> List[dpnIds, List <ports>]) cache.
                VirtualNetwork vnet = vnetworks.get(intf.getNetworkID());
                if (null != vnet) {
                    BigInteger dpId = ipv6ServiceUtils.getDataPathId(intf.getDpId());
                    vnet.updateDpnPortInfo(dpId, intf.getOfPort(), Ipv6Constants.DEL_ENTRY);
                }
            }
            vintfs.remove(portId);
            intf = null;
        }
        return;
    }

    public void deleteInterface(Uuid interfaceUuid, String dpId) {
        // Nothing to do for now
        return;
    }

    public void addUnprocessed(HashMap<Uuid, List<VirtualPort>> unprocessed, Uuid id, VirtualPort intf) {

        List<VirtualPort> intfList = unprocessed.get(id);

        if (intfList == null) {
            intfList = new ArrayList();
            intfList.add(intf);
            unprocessed.put(id, intfList);
        } else {
            intfList.add(intf);
        }
        return;
    }

    public void removeUnprocessed(HashMap<Uuid, List<VirtualPort>> unprocessed, Uuid id) {

        List<VirtualPort> intfList = unprocessed.get(id);
        intfList = null;
        return;
    }

    public VirtualPort getRouterV6InterfaceForNetwork(Uuid networkId) {
        LOG.debug("obtaining the virtual interface for {}", networkId);
        return (vrouterv6IntfMap.get(networkId));
    }

    public VirtualPort obtainV6Interface(Uuid id) {
        VirtualPort intf = vintfs.get(id);
        if (intf == null) {
            return null;
        }
        for (VirtualSubnet snet : intf.getSubnets()) {
            if (snet.getIpVersion().equals(Ipv6Constants.IP_VERSION_V6)) {
                return intf;
            }
        }
        return null;
    }

    private void programIcmpv6RSPuntFlows(VirtualPort routerPort, int action) {
        Long elanTag = getNetworkElanTag(routerPort.getNetworkID());
        int flowStatus;
        VirtualNetwork vnet = vnetworks.get(routerPort.getNetworkID());
        if (vnet != null) {
            List<BigInteger> dpnList = vnet.getDpnsHostingNetwork();
            for (BigInteger dpId : dpnList) {
                flowStatus = vnet.getRSPuntFlowStatusOnDpnId(dpId);
                if (action == Ipv6Constants.ADD_FLOW && flowStatus == Ipv6Constants.FLOWS_NOT_CONFIGURED) {
                    ipv6ServiceUtils.installIcmpv6RsPuntFlow(NwConstants.IPV6_TABLE, dpId, elanTag,
                            mdsalUtil, Ipv6Constants.ADD_FLOW);
                    vnet.setRSPuntFlowStatusOnDpnId(dpId, Ipv6Constants.FLOWS_CONFIGURED);
                } else if (action == Ipv6Constants.DEL_FLOW && flowStatus == Ipv6Constants.FLOWS_CONFIGURED) {
                    ipv6ServiceUtils.installIcmpv6RsPuntFlow(NwConstants.IPV6_TABLE, dpId, elanTag,
                            mdsalUtil, Ipv6Constants.DEL_FLOW);
                    vnet.setRSPuntFlowStatusOnDpnId(dpId, Ipv6Constants.FLOWS_NOT_CONFIGURED);
                }
            }
        }
    }

    private void programIcmpv6NSPuntFlowForAddress(VirtualPort routerPort, Ipv6Address ipv6Address, int action) {
        Long elanTag = getNetworkElanTag(routerPort.getNetworkID());
        VirtualNetwork vnet = vnetworks.get(routerPort.getNetworkID());
        if (vnet != null) {
            Collection<VirtualNetwork.DpnInterfaceInfo> dpnIfaceList = vnet.getDpnIfaceList();
            for (VirtualNetwork.DpnInterfaceInfo dpnIfaceInfo : dpnIfaceList) {
                if (action == Ipv6Constants.ADD_FLOW && !dpnIfaceInfo.ndTargetFlowsPunted.contains(ipv6Address)) {
                    ipv6ServiceUtils.installIcmpv6NsPuntFlow(NwConstants.IPV6_TABLE, dpnIfaceInfo.getDpId(),
                            elanTag, ipv6Address.getValue(), mdsalUtil, Ipv6Constants.ADD_FLOW);
                    dpnIfaceInfo.updateNDTargetAddress(ipv6Address, action);
                } else if (action == Ipv6Constants.DEL_FLOW && dpnIfaceInfo.ndTargetFlowsPunted.contains(ipv6Address)) {
                    ipv6ServiceUtils.installIcmpv6NsPuntFlow(NwConstants.IPV6_TABLE, dpnIfaceInfo.getDpId(),
                            elanTag, ipv6Address.getValue(), mdsalUtil, Ipv6Constants.DEL_FLOW);
                    dpnIfaceInfo.updateNDTargetAddress(ipv6Address, action);
                }
            }
        }
    }

    public void programIcmpv6PuntFlowsIfNecessary(Uuid vmPortId, BigInteger dpId, VirtualPort routerPort) {
        VirtualPort vmPort = vintfs.get(vmPortId);
        if (null != vmPort) {
            VirtualNetwork vnet = vnetworks.get(vmPort.getNetworkID());
            if (null != vnet) {
                VirtualNetwork.DpnInterfaceInfo dpnInfo = vnet.getDpnIfaceInfo(dpId);
                if (null != dpnInfo) {
                    Long elanTag = getNetworkElanTag(routerPort.getNetworkID());
                    if (vnet.getRSPuntFlowStatusOnDpnId(dpId) == Ipv6Constants.FLOWS_NOT_CONFIGURED) {
                        ipv6ServiceUtils.installIcmpv6RsPuntFlow(NwConstants.IPV6_TABLE, dpId, elanTag,
                                mdsalUtil, Ipv6Constants.ADD_FLOW);
                        vnet.setRSPuntFlowStatusOnDpnId(dpId, Ipv6Constants.FLOWS_CONFIGURED);
                    }

                    for (Ipv6Address ipv6Address: routerPort.getIpv6Addresses()) {
                        if (!dpnInfo.ndTargetFlowsPunted.contains(ipv6Address)) {
                            ipv6ServiceUtils.installIcmpv6NsPuntFlow(NwConstants.IPV6_TABLE, dpId,
                                    elanTag, ipv6Address.getValue(), mdsalUtil, Ipv6Constants.ADD_FLOW);
                            dpnInfo.updateNDTargetAddress(ipv6Address, Ipv6Constants.ADD_FLOW);
                        }
                    }
                }
            }
        }
    }

    public String getInterfaceNameFromTag(long portTag) {
        String interfaceName = null;
        GetInterfaceFromIfIndexInput input = new GetInterfaceFromIfIndexInputBuilder()
                .setIfIndex(new Integer((int)portTag)).build();
        Future<RpcResult<GetInterfaceFromIfIndexOutput>> futureOutput =
                interfaceManagerRpc.getInterfaceFromIfIndex(input);
        try {
            GetInterfaceFromIfIndexOutput output = futureOutput.get().getResult();
            interfaceName = output.getInterfaceName();
        } catch (InterruptedException | ExecutionException e) {
            LOG.error("Error while retrieving the interfaceName from tag using getInterfaceFromIfIndex RPC");
        }
        LOG.trace("Returning interfaceName {} for tag {} form getInterfaceNameFromTag", interfaceName, portTag);
        return interfaceName;
    }

    public Long updateNetworkElanTag(Uuid networkId) {
        Long elanTag = null;
        if (null != this.elanProvider) {
            ElanInstance elanInstance = this.elanProvider.getElanInstance(networkId.getValue());
            if (null != elanInstance) {
                elanTag = elanInstance.getElanTag();
                VirtualNetwork net = vnetworks.get(networkId);
                if (null != net) {
                    net.setElanTag(elanTag);
                }
            }
        }
        return elanTag;
    }

    public Long getNetworkElanTag(Uuid networkId) {
        Long elanTag = null;
        VirtualNetwork net = vnetworks.get(networkId);
        if (null != net) {
            elanTag = net.getElanTag();
            if (null == elanTag) {
                elanTag = updateNetworkElanTag(networkId);
            }
        }
        return elanTag;
    }

    public void addNetwork(Uuid networkId) {
        VirtualNetwork net = vnetworks.get(networkId);
        if (null == net) {
            net = new VirtualNetwork();
            net.setNetworkUuid(networkId);
            vnetworks.put(networkId, net);
            updateNetworkElanTag(networkId);
        }
    }

    public void removeNetwork(Uuid networkId) {
        // Delete the network and the corresponding dpnIds<-->List(ports) cache.
        VirtualNetwork net = vnetworks.get(networkId);
        if (null == net) {
            net.removeSelf();
            vnetworks.remove(networkId);
            net = null;
        }
    }

    private void transmitRouterAdvertisement(VirtualPort intf, Ipv6RtrAdvertType advType) {
        Ipv6RouterAdvt ipv6RouterAdvert = new Ipv6RouterAdvt();

        LOG.debug("in transmitRouterAdvertisement for {}", advType);
        VirtualNetwork vnet = vnetworks.get(intf.getNetworkID());
        if (vnet != null) {
            String nodeName;
            String outPort;
            Collection<VirtualNetwork.DpnInterfaceInfo> dpnIfaceList = vnet.getDpnIfaceList();
            for (VirtualNetwork.DpnInterfaceInfo dpnIfaceInfo : dpnIfaceList) {
                nodeName = Ipv6Constants.OPENFLOW_NODE_PREFIX + dpnIfaceInfo.getDpId();
                List<NodeConnectorRef> ncRefList = new ArrayList<>();
                for (Long ofPort: dpnIfaceInfo.ofPortList) {
                    outPort = nodeName + ":" + ofPort;
                    LOG.debug("Transmitting RA {} for node {}, port {}", advType, nodeName, outPort);
                    InstanceIdentifier<NodeConnector> outPortId = InstanceIdentifier.builder(Nodes.class)
                            .child(Node.class, new NodeKey(new NodeId(nodeName)))
                            .child(NodeConnector.class, new NodeConnectorKey(new NodeConnectorId(outPort)))
                            .build();
                    ncRefList.add(new NodeConnectorRef(outPortId));
                }
                if (!ncRefList.isEmpty()) {
                    ipv6RouterAdvert.transmitRtrAdvertisement(advType, intf, ncRefList, null);
                }
            }
        }
    }

    public void transmitUnsolicitedRA(Uuid portId) {
        VirtualPort port = vintfs.get(portId);
        LOG.debug("in transmitUnsolicitedRA for {}, port", portId, port);
        if (port != null) {
            transmitUnsolicitedRA(port);
        }
    }

    public void transmitUnsolicitedRA(VirtualPort port) {
        transmitRouterAdvertisement(port, Ipv6RtrAdvertType.UNSOLICITED_ADVERTISEMENT);
        Ipv6TimerWheel timer = Ipv6TimerWheel.getInstance();
        Timeout portTimeout = timer.setPeriodicTransmissionTimeout(port.getPeriodicTimer(),
                                                                   Ipv6Constants.PERIODIC_RA_INTERVAL,
                                                                   TimeUnit.SECONDS);
        port.setPeriodicTimeout(portTimeout);
        LOG.debug("re-started periodic RA Timer for routerIntf {}, int {}s", port.getIntfUUID(),
                   Ipv6Constants.PERIODIC_RA_INTERVAL);
    }
}
