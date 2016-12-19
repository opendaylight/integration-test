/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

/*
 * Created eyugsar 2016/12/1
 */
package org.opendaylight.netvirt.natservice.internal;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.concurrent.Future;
import java.util.concurrent.ExecutionException;

import com.google.common.collect.Lists;
import org.apache.commons.net.util.SubnetUtils;
import org.apache.commons.net.util.SubnetUtils.SubnetInfo;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.mdsalutil.MDSALUtil;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.AllocateIdInput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.AllocateIdInputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.AllocateIdOutput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.CreateIdPoolInput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.CreateIdPoolInputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.DeleteIdPoolInput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.DeleteIdPoolInputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.IdManagerService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.ReleaseIdInput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.ReleaseIdInputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.ExternalIpsCounter;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.IntextIpMap;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.IntextIpPortMap;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.ProtocolTypes;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.SnatintIpPortMap;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.ext.routers.Routers;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.external.ips.counter.ExternalCounters;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.external.ips.counter.ExternalCountersKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.external.ips.counter.external.counters.ExternalIpCounter;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.external.ips.counter.external.counters.ExternalIpCounterKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.intext.ip.map.IpMapping;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.intext.ip.map.IpMappingKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.intext.ip.map.ip.mapping.IpMap;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.intext.ip.map.ip.mapping.IpMapBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.intext.ip.map.ip.mapping.IpMapKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.intext.ip.port.map.IpPortMapping;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.intext.ip.port.map.IpPortMappingKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.intext.ip.port.map.ip.port.mapping.IntextIpProtocolType;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.intext.ip.port.map.ip.port.mapping.IntextIpProtocolTypeKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.intext.ip.port.map.ip.port.mapping.intext.ip.protocol.type.IpPortMap;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.intext.ip.port.map.ip.port.mapping.intext.ip.protocol.type.IpPortMapBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.intext.ip.port.map.ip.port.mapping.intext.ip.protocol.type.IpPortMapKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.intext.ip.port.map.ip.port.mapping.intext.ip.protocol.type.ip.port.map.IpPortExternal;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.intext.ip.port.map.ip.port.mapping.intext.ip.protocol.type.ip.port.map.IpPortExternalBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.snatint.ip.port.map.IntipPortMap;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.snatint.ip.port.map.IntipPortMapKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.snatint.ip.port.map.intip.port.map.IpPort;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.snatint.ip.port.map.intip.port.map.IpPortKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.snatint.ip.port.map.intip.port.map.ip.port.IntIpProtoType;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.snatint.ip.port.map.intip.port.map.ip.port.IntIpProtoTypeBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.snatint.ip.port.map.intip.port.map.ip.port.IntIpProtoTypeKey;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier.InstanceIdentifierBuilder;
import org.opendaylight.yangtools.yang.common.RpcResult;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import  org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.natservice.rev160111.external.ips.counter.external.counters.ExternalIpCounterBuilder;

import com.google.common.base.Optional;
import com.google.common.util.concurrent.UncheckedExecutionException;

public class NaptManager  {
    private static final Logger LOG = LoggerFactory.getLogger(NaptManager.class);
    private final DataBroker dataBroker;
    private final IdManagerService idManager;
    private static final long LOW_PORT = 49152L;
    private static final long HIGH_PORT = 65535L;
    private static boolean EXTSUBNET_FLAG = false;
    private static boolean NEXT_EXTIP_FLAG = false;

    public NaptManager(final DataBroker dataBroker, final IdManagerService idManager) {
        this.dataBroker = dataBroker;
        this.idManager = idManager;
    }

    protected void createNaptPortPool(String PoolName) {
         LOG.debug("NAPT Service : createPortPool requested for : {}", PoolName);
         CreateIdPoolInput createPool = new CreateIdPoolInputBuilder()
             .setPoolName(PoolName)
             .setLow(LOW_PORT)
             .setHigh(HIGH_PORT)
             .build();
         try {
             Future<RpcResult<Void>> result = idManager.createIdPool(createPool);
             if ((result != null) && (result.get().isSuccessful())) {
                 LOG.debug("NAPT Service : Created PortPool");
             } else {
                 LOG.error("NAPT Service : Unable to create PortPool");
             }
         } catch (InterruptedException | ExecutionException e) {
             LOG.error("Failed to create PortPool for NAPT Service",e);
         }
    }

    void removeNaptPortPool(String poolName) {
        DeleteIdPoolInput deleteIdPoolInput = new DeleteIdPoolInputBuilder().setPoolName(poolName).build();
        LOG.debug("NAPT Service : Remove Napt port pool requested for : {}", poolName);
        try {
            Future<RpcResult<Void>> result = idManager.deleteIdPool(deleteIdPoolInput);
            if ((result != null) && (result.get().isSuccessful())) {
                LOG.debug("NAPT Service : Deleted PortPool {}", poolName);
            } else {
                LOG.error("NAPT Service : Unable to delete PortPool {}", poolName);
            }
        } catch (InterruptedException | ExecutionException e) {
            LOG.error("Failed to delete PortPool {} for NAPT Service", poolName, e);
        }
    }

