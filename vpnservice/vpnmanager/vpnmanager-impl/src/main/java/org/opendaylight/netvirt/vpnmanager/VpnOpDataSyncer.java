/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.vpnmanager;

import com.google.common.util.concurrent.ThreadFactoryBuilder;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.ThreadFactory;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.google.common.collect.ImmutableMap;

/**
 * Aims to provide a common synchronization point for all those classes that
 * want to know when certain type of Operational data is ready for a given VPN,
 * and those others that can notify that the Operational data is ready
 */
public class VpnOpDataSyncer {

    static final Logger logger = LoggerFactory.getLogger(VpnOpDataSyncer.class);

    public enum VpnOpDataType {
        vpnInstanceToId,
        vpnOpData,
    }

    // Maps a VpnName with a list of Task to be executed once the the Vpn is fully ready.
    private final ConcurrentHashMap<String, List<Runnable>> vpnInst2IdSynchronizerMap = new ConcurrentHashMap<>();
    private final ConcurrentHashMap<String, List<Runnable>> vpnInst2OpDataSynchronizerMap = new ConcurrentHashMap<>();

    // The only purpose of this map is being able to reuse code
    private final Map<VpnOpDataType, ConcurrentHashMap<String, List<Runnable>>> mapOfMaps =
        ImmutableMap.<VpnOpDataType, ConcurrentHashMap<String, List<Runnable>>>builder()
            .put(VpnOpDataType.vpnInstanceToId, vpnInst2IdSynchronizerMap)
            .put(VpnOpDataType.vpnOpData,       vpnInst2OpDataSynchronizerMap)
            .build();


    private static final ThreadFactory threadFactory = new ThreadFactoryBuilder().setNameFormat("NV-VpnMgr-%d").build();
    private final ExecutorService executorService = Executors.newSingleThreadExecutor(threadFactory);


    public boolean waitForVpnDataReady(VpnOpDataType vpnOpDataType, String vpnName, long maxWaitMillis,
                                       int maxAttempts) {
        int attempts = 0;
        boolean isDataReady = false;
        do {
            attempts++;
            isDataReady = waitForVpnDataReady(vpnOpDataType, vpnName, maxWaitMillis);
        } while ( !isDataReady && attempts < maxAttempts);

        return isDataReady;
    }

    public boolean waitForVpnDataReady(VpnOpDataType dataType, String vpnName, long maxWaitMillis) {
        //TODO(vivek) This waiting business to be removed in carbon
        boolean dataReady = false;
        ConcurrentHashMap<String, List<Runnable>> listenerMap = mapOfMaps.get(dataType);
        Runnable notifyTask = new VpnNotifyTask();
        List<Runnable> notifieeList = null;
        try {
            synchronized (listenerMap) {
                notifieeList = listenerMap.get(vpnName);
                if (notifieeList == null) {
                    notifieeList = new ArrayList<>();
                    listenerMap.put(vpnName, notifieeList);
                }
                notifieeList.add(notifyTask);
            }

            synchronized (notifyTask) {
                long t0 = System.nanoTime();
                long elapsedTimeNs = t0;
                try {

                    notifyTask.wait(maxWaitMillis);
                    elapsedTimeNs = System.nanoTime() - t0;

                    if ( elapsedTimeNs < (maxWaitMillis * 1000000) ) {
                        // Thread woken up before timeout
                        logger.debug("Its been reported that VPN {} is now ready", vpnName);
                        dataReady = true;
                    } else {
                        // Timeout
                        logger.debug("Vpn {} OpData not ready after {}ms", vpnName, maxWaitMillis);
                        dataReady = false;
                    }
                } catch ( InterruptedException e ) {
                    dataReady = true;
                }
            }
        } finally {
            synchronized (listenerMap) {
                notifieeList = listenerMap.get(vpnName);
                if (notifieeList != null) {
                    notifieeList.remove(notifyTask);
                    if (notifieeList.isEmpty()) {
                        listenerMap.remove(vpnName);
                    }
                }
            }
        }
        return dataReady;
    }

    public void notifyVpnOpDataReady(VpnOpDataType dataType, String vpnName) {
        logger.debug("Reporting that vpn {} is ready", vpnName);
        ConcurrentHashMap<String, List<Runnable>> listenerMap = mapOfMaps.get(dataType);
        synchronized (listenerMap) {
            List<Runnable> notifieeList = listenerMap.remove(vpnName);
            if (notifieeList == null) {
                logger.trace(" No notify tasks found for vpnName {}", vpnName);
                return;
            }
            Iterator<Runnable> notifieeIter = notifieeList.iterator();
            while (notifieeIter.hasNext()) {
                Runnable notifyTask = notifieeIter.next();
                executorService.execute(notifyTask);
                notifieeIter.remove();
            }
        }
    }
}
