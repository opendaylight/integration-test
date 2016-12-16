/*
 * Copyright © 2015 Red Hat, Inc. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.openstack.netvirt.sfc.it.utils;

import java.util.ArrayList;
import java.util.List;

import org.opendaylight.yang.gen.v1.urn.cisco.params.xml.ns.yang.sfc.common.rev151017.SfDataPlaneLocatorName;
import org.opendaylight.yang.gen.v1.urn.cisco.params.xml.ns.yang.sfc.common.rev151017.SfName;
import org.opendaylight.yang.gen.v1.urn.cisco.params.xml.ns.yang.sfc.common.rev151017.SffName;
import org.opendaylight.yang.gen.v1.urn.cisco.params.xml.ns.yang.sfc.common.rev151017.SftTypeName;
import org.opendaylight.yang.gen.v1.urn.cisco.params.xml.ns.yang.sfc.sf.rev140701.ServiceFunctionsBuilder;
import org.opendaylight.yang.gen.v1.urn.cisco.params.xml.ns.yang.sfc.sf.rev140701.service.function.base.SfDataPlaneLocator;
import org.opendaylight.yang.gen.v1.urn.cisco.params.xml.ns.yang.sfc.sf.rev140701.service.function.base.SfDataPlaneLocatorBuilder;
import org.opendaylight.yang.gen.v1.urn.cisco.params.xml.ns.yang.sfc.sf.rev140701.service.functions.ServiceFunction;
import org.opendaylight.yang.gen.v1.urn.cisco.params.xml.ns.yang.sfc.sf.rev140701.service.functions.ServiceFunctionBuilder;
import org.opendaylight.yang.gen.v1.urn.cisco.params.xml.ns.yang.sfc.sl.rev140701.VxlanGpe;
import org.opendaylight.yang.gen.v1.urn.ericsson.params.xml.ns.yang.sfc.sf.ovs.rev160107.SfDplOvsAugmentation;
import org.opendaylight.yang.gen.v1.urn.ericsson.params.xml.ns.yang.sfc.sf.ovs.rev160107.SfDplOvsAugmentationBuilder;
import org.opendaylight.yang.gen.v1.urn.ericsson.params.xml.ns.yang.sfc.sf.ovs.rev160107.connected.port.OvsPortBuilder;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.IpAddress;

public class ServiceFunctionUtils extends AbstractUtils {
    public SfDataPlaneLocatorBuilder sfDataPlaneLocatorBuilder(SfDataPlaneLocatorBuilder sfDataPlaneLocatorBuilder,
                                                               String ip, int port, String dplName,
                                                               String sf1DplPortName, String sffName) {
        SfDplOvsAugmentationBuilder sfDplOvsAugmentationBuilder = new SfDplOvsAugmentationBuilder();
        OvsPortBuilder ovsPortBuilder = new OvsPortBuilder().setPortId(sf1DplPortName);
        sfDplOvsAugmentationBuilder.setOvsPort(ovsPortBuilder.build());

        return sfDataPlaneLocatorBuilder
                .addAugmentation(SfDplOvsAugmentation.class, sfDplOvsAugmentationBuilder.build())
                .setLocatorType(ipBuilder(ip, port).build())
                .setName(SfDataPlaneLocatorName.getDefaultInstance(dplName))
                .setTransport(VxlanGpe.class)
                .setServiceFunctionForwarder(SffName.getDefaultInstance(sffName));
    }

    public ServiceFunctionBuilder serviceFunctionBuilder(ServiceFunctionBuilder serviceFunctionBuilder,
                                                         String ip, String sfName,
                                                         List<SfDataPlaneLocator> sfDataPlaneLocatorList,
                                                         SftTypeName type) {
        return serviceFunctionBuilder
                .setSfDataPlaneLocator(sfDataPlaneLocatorList)
                .setName(new SfName(sfName))
                .setIpMgmtAddress(new IpAddress(ip.toCharArray()))
                .setType(type)
                .setNshAware(true);
    }

    public ServiceFunctionsBuilder serviceFunctionsBuilder(ServiceFunctionsBuilder serviceFunctionsBuilder,
                                                           List<ServiceFunction> serviceFunctionList) {
        return serviceFunctionsBuilder.setServiceFunction(serviceFunctionList);
    }

    public ServiceFunctionBuilder serviceFunctionBuilder(String sfIp, int port, String sf1DplName,
                                                         String sf1DplPortName,
                                                         String sffname, String sfName) {
        SfDataPlaneLocatorBuilder sfDataPlaneLocator =
                sfDataPlaneLocatorBuilder(new SfDataPlaneLocatorBuilder(), sfIp, port, sf1DplName,
                        sf1DplPortName, sffname);
        List<SfDataPlaneLocator> sfDataPlaneLocatorList = list(new ArrayList<>(), sfDataPlaneLocator);
        return serviceFunctionBuilder(
                new ServiceFunctionBuilder(), sfIp, sfName, sfDataPlaneLocatorList, new SftTypeName("firewall"));
    }


}
