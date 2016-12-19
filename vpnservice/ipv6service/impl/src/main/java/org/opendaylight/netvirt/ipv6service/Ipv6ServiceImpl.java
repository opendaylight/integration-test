/*
 * Copyright (c) 2016 Red Hat, Inc. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.ipv6service;

import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.genius.mdsalutil.interfaces.IMdsalApiManager;
import org.opendaylight.netvirt.elanmanager.api.IElanService;
import org.opendaylight.netvirt.ipv6service.utils.Ipv6PeriodicTrQueue;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.rpcs.rev160406.OdlInterfaceRpcService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.packet.service.rev130709.PacketProcessingService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class Ipv6ServiceImpl {
    private static final Logger LOG = LoggerFactory.getLogger(Ipv6ServiceImpl.class);
    private final PacketProcessingService pktProcessingService;
    private final OdlInterfaceRpcService interfaceManagerRpc;
    private final IfMgr ifMgr;
    private final IElanService elanProvider;
    private final DataBroker dataBroker;
    private final IMdsalApiManager mdsalUtil;

    public Ipv6ServiceImpl(final PacketProcessingService pktProcessingService,
                           final OdlInterfaceRpcService interfaceManagerRpc,
                           final IElanService elanProvider,
                           final DataBroker dataBroker,
                           final IMdsalApiManager mdsalUtil) {
        this.pktProcessingService = pktProcessingService;
        this.interfaceManagerRpc = interfaceManagerRpc;
        this.elanProvider = elanProvider;
        this.dataBroker = dataBroker;
        this.mdsalUtil = mdsalUtil;
        ifMgr = IfMgr.getIfMgrInstance();
    }

    public void start() {
        LOG.info("{} start", getClass().getSimpleName());
        ifMgr.setInterfaceManagerRpc(interfaceManagerRpc);
        ifMgr.setElanProvider(elanProvider);
        ifMgr.setDataBroker(dataBroker);
        ifMgr.setMdsalUtilManager(mdsalUtil);
        final Ipv6PeriodicRAThread ipv6Thread = Ipv6PeriodicRAThread.getInstance();
        Ipv6RouterAdvt.setPacketProcessingService(pktProcessingService);
    }

    public void close() {
        Ipv6PeriodicTrQueue queue = Ipv6PeriodicTrQueue.getInstance();
        queue.clearTimerQueue();
        Ipv6PeriodicRAThread ipv6Thread = Ipv6PeriodicRAThread.getInstance();
        Ipv6PeriodicRAThread.stopIpv6PeriodicRAThread();
        LOG.info("{} close", getClass().getSimpleName());
    }
}
