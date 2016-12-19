/*
 * Copyright (c) 2015 - 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.vpnmanager.utilities;

import com.google.common.base.Optional;

import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.netvirt.vpnmanager.VpnUtil;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.Interfaces;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.InterfacesState;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.InterfaceKey;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.state.Interface;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.PhysAddress;
import org.opendaylight.yang.gen.v1.urn.opendaylight.flow.types.rev131026.instruction.list.Instruction;
import org.opendaylight.yang.gen.v1.urn.opendaylight.inventory.rev130819.NodeConnectorId;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rpcs.rev160406.GetDpidFromInterfaceInput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rpcs.rev160406.GetDpidFromInterfaceInputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rpcs.rev160406.GetDpidFromInterfaceOutput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rpcs.rev160406.OdlInterfaceRpcService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.servicebinding.rev160406.ServiceBindings;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.servicebinding.rev160406.ServiceTypeFlowBased;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.servicebinding.rev160406.StypeOpenflow;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.servicebinding.rev160406.StypeOpenflowBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.servicebinding.rev160406.ServiceModeIngress;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.servicebinding.rev160406.service.bindings.ServicesInfo;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.servicebinding.rev160406.service.bindings.ServicesInfoKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.servicebinding.rev160406.service.bindings.services.info.BoundServices;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.servicebinding.rev160406.service.bindings.services.info.BoundServicesBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.servicebinding.rev160406.service.bindings.services.info.BoundServicesKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.op.rev160406.DpnEndpoints;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.op.rev160406.dpn.endpoints.DPNTEPsInfo;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.op.rev160406.dpn.endpoints.DPNTEPsInfoKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.op.rev160406.dpn.endpoints.dpn.teps.info.TunnelEndPoints;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.opendaylight.yangtools.yang.common.RpcResult;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.math.BigInteger;
import java.util.List;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;

public class InterfaceUtils {
  private static final Logger LOG = LoggerFactory.getLogger(InterfaceUtils.class);
  private static String OF_URI_SEPARATOR = ":";

  public static BigInteger getDpnForInterface(OdlInterfaceRpcService interfaceManagerRpcService, String ifName) {
    BigInteger nodeId = BigInteger.ZERO;
    try {
      GetDpidFromInterfaceInput
          dpIdInput =
          new GetDpidFromInterfaceInputBuilder().setIntfName(ifName).build();
      Future<RpcResult<GetDpidFromInterfaceOutput>>
          dpIdOutput =
          interfaceManagerRpcService.getDpidFromInterface(dpIdInput);
      RpcResult<GetDpidFromInterfaceOutput> dpIdResult = dpIdOutput.get();
      if (dpIdResult.isSuccessful()) {
        nodeId = dpIdResult.getResult().getDpid();
      } else {
        LOG.error("Could not retrieve DPN Id for interface {}", ifName);
      }
    } catch (NullPointerException | InterruptedException | ExecutionException e) {
      LOG.error("Exception when getting dpn for interface {}", ifName,  e);
    }
    return nodeId;
  }

  public static String getEndpointIpAddressForDPN(DataBroker broker, BigInteger dpnId) {
    String nextHopIp = null;
    InstanceIdentifier<DPNTEPsInfo> tunnelInfoId =
        InstanceIdentifier.builder(DpnEndpoints.class).child(DPNTEPsInfo.class, new DPNTEPsInfoKey(dpnId)).build();
    Optional<DPNTEPsInfo> tunnelInfo = VpnUtil.read(broker, LogicalDatastoreType.CONFIGURATION, tunnelInfoId);
    if (tunnelInfo.isPresent()) {
      List<TunnelEndPoints> nexthopIpList = tunnelInfo.get().getTunnelEndPoints();
      if (nexthopIpList != null && !nexthopIpList.isEmpty()) {
        nextHopIp = nexthopIpList.get(0).getIpAddress().getIpv4Address().getValue();
      }
    }
    return nextHopIp;
  }

  public static InstanceIdentifier<BoundServices> buildServiceId(String vpnInterfaceName, short serviceIndex) {
    return InstanceIdentifier.builder(ServiceBindings.class).child(ServicesInfo.class, new ServicesInfoKey(vpnInterfaceName, ServiceModeIngress.class))
        .child(BoundServices.class, new BoundServicesKey(serviceIndex)).build();
  }

  public static BoundServices getBoundServices(String serviceName, short servicePriority, int flowPriority,
                                               BigInteger cookie, List<Instruction> instructions) {
    StypeOpenflowBuilder augBuilder = new StypeOpenflowBuilder().setFlowCookie(cookie).setFlowPriority(flowPriority).setInstruction(instructions);
    return new BoundServicesBuilder().setKey(new BoundServicesKey(servicePriority))
        .setServiceName(serviceName).setServicePriority(servicePriority)
        .setServiceType(ServiceTypeFlowBased.class).addAugmentation(StypeOpenflow.class, augBuilder.build()).build();
  }

  public static boolean isOperational(DataBroker dataBroker, String ifName) {
    return getInterfaceStateFromOperDS(dataBroker, ifName) != null;
  }

  public static InstanceIdentifier<Interface> buildStateInterfaceId(String interfaceName) {
    InstanceIdentifier.InstanceIdentifierBuilder<Interface> idBuilder =
        InstanceIdentifier.builder(InterfacesState.class)
            .child(org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.state.Interface.class,
                   new org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.state.InterfaceKey(interfaceName));
    InstanceIdentifier<org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.state.Interface> id = idBuilder.build();
    return id;
  }

  public static org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.state.Interface getInterfaceStateFromOperDS(DataBroker dataBroker, String interfaceName) {
    InstanceIdentifier<org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.state.Interface> ifStateId =
        buildStateInterfaceId(interfaceName);
    Optional<Interface> ifStateOptional =
        VpnUtil.read(dataBroker, LogicalDatastoreType.OPERATIONAL, ifStateId);
    if (ifStateOptional.isPresent()) {
      return ifStateOptional.get();
    }

    return null;
  }

  public static org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.Interface getInterface(DataBroker broker, String interfaceName) {
    Optional<org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.Interface> optInterface =
        VpnUtil.read(broker, LogicalDatastoreType.CONFIGURATION, getInterfaceIdentifier(interfaceName));
    if(optInterface.isPresent()) {
      return optInterface.get();
    }
    return null;
  }

  public static Optional<String> getMacAddressForInterface(DataBroker dataBroker, String interfaceName) {
      Optional<String> macAddressOptional = Optional.absent();
      InstanceIdentifier<org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.state.Interface> ifStateId =
              buildStateInterfaceId(interfaceName);
      Optional<Interface> ifStateOptional = VpnUtil.read(dataBroker, LogicalDatastoreType.OPERATIONAL, ifStateId);
      if (ifStateOptional.isPresent()) {
          PhysAddress macAddress = ifStateOptional.get().getPhysAddress();
          if (macAddress != null) {
              macAddressOptional = Optional.of(macAddress.getValue());
          }
      }
      return macAddressOptional;
  }

  public static InstanceIdentifier<org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.Interface> getInterfaceIdentifier(String interfaceName) {
    return InstanceIdentifier.builder(Interfaces.class)
        .child(
            org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.Interface.class, new InterfaceKey(interfaceName)).build();
  }

  public static String getDpnFromNodeConnectorId(NodeConnectorId portId) {
        /*
         * NodeConnectorId is of form 'openflow:dpnid:portnum'
         */
    String[] split = portId.getValue().split(OF_URI_SEPARATOR);
    return split[1];
  }

  public static BigInteger getDpIdFromInterface(org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.interfaces.rev140508.interfaces.state.Interface ifState) {
    String lowerLayerIf = ifState.getLowerLayerIf().get(0);
    NodeConnectorId nodeConnectorId = new NodeConnectorId(lowerLayerIf);
    return new BigInteger(getDpnFromNodeConnectorId(nodeConnectorId));
  }

}