     // 1. napt service functions
     /**
      * this method is used to inform this service of what external IP address to be used
      * as mapping when requested one for the internal IP address given in the input
      * @param segmentId – segmentation in which the mapping to be used. Eg; routerid
      * @param internal subnet prefix or ip address
      * @param external subnet prefix or ip address
      */

      public void registerMapping(long segmentId, IPAddress internal, IPAddress external) {

          LOG.debug("NAPT Service : registerMapping called with segmentid {}, internalIp {}, prefix {}, externalIp {} and prefix {} ", segmentId, internal.getIpAddress(),
                internal.getPrefixLength(), external.getIpAddress(), external.getPrefixLength());
        // Create Pool per ExternalIp and not for all IPs in the subnet. Create new Pools during getExternalAddressMapping if exhausted.
        String externalIpPool;
        if (external.getPrefixLength() !=0 && external.getPrefixLength() != NatConstants.DEFAULT_PREFIX) {  // subnet case
            String externalSubnet = new StringBuilder(64).append(external.getIpAddress()).append("/").append(external.getPrefixLength()).toString();
            LOG.debug("NAPT Service : externalSubnet is : {}", externalSubnet);
            SubnetUtils subnetUtils = new SubnetUtils(externalSubnet);
            SubnetInfo subnetInfo = subnetUtils.getInfo();
            externalIpPool = subnetInfo.getLowAddress();
        } else {  // ip case
            externalIpPool = external.getIpAddress();
        }
        createNaptPortPool(externalIpPool);

        // Store the ip to ip map in Operational DS
        String internalIp = internal.getIpAddress();
        if(internal.getPrefixLength() != 0) {
            internalIp =  new StringBuilder(64).append(internal.getIpAddress()).append("/").append(internal.getPrefixLength()).toString();
        }
        String externalIp = external.getIpAddress();
        if(external.getPrefixLength() != 0) {
            externalIp =  new StringBuilder(64).append(external.getIpAddress()).append("/").append(external.getPrefixLength()).toString();
        }
        updateCounter(segmentId, externalIp, true);
        //update the actual ip-map
        IpMap ipm = new IpMapBuilder().setKey(new IpMapKey(internalIp)).setInternalIp(internalIp).setExternalIp(externalIp).build();
        MDSALUtil.syncWrite(dataBroker, LogicalDatastoreType.OPERATIONAL, getIpMapIdentifier(segmentId, internalIp), ipm);
        LOG.debug("NAPT Service : registerMapping exit after updating DS with internalIP {}, externalIP {}", internalIp, externalIp);
     }

      public void updateCounter(long segmentId, String externalIp, boolean isAdd){
          short counter = 0;
          InstanceIdentifier<ExternalIpCounter> id = InstanceIdentifier.builder(ExternalIpsCounter.class).child(ExternalCounters.class, new ExternalCountersKey(segmentId)).child(ExternalIpCounter.class, new ExternalIpCounterKey(externalIp)).build();
          Optional <ExternalIpCounter> externalIpCounter = MDSALUtil.read(dataBroker, LogicalDatastoreType.OPERATIONAL, id);
          if (externalIpCounter.isPresent()) {
              counter = externalIpCounter.get().getCounter();
              if(isAdd){
                  counter++;
                  LOG.debug("NAT Service : externalIp and counter after increment are {} and {}", externalIp, counter);
              }else{
                  if(counter > 0){
                    counter--;
                  }
                  LOG.debug("NAT Service : externalIp and counter after decrement are {} and {}", externalIp, counter);
              }

          }else if(isAdd){
              counter = 1;
          }

          //update the new counter value for this externalIp
          ExternalIpCounter externalIpCounterData = new ExternalIpCounterBuilder().setKey(new ExternalIpCounterKey(externalIp)).setExternalIp(externalIp).setCounter(counter).build();
          MDSALUtil.syncWrite(dataBroker, LogicalDatastoreType.OPERATIONAL, getExternalIpsIdentifier(segmentId, externalIp), externalIpCounterData);

      }

