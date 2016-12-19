/*
 * Copyright (c) 2016 Brocade Communications Systems, Inc. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.openstack.sfc.translator;

import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.netvirt.utils.mdsal.utils.MdsalUtils;
import org.opendaylight.yang.gen.v1.urn.cisco.params.xml.ns.yang.sfc.sf.rev140701.ServiceFunctions;
import org.opendaylight.yang.gen.v1.urn.cisco.params.xml.ns.yang.sfc.sf.rev140701.service.functions.ServiceFunction;
import org.opendaylight.yang.gen.v1.urn.cisco.params.xml.ns.yang.sfc.sf.rev140701.service.functions.ServiceFunctionKey;
import org.opendaylight.yang.gen.v1.urn.cisco.params.xml.ns.yang.sfc.sfc.rev140701.ServiceFunctionChains;
import org.opendaylight.yang.gen.v1.urn.cisco.params.xml.ns.yang.sfc.sfc.rev140701.service.function.chain.grouping.ServiceFunctionChain;
import org.opendaylight.yang.gen.v1.urn.cisco.params.xml.ns.yang.sfc.sfc.rev140701.service.function.chain.grouping.ServiceFunctionChainKey;
import org.opendaylight.yang.gen.v1.urn.cisco.params.xml.ns.yang.sfc.sff.rev140701.ServiceFunctionForwarders;
import org.opendaylight.yang.gen.v1.urn.cisco.params.xml.ns.yang.sfc.sff.rev140701.service.function.forwarders.ServiceFunctionForwarder;
import org.opendaylight.yang.gen.v1.urn.cisco.params.xml.ns.yang.sfc.sff.rev140701.service.function.forwarders.ServiceFunctionForwarderKey;
import org.opendaylight.yang.gen.v1.urn.cisco.params.xml.ns.yang.sfc.sfp.rev140701.ServiceFunctionPaths;
import org.opendaylight.yang.gen.v1.urn.cisco.params.xml.ns.yang.sfc.sfp.rev140701.service.function.paths.ServiceFunctionPath;
import org.opendaylight.yang.gen.v1.urn.cisco.params.xml.ns.yang.sfc.sfp.rev140701.service.function.paths.ServiceFunctionPathKey;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.access.control.list.rev160218.AccessLists;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.access.control.list.rev160218.access.lists.Acl;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.access.control.list.rev160218.access.lists.AclKey;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.Ipv4Address;
import org.opendaylight.yangtools.yang.binding.DataObject;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;

/**
 * Utility methods to read OpenDaylight SFC models.
 */
public class SfcMdsalHelper {
    private static final Logger LOG = LoggerFactory.getLogger(SfcMdsalHelper.class);
    private static InstanceIdentifier<AccessLists> accessListIid = InstanceIdentifier.create(AccessLists.class);
    private static InstanceIdentifier<ServiceFunctions> sfIid = InstanceIdentifier.create(ServiceFunctions.class);
    private static InstanceIdentifier<ServiceFunctionForwarders> sffIid =
            InstanceIdentifier.create(ServiceFunctionForwarders.class);
    private static InstanceIdentifier<ServiceFunctionChains> sfcIid =
            InstanceIdentifier.create(ServiceFunctionChains.class);
    private static InstanceIdentifier<ServiceFunctionPaths> sfpIid
            = InstanceIdentifier.create(ServiceFunctionPaths.class);

    private final DataBroker dataBroker;
    private final MdsalUtils mdsalUtils;

    public SfcMdsalHelper(DataBroker dataBroker) {
        this.dataBroker = dataBroker;
        mdsalUtils = new MdsalUtils(this.dataBroker);
    }

    //ACL Flow Classifier data store utility methods
    public void addAclFlowClassifier(Acl aclFlowClassifier) {
        InstanceIdentifier<Acl> aclIid = getAclPath(aclFlowClassifier.getKey());
        LOG.info("Write ACL FlowClassifier {} to config data store at {}",aclFlowClassifier, aclIid);
        mdsalPutWrapper(LogicalDatastoreType.CONFIGURATION, aclIid, aclFlowClassifier);
    }

    public void updateAclFlowClassifier(Acl aclFlowClassifier) {
        InstanceIdentifier<Acl> aclIid = getAclPath(aclFlowClassifier.getKey());
        LOG.info("Update ACL FlowClassifier {} in config data store at {}",aclFlowClassifier, aclIid);
        mdsalUtils.merge(LogicalDatastoreType.CONFIGURATION, aclIid, aclFlowClassifier);
    }

    public void removeAclFlowClassifier(Acl aclFlowClassifier) {
        InstanceIdentifier<Acl> aclIid = getAclPath(aclFlowClassifier.getKey());
        LOG.info("Remove ACL FlowClassifier {} from config data store at {}",aclFlowClassifier, aclIid);
        mdsalUtils.delete(LogicalDatastoreType.CONFIGURATION, aclIid);
    }

    //Service Function
    public ServiceFunction readServiceFunction(ServiceFunctionKey sfKey) {
        InstanceIdentifier<ServiceFunction> sfIid = getSFPath(sfKey);
        LOG.info("Read Service Function {} from config data store at {}",sfKey, sfIid);
        return mdsalUtils.read(LogicalDatastoreType.CONFIGURATION, sfIid);
    }

    public void addServiceFunction(ServiceFunction sf) {
        InstanceIdentifier<ServiceFunction> sfIid = getSFPath(sf.getKey());
        LOG.info("Write Service Function {} to config data store at {}",sf, sfIid);
        mdsalPutWrapper(LogicalDatastoreType.CONFIGURATION, sfIid, sf);
    }