     /**
      * method to get external ip/port mapping when provided with internal ip/port pair
      * If already a mapping exist for the given input, then the existing mapping is returned
      * instead of overwriting with new ip/port pair.
      * @param segmentId - Router ID
      * @param sourceAddress - internal ip address/port pair
      * @param protocol - TCP/UDP
      * @return external ip address/port
      */
     public SessionAddress getExternalAddressMapping(long segmentId, SessionAddress sourceAddress, NAPTEntryEvent.Protocol protocol) {
         LOG.debug("NAPT Service : getExternalAddressMapping called with segmentId {}, internalIp {} and port {}",
                 segmentId, sourceAddress.getIpAddress(), sourceAddress.getPortNumber());
        /*
         1. Get Internal IP, Port in IP:Port format
         2. Inside DB with routerId get the list of entries and check if it matches with existing IP:Port
         3. If True return SessionAddress of ExternalIp and Port
         4. Else check ip Map and Form the ExternalIp and Port and update DB and then return ExternalIp and Port
         */

         //SessionAddress externalIpPort = new SessionAddress();
         String internalIpPort = new StringBuilder(64).append(sourceAddress.getIpAddress()).append(":").append(sourceAddress.getPortNumber()).toString();

         // First check existing Port Map.
         SessionAddress existingIpPort = checkIpPortMap(segmentId, internalIpPort, protocol);
         if(existingIpPort != null) {
             // populate externalIpPort from IpPortMap and return
             LOG.debug("NAPT Service : getExternalAddressMapping successfully returning existingIpPort as {} and {}", existingIpPort.getIpAddress(), existingIpPort.getPortNumber());
             return existingIpPort;
         } else {
             // Now check in ip-map
             String externalIp = checkIpMap(segmentId, sourceAddress.getIpAddress());
             if(externalIp == null) {
                 LOG.error("NAPT Service : getExternalAddressMapping, Unexpected error, internal to external ip map does not exist");
                 return null;
             } else {
                 /* Logic assuming internalIp is always ip and not subnet
                  * case 1: externalIp is ip
                  *        a) goto externalIp pool and getPort and return
                  *        b) else return error
                  * case 2: externalIp is subnet
                  *        a) Take first externalIp and goto that Pool and getPort
                  *             if port -> return
                  *             else Take second externalIp and create that Pool and getPort
                  *             if port ->return
                  *             else
                  *             Continue same with third externalIp till we exhaust subnet
                  *        b) Nothing worked return error
                  */
                 SubnetUtils externalIpSubnet;
                 List<String> allIps = new ArrayList<>();
                 String subnetPrefix = "/" + String.valueOf(NatConstants.DEFAULT_PREFIX);
                 if( !externalIp.contains(subnetPrefix) ) {
                    EXTSUBNET_FLAG = true;
                    externalIpSubnet = new SubnetUtils(externalIp);
                    allIps = Arrays.asList(externalIpSubnet.getInfo().getAllAddresses());
                    LOG.debug("NAPT Service : total count of externalIps available {}", externalIpSubnet.getInfo().getAddressCount());
                 } else {
                     LOG.debug("NAPT Service : getExternalAddress single ip case");
                     if(externalIp.contains(subnetPrefix)) {
                         String[] externalIpSplit = externalIp.split("/");
                         String extIp = externalIpSplit[0];
                         externalIp = extIp; //remove /32 what we got from checkIpMap
                     }
                     allIps.add(externalIp);
                 }

                 for(String extIp : allIps) {
                    LOG.info("NAPT Service : Looping externalIPs with externalIP now as {}", extIp);
                    if(NEXT_EXTIP_FLAG) {
                        createNaptPortPool(extIp);
                        LOG.debug("NAPT Service : Created Pool for next Ext IP {}", extIp);
                    }
                    AllocateIdInput getIdInput = new AllocateIdInputBuilder()
                        .setPoolName(extIp).setIdKey(internalIpPort)
                        .build();
                     try {
                        Future<RpcResult<AllocateIdOutput>> result = idManager.allocateId(getIdInput);
                        RpcResult<AllocateIdOutput> rpcResult;
                        if ((result != null) && (result.get().isSuccessful())) {
                            LOG.debug("NAPT Service : Got id from idManager");
                            rpcResult = result.get();
                        } else {
                            LOG.error("NAPT Service : getExternalAddressMapping, idManager could not allocate id retry if subnet");
                            if(!EXTSUBNET_FLAG) {
                                LOG.error("NAPT Service : getExternalAddressMapping returning null for single IP case, may be ports exhausted");
                                return null;
                            }
                            LOG.debug("NAPT Service : Could be ports exhausted case, try with another externalIP if possible");
                            NEXT_EXTIP_FLAG = true;
                            continue;
                        }
                        int extPort= rpcResult.getResult().getIdValue().intValue();
                        SessionAddress externalIpPort = new SessionAddress(extIp, extPort);
                        // Write to ip-port-map before returning
                        IpPortExternalBuilder ipExt = new IpPortExternalBuilder();
                        IpPortExternal ipPortExt = ipExt.setIpAddress(extIp).setPortNum(extPort).build();
                        IpPortMap ipm = new IpPortMapBuilder().setKey(new IpPortMapKey(internalIpPort))
                                .setIpPortInternal(internalIpPort).setIpPortExternal(ipPortExt).build();
                        LOG.debug("NAPT Service : getExternalAddressMapping writing into ip-port-map with externalIP {} and port {}",
                                ipPortExt.getIpAddress(), ipPortExt.getPortNum());
                        try {
                            MDSALUtil.syncWrite(dataBroker, LogicalDatastoreType.CONFIGURATION,
                                           getIpPortMapIdentifier(segmentId, internalIpPort, protocol), ipm);
                        } catch (UncheckedExecutionException uee) {
                            LOG.error("NAPT Service : Failed to write into ip-port-map with exception {}", uee.getMessage() );
                        }

                         // Write to snat-internal-ip-port-info
                         String internalIpAddress = sourceAddress.getIpAddress();
                         int ipPort = sourceAddress.getPortNumber();
                         ProtocolTypes protocolType = NatUtil.getProtocolType(protocol);
                         List<Integer> portList = NatUtil.getInternalIpPortListInfo(dataBroker,segmentId,internalIpAddress,protocolType);
                         if (portList == null) {
                             portList = Lists.newArrayList();
                         }
                         portList.add(ipPort);

                         IntIpProtoTypeBuilder builder = new IntIpProtoTypeBuilder();
                         IntIpProtoType intIpProtocolType = builder.setKey(new IntIpProtoTypeKey(protocolType)).setPorts(portList).build();
                         try {
                             MDSALUtil.syncWrite(dataBroker, LogicalDatastoreType.CONFIGURATION,
                                     NatUtil.buildSnatIntIpPortIdentifier(segmentId, internalIpAddress, protocolType), intIpProtocolType);
                         } catch (Exception ex) {
                             LOG.error("NAPT Service : Failed to write into snat-internal-ip-port-info with exception {}", ex.getMessage() );
                         }

                         LOG.debug("NAPT Service : getExternalAddressMapping successfully returning externalIP {} and port {}",
                                         externalIpPort.getIpAddress(), externalIpPort.getPortNumber());
                        return externalIpPort;
                    } catch(InterruptedException | ExecutionException  e) {
                        LOG.error("NAPT Service : getExternalAddressMapping, Exception caught  {}",e);
                        return null;
                    }
                }// end of for loop
             }// end of else ipmap present
         }// end of else check ipmap
         LOG.error("NAPT Service: getExternalAddressMapping returning null, nothing worked or externalIPs exhausted");
         return null;
     }