    public void updateServiceFunction(ServiceFunction sf) {
        InstanceIdentifier<ServiceFunction> sfIid = getSFPath(sf.getKey());
        LOG.info("Update Service Function {} in config data store at {}",sf, sfIid);
        mdsalUtils.merge(LogicalDatastoreType.CONFIGURATION, sfIid, sf);
    }

    public void removeServiceFunction(ServiceFunctionKey sfKey) {
        InstanceIdentifier<ServiceFunction> sfIid = getSFPath(sfKey);
        LOG.info("Remove Service Function {} from config data store at {}",sfKey, sfIid);
        mdsalUtils.delete(LogicalDatastoreType.CONFIGURATION, sfIid);
    }

    //Service Function Forwarder
    public ServiceFunctionForwarder readServiceFunctionForwarder(ServiceFunctionForwarderKey sffKey) {
        InstanceIdentifier<ServiceFunctionForwarder> sffIid = getSFFPath(sffKey);
        LOG.info("Read Service Function Forwarder from config data store at {}", sffIid);
        return mdsalUtils.read(LogicalDatastoreType.CONFIGURATION, sffIid);
    }

    public void addServiceFunctionForwarder(ServiceFunctionForwarder sff) {
        InstanceIdentifier<ServiceFunctionForwarder> sffIid = getSFFPath(sff.getKey());
        LOG.info("Write Service Function Forwarder {} to config data store at {}",sff, sffIid);
        mdsalPutWrapper(LogicalDatastoreType.CONFIGURATION, sffIid, sff);
    }

    public void deleteServiceFunctionForwarder(ServiceFunctionForwarderKey sffKey) {
        InstanceIdentifier<ServiceFunctionForwarder> sffIid = getSFFPath(sffKey);
        LOG.info("Delete Service Function Forwarder from config data store at {}", sffIid);
        mdsalUtils.delete(LogicalDatastoreType.CONFIGURATION, sffIid);
    }

    public void addServiceFunctionChain(ServiceFunctionChain sfc) {
        InstanceIdentifier<ServiceFunctionChain> sfcIid = getSFCPath(sfc.getKey());
        LOG.info("Write Service Function Chain {} to config data store at {}",sfc, sfcIid);
        mdsalPutWrapper(LogicalDatastoreType.CONFIGURATION, sfcIid, sfc);
    }

    public void deleteServiceFunctionChain(ServiceFunctionChainKey sfcKey) {
        InstanceIdentifier<ServiceFunctionChain> sfcIid = getSFCPath(sfcKey);
        LOG.info("Remove Service Function Chain {} from config data store at {}",sfcKey, sfcIid);
        mdsalUtils.delete(LogicalDatastoreType.CONFIGURATION, sfcIid);
    }

    public void addServiceFunctionPath(ServiceFunctionPath sfp) {
        InstanceIdentifier<ServiceFunctionPath> sfpIid = getSFPPath(sfp.getKey());
        LOG.info("Write Service Function Path {} to config data store at {}",sfp, sfpIid);
        mdsalPutWrapper(LogicalDatastoreType.CONFIGURATION, sfpIid, sfp);
    }

    public void deleteServiceFunctionPath(ServiceFunctionPathKey sfpKey) {
        InstanceIdentifier<ServiceFunctionPath> sfpIid = getSFPPath(sfpKey);
        LOG.info("Delete Service Function Path from config data store at {}", sfpIid);
        mdsalUtils.delete(LogicalDatastoreType.CONFIGURATION, sfpIid);
    }

    private InstanceIdentifier<Acl> getAclPath(AclKey aclKey) {
        return accessListIid.builder().child(Acl.class, aclKey).build();
    }

    private InstanceIdentifier<ServiceFunction> getSFPath(ServiceFunctionKey key) {
        return sfIid.builder().child(ServiceFunction.class, key).build();
    }

    private InstanceIdentifier<ServiceFunctionForwarder> getSFFPath(ServiceFunctionForwarderKey key) {
        return sffIid.builder().child(ServiceFunctionForwarder.class, key).build();
    }

    private InstanceIdentifier<ServiceFunctionChain> getSFCPath(ServiceFunctionChainKey key) {
        return sfcIid.builder().child(ServiceFunctionChain.class, key).build();
    }

    private InstanceIdentifier<ServiceFunctionPath> getSFPPath(ServiceFunctionPathKey key) {
        return sfpIid.builder().child(ServiceFunctionPath.class, key).build();
    }

    public ServiceFunctionForwarder getExistingSFF(String ipAddress) {
        ServiceFunctionForwarders existingSffs = mdsalUtils.read(LogicalDatastoreType.CONFIGURATION, sffIid);
        if (existingSffs != null
                && existingSffs.getServiceFunctionForwarder() != null
                && !existingSffs.getServiceFunctionForwarder().isEmpty()) {

            List<ServiceFunctionForwarder> existingSffList = existingSffs.getServiceFunctionForwarder();
            for (ServiceFunctionForwarder sff : existingSffList) {
                if (sff.getIpMgmtAddress().getIpv4Address().equals(new Ipv4Address(ipAddress))) {
                    return sff;
                }
            }
        }
        return null;
    }

    private <D extends DataObject> void mdsalPutWrapper(LogicalDatastoreType dataStore, InstanceIdentifier<D> iid, D data) {
        try {
            mdsalUtils.put(dataStore, iid, data);
        } catch (Exception e) {
            LOG.error("Exception while putting data in data store {} : {}",iid, data, e);
        }
    }
}