     /**
      * release the existing mapping of internal ip/port to external ip/port pair
      * if no mapping exist for given internal ip/port, it returns false
      * @param segmentId - Router ID
      * @param address - Session Address
      * @param protocol - TCP/UDP
      * @return true if mapping exist and the mapping is removed successfully
      */

     public boolean releaseAddressMapping(long segmentId, SessionAddress address, NAPTEntryEvent.Protocol protocol) {

         LOG.debug("NAPT Service : releaseAddressMapping called with segmentId {}, internalIP {}, port {}", segmentId, address.getIpAddress(), address.getPortNumber());
         // delete entry from IpPort Map and IP Map if exists
         String internalIpPort = new StringBuilder(64).append(address.getIpAddress()).append(":").append(address.getPortNumber()).toString();
         SessionAddress existingIpPort = checkIpPortMap(segmentId, internalIpPort, protocol);
         if(existingIpPort != null) {
             // delete the entry from IpPortMap DS
             try {
                 removeFromIpPortMapDS(segmentId, internalIpPort , protocol);
             } catch (Exception e){
                 LOG.error("NAPT Service : releaseAddressMapping failed, Removal of ipportmap {} for router {} failed {}" , internalIpPort, segmentId, e);
                 return false;
             }
         } else {
             LOG.error("NAPT Service : releaseAddressMapping failed, segmentId {} and internalIpPort {} not found in IpPortMap DS", segmentId, internalIpPort);
             return false;
         }
         String existingIp = checkIpMap(segmentId, address.getIpAddress());
         if(existingIp != null) {
             // delete the entry from IpMap DS
             try {
                 removeFromIpMapDS(segmentId, address.getIpAddress());
             } catch (Exception e){
                 LOG.error("NAPT Service : Removal of  ipmap {} for router {} failed {}" , address.getIpAddress(), segmentId, e);
                 return false;
             }
             //delete the entry from snatIntIpportinfo
             try {
                 removeFromSnatIpPortDS(segmentId, address.getIpAddress());
             } catch (Exception e){
                 LOG.error("NAPT Service : releaseAddressMapping failed, Removal of snatipportmap {} for router {} failed {}" , address.getIpAddress(), segmentId, e);
                 return false;
             }
         } else {
             LOG.error("NAPT Service : releaseAddressMapping failed, segmentId {} and internalIpPort {} not found in IpMap DS", segmentId, internalIpPort);
             return false;
         }
         // Finally release port from idmanager
         removePortFromPool(internalIpPort, existingIpPort.getIpAddress());

         LOG.debug("NAPT Service : Exit of releaseAddressMapping successfully for segmentId {} and internalIpPort {}", segmentId, internalIpPort);  
         return true;

     }

    protected void releaseIpExtPortMapping(long segmentId, SessionAddress address, NAPTEntryEvent.Protocol protocol) {
        String internalIpPort = address.getIpAddress() + ":" + address.getPortNumber();
        SessionAddress existingIpPort = checkIpPortMap(segmentId, internalIpPort, protocol);
        if(existingIpPort != null) {
            // delete the entry from IpPortMap DS
            try {
                removeFromIpPortMapDS(segmentId, internalIpPort , protocol);
                // Finally release port from idmanager
                removePortFromPool(internalIpPort, existingIpPort.getIpAddress());
            } catch (Exception e){
                LOG.error("NAPT Service : releaseAddressMapping failed, Removal of ipportmap {} for router {} failed {}" ,
                        internalIpPort, segmentId, e);
            }
        } else {
            LOG.error("NAPT Service : releaseIpExtPortMapping failed, segmentId {} and internalIpPort {} not found in IpPortMap DS", segmentId, internalIpPort);
        }

        //delete the entry of port for InternalIp from snatIntIpportMappingDS
        try {
            removeSnatIntIpPortDS(segmentId,address, protocol);
        } catch (Exception e){
            LOG.error("NAPT Service : releaseSnatIpPortMapping failed, Removal of snatipportmap {} for router {} failed {}" ,
                    address.getIpAddress(), segmentId, e);
        }
    }

     /**
      * removes the internal ip to external ip mapping if present
      * @param segmentId - Router ID
      * @return true if successfully removed
      */
     public boolean removeMapping(long segmentId) {
         try {
             removeIpMappingForRouterID(segmentId);
             removeIpPortMappingForRouterID(segmentId);
             removeIntIpPortMappingForRouterID(segmentId);
         } catch (Exception e){
             LOG.error("NAPT Service : Removal of  IPMapping for router {} failed {}" , segmentId, e);
             return false;
         }

         //TODO :  This is when router is deleted then cleanup the entries in tables, ports etc - Delete scenarios
        return false;
     }

     // 2. Utility functions
     protected InstanceIdentifier<IpMap> getIpMapIdentifier(long segid, String internal) {
         InstanceIdentifier<IpMap> id = InstanceIdentifier.builder(
                 IntextIpMap.class).child(IpMapping.class, new IpMappingKey(segid)).child(IpMap.class, new IpMapKey(internal)).build();
         return id;
     }

     protected InstanceIdentifier<ExternalIpCounter> getExternalIpsIdentifier(long segmentId, String external) {
         InstanceIdentifier<ExternalIpCounter> id = InstanceIdentifier.builder(ExternalIpsCounter.class).child(ExternalCounters.class, new ExternalCountersKey(segmentId))
                 .child(ExternalIpCounter.class, new ExternalIpCounterKey(external)).build();
         return id;
     }

    public static List<IpMap> getIpMapList(DataBroker broker, Long routerId) {
        InstanceIdentifier<IpMapping> id = getIpMapList(routerId);
        Optional<IpMapping> ipMappingListData = NatUtil.read(broker, LogicalDatastoreType.OPERATIONAL, id);
        if (ipMappingListData.isPresent()) {
            IpMapping ipMapping = ipMappingListData.get();
            return ipMapping.getIpMap();
        }
        return null;
    }

    protected static InstanceIdentifier<IpMapping> getIpMapList(long routerId) {
        InstanceIdentifier<IpMapping> id = InstanceIdentifier.builder(
                IntextIpMap.class).child(IpMapping.class, new IpMappingKey(routerId)).build();
        return id;
    }

     protected InstanceIdentifier<IpPortMap> getIpPortMapIdentifier(long segid, String internal, NAPTEntryEvent.Protocol protocol) {
         ProtocolTypes protocolType = NatUtil.getProtocolType(protocol);
         InstanceIdentifier<IpPortMap> id = InstanceIdentifier.builder(
                 IntextIpPortMap.class).child(IpPortMapping.class, new IpPortMappingKey(segid)).child(IntextIpProtocolType.class, new IntextIpProtocolTypeKey(protocolType)).
                 child(IpPortMap.class, new IpPortMapKey(internal)).build();
         return id;
     }

     protected SessionAddress checkIpPortMap(long segmentId, String internalIpPort, NAPTEntryEvent.Protocol protocol) {

         LOG.debug("NAPT Service : checkIpPortMap called with segmentId {} and internalIpPort {}", segmentId, internalIpPort);
         ProtocolTypes protocolType = NatUtil.getProtocolType(protocol);
         // check if ip-port-map node is there
         InstanceIdentifierBuilder<IntextIpProtocolType> idBuilder =
                         InstanceIdentifier.builder(IntextIpPortMap.class).child(IpPortMapping.class, new IpPortMappingKey(segmentId)).child(IntextIpProtocolType.class, new IntextIpProtocolTypeKey(protocolType));
         InstanceIdentifier<IntextIpProtocolType> id = idBuilder.build();
         Optional<IntextIpProtocolType> intextIpProtocolType = MDSALUtil.read(dataBroker, LogicalDatastoreType.CONFIGURATION, id);
         if (intextIpProtocolType.isPresent()) {
               List<IpPortMap> ipPortMaps = intextIpProtocolType.get().getIpPortMap();
               for (IpPortMap ipPortMap : ipPortMaps) {
                    if (ipPortMap.getIpPortInternal().equals(internalIpPort)) {
                       LOG.debug("NAPT Service : IpPortMap : {}", ipPortMap);
                       SessionAddress externalIpPort = new SessionAddress(ipPortMap.getIpPortExternal().getIpAddress(),
                                ipPortMap.getIpPortExternal().getPortNum());
                       LOG.debug("NAPT Service : checkIpPortMap returning successfully externalIP {} and port {}",
                               externalIpPort.getIpAddress(), externalIpPort.getPortNumber());
                       return externalIpPort;
                    }
               }
         }
         // return null if not found
         LOG.error("NAPT Service : no-entry in checkIpPortMap, returning NULL [should be OK] for segmentId {} and internalIPPort {}", segmentId, internalIpPort);
         return null;
     }

     protected String checkIpMap(long segmentId, String internalIp) {

         LOG.debug("NAPT Service : checkIpMap called with segmentId {} and internalIp {}", segmentId, internalIp);
         String externalIp;
         // check if ip-map node is there
         InstanceIdentifierBuilder<IpMapping> idBuilder =
                         InstanceIdentifier.builder(IntextIpMap.class).child(IpMapping.class, new IpMappingKey(segmentId));
         InstanceIdentifier<IpMapping> id = idBuilder.build();
         Optional<IpMapping> ipMapping = MDSALUtil.read(dataBroker, LogicalDatastoreType.OPERATIONAL, id);
         if (ipMapping.isPresent()) {
               List<IpMap> ipMaps = ipMapping.get().getIpMap();
               for (IpMap ipMap : ipMaps) {
                    if (ipMap.getInternalIp().equals(internalIp)) {
                       LOG.debug("NAPT Service : IpMap : {}", ipMap);
                       externalIp = ipMap.getExternalIp().toString();
                       LOG.debug("NAPT Service : checkIpMap successfully returning externalIp {}", externalIp );
                       return externalIp;
                    } else if (ipMap.getInternalIp().contains("/")) { // subnet case
                        SubnetUtils subnetUtils = new SubnetUtils(ipMap.getInternalIp());
                        SubnetInfo subnetInfo = subnetUtils.getInfo();
                        if (subnetInfo.isInRange(internalIp)) {
                            LOG.debug("NAPT Service : internalIp {} found to be IpMap of internalIpSubnet {}", internalIp, ipMap.getInternalIp());
                            externalIp = ipMap.getExternalIp().toString();
                            LOG.debug("NAPT Service : checkIpMap successfully returning externalIp {}", externalIp );
                            return externalIp;
                        }
                    }
               }
         }
         // return null if not found
         LOG.error("NAPT Service : checkIpMap failed, returning NULL for segmentId {} and internalIp {}", segmentId, internalIp);
         return null;
      }

    protected void removeSnatIntIpPortDS(long segmentId, SessionAddress address,NAPTEntryEvent.Protocol protocol) {
        LOG.trace("NAPT Service : removeSnatIntIpPortDS method called for IntIpport {} of router {} ",address,segmentId);
        ProtocolTypes protocolType = NatUtil.getProtocolType(protocol);
        List<Integer> portList = NatUtil.getInternalIpPortListInfo(dataBroker,segmentId,address.getIpAddress(),protocolType);
        if (portList == null || portList.isEmpty() || !portList.contains(address.getPortNumber())) {
           LOG.debug("Internal IP {} for port {} entry not found in SnatIntIpPort DS",address.getIpAddress(),address.getPortNumber());
           return;
        }
        LOG.trace("NAPT Service : PortList {} retrieved for InternalIp {} of router {}",portList,address.getIpAddress(),segmentId);
        Integer port = address.getPortNumber();
        portList.remove(port);

        IntIpProtoTypeBuilder builder = new IntIpProtoTypeBuilder();
        IntIpProtoType intIpProtocolType = builder.setKey(new IntIpProtoTypeKey(protocolType)).setPorts(portList).build();
        try {
            MDSALUtil.syncWrite(dataBroker, LogicalDatastoreType.CONFIGURATION, NatUtil.buildSnatIntIpPortIdentifier(segmentId, address.getIpAddress(), protocolType), intIpProtocolType);
        } catch (Exception ex) {
            LOG.error("NAPT Service : Failed to write into snat-internal-ip-port-info with exception {}", ex.getMessage() );
        }
        LOG.debug("NAPT Service : Removing SnatIp {} Port {} of router {} from SNATIntIpport datastore : {}"
                ,address.getIpAddress(),address.getPortNumber(),segmentId);
    }

    protected void removeFromSnatIpPortDS(long segmentId, String internalIp) {
        InstanceIdentifier<IpPort> intIp = InstanceIdentifier.builder(SnatintIpPortMap.class).child
                (IntipPortMap.class, new IntipPortMapKey(segmentId)).child(IpPort.class, new IpPortKey(internalIp)).build();
        // remove from SnatIpPortDS
        LOG.debug("NAPT Service : Removing SnatIpPort from datastore : {}", intIp);
        MDSALUtil.syncDelete(dataBroker, LogicalDatastoreType.CONFIGURATION, intIp);

    }

    protected void removeFromIpPortMapDS(long segmentId, String internalIpPort, NAPTEntryEvent.Protocol protocol) {
         ProtocolTypes protocolType = NatUtil.getProtocolType(protocol);
         removeFromIpPortMapDS(segmentId, internalIpPort, protocolType);
    }

    protected void removeFromIpPortMapDS(long segmentId, String internalIpPort, ProtocolTypes protocolType) {
        InstanceIdentifierBuilder<IpPortMap> idBuilder = InstanceIdentifier.builder(IntextIpPortMap.class)
                .child(IpPortMapping.class, new IpPortMappingKey(segmentId)).child(IntextIpProtocolType.class, new IntextIpProtocolTypeKey(protocolType))
                .child(IpPortMap.class, new IpPortMapKey(internalIpPort));
        InstanceIdentifier<IpPortMap> id = idBuilder.build();
        // remove from ipportmap DS
        LOG.debug("NAPT Service : Removing ipportmap from datastore : {}", id);
        MDSALUtil.syncDelete(dataBroker, LogicalDatastoreType.CONFIGURATION, id);
    }

     protected void removeFromIpMapDS(long segmentId, String internalIp) {
         InstanceIdentifierBuilder<IpMap> idBuilder = InstanceIdentifier.builder(IntextIpMap.class)
                 .child(IpMapping.class, new IpMappingKey(segmentId))
                 .child(IpMap.class, new IpMapKey(internalIp));
         InstanceIdentifier<IpMap> id = idBuilder.build();
         // Get externalIp and decrement the counter
         String externalIp = null;
         Optional<IpMap> ipMap = MDSALUtil.read(dataBroker, LogicalDatastoreType.OPERATIONAL, id);
         if (ipMap.isPresent()) {
             externalIp = ipMap.get().getExternalIp();
             LOG.debug("NAT Service : externalIP is {}", externalIp);
         }else{
             LOG.warn("NAT Service : ipMap not present for the internal IP {}", internalIp);
         }

         if(externalIp!=null) {
             updateCounter(segmentId, externalIp, false);
             // remove from ipmap DS
             LOG.debug("NAPT Service : Removing ipmap from datastore");
             MDSALUtil.syncDelete(dataBroker, LogicalDatastoreType.OPERATIONAL, id);
         }else{
             LOG.warn("NAT Service : externalIp not present for the internal IP {}", internalIp);
         }
     }

     protected void removeIntExtIpMapDS(long segmentId, String internalIp) {
         InstanceIdentifierBuilder<IpMap> idBuilder = InstanceIdentifier.builder(IntextIpMap.class)
                 .child(IpMapping.class, new IpMappingKey(segmentId))
                 .child(IpMap.class, new IpMapKey(internalIp));
         InstanceIdentifier<IpMap> id = idBuilder.build();

         LOG.debug("NAPT Service : Removing ipmap from datastore");
         MDSALUtil.syncDelete(dataBroker, LogicalDatastoreType.OPERATIONAL, id);
     }

     protected String getExternalIpAllocatedForSubnet(long segmentId, String internalIp) {
         InstanceIdentifierBuilder<IpMap> idBuilder = InstanceIdentifier.builder(IntextIpMap.class)
                 .child(IpMapping.class, new IpMappingKey(segmentId))
                 .child(IpMap.class, new IpMapKey(internalIp));
         InstanceIdentifier<IpMap> id = idBuilder.build();

         Optional<IpMap> ipMap = MDSALUtil.read(dataBroker, LogicalDatastoreType.OPERATIONAL, id);
         if (ipMap.isPresent()) {
             return ipMap.get().getExternalIp();
         }
         return null;
     }

     private void removeIpMappingForRouterID(long segmentId) {
        InstanceIdentifierBuilder<IpMapping> idBuilder = InstanceIdentifier.builder(IntextIpMap.class)
                .child(IpMapping.class, new IpMappingKey(segmentId));
        InstanceIdentifier<IpMapping> id = idBuilder.build();
        // Get all externalIps and decrement their counters before deleting the ipmap
        String externalIp = null;
        Optional<IpMapping> ipMapping = MDSALUtil.read(dataBroker, LogicalDatastoreType.OPERATIONAL, id);
        if (ipMapping.isPresent()) {
              List<IpMap> ipMaps = ipMapping.get().getIpMap();
              for (IpMap ipMap : ipMaps) {
                  externalIp = ipMap.getExternalIp();
                  LOG.debug("NAT Service : externalIP is {}", externalIp);
                  if(externalIp!=null) {
                      updateCounter(segmentId, externalIp, false);
                  }
              }
        }
        // remove from ipmap DS
        LOG.debug("NAPT Service : Removing Ipmap for router {} from datastore",segmentId);
        MDSALUtil.syncDelete(dataBroker, LogicalDatastoreType.OPERATIONAL, id);
    }

    void removeIpPortMappingForRouterID(long segmentId) {
        InstanceIdentifier<IpPortMapping> idBuilder = InstanceIdentifier.builder(IntextIpPortMap.class)
                .child(IpPortMapping.class, new IpPortMappingKey(segmentId)).build();
        // remove from IntExtIpPortmap DS
        LOG.debug("NAPT Service : Removing IntExtIpPort map for router {} from datastore",segmentId);
        MDSALUtil.syncDelete(dataBroker, LogicalDatastoreType.CONFIGURATION, idBuilder);
    }

    void removeIntIpPortMappingForRouterID(long segmentId) {
        InstanceIdentifier<IntipPortMap> intIp = InstanceIdentifier.builder(SnatintIpPortMap.class).child
                (IntipPortMap.class, new IntipPortMapKey(segmentId)).build();
        // remove from SnatIntIpPortmap DS
        LOG.debug("NAPT Service : Removing SnatIntIpPort from datastore : {}", intIp);
        MDSALUtil.syncDelete(dataBroker, LogicalDatastoreType.CONFIGURATION, intIp);
    }

     void removePortFromPool(String internalIpPort, String externalIp) {
         LOG.debug("NAPT Service : removePortFromPool method called");
         ReleaseIdInput idInput = new ReleaseIdInputBuilder().
                                        setPoolName(externalIp)
                                        .setIdKey(internalIpPort).build();
         try {
             Future<RpcResult<Void>> result = idManager.releaseId(idInput);
             RpcResult<Void> rpcResult = result.get();
             if(!rpcResult.isSuccessful()) {
                 LOG.error("NAPT Service : idmanager failed to remove port from pool {}", rpcResult.getErrors());
             }
             LOG.debug("NAPT Service : Removed port from pool for InternalIpPort {} with externalIp {}",internalIpPort,externalIp);
         } catch (InterruptedException | ExecutionException e) {
             LOG.error("NAPT Service : idmanager failed with Exception {} when removing entry in pool with key {}, ", e, internalIpPort);
         }
     }

    protected void initialiseExternalCounter(Routers routers, long routerId){
        LOG.debug("NAPT Service : Initialise External IPs counter");
        List<String> externalIps = routers.getExternalIps();

        //update the new counter value for this externalIp
        for(String externalIp : externalIps) {
            String[] IpSplit = externalIp.split("/");
            String extIp = IpSplit[0];
            String extPrefix = Short.toString(NatConstants.DEFAULT_PREFIX);
            if(IpSplit.length==2) {
                extPrefix = IpSplit[1];
            }
            extIp = extIp + "/" + extPrefix;
            initialiseNewExternalIpCounter(routerId, extIp);
        }
    }

    protected void initialiseNewExternalIpCounter(long routerId, String ExternalIp){
        ExternalIpCounter externalIpCounterData = new ExternalIpCounterBuilder().setKey(new ExternalIpCounterKey(ExternalIp)).
                setExternalIp(ExternalIp).setCounter((short) 0).build();
        MDSALUtil.syncWrite(dataBroker, LogicalDatastoreType.OPERATIONAL, getExternalIpsIdentifier(routerId, ExternalIp), externalIpCounterData);
    }

    protected void removeExternalCounter(long routerId){
        // Remove from external-counters model
        InstanceIdentifier<ExternalCounters> id = InstanceIdentifier.builder(ExternalIpsCounter.class).child(ExternalCounters.class, new ExternalCountersKey(routerId)).build();
        LOG.debug("NAPT Service : Removing ExternalCounterd from datastore");
        MDSALUtil.syncDelete(dataBroker, LogicalDatastoreType.OPERATIONAL, id);
    }

    protected void removeExternalIpCounter(long routerId, String externalIp){
        // Remove from external-counters model
        InstanceIdentifier<ExternalIpCounter> id = InstanceIdentifier.builder(ExternalIpsCounter.class).child(ExternalCounters.class,
                new ExternalCountersKey(routerId)).child(ExternalIpCounter.class, new ExternalIpCounterKey(externalIp)).build();
        LOG.debug("NAPT Service : Removing ExternalIpsCounter from datastore");
        MDSALUtil.syncDelete(dataBroker, LogicalDatastoreType.OPERATIONAL, id);
    }

}