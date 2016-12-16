/*
 * Copyright (c) 2016 Dell Inc. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.ipv6service;

import org.opendaylight.netvirt.ipv6service.utils.Ipv6PeriodicTrQueue;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class Ipv6PeriodicRAThread implements Runnable {
    private static final Logger LOG = LoggerFactory.getLogger(Ipv6PeriodicRAThread.class);
    public static final Ipv6PeriodicRAThread INSTANCE = new Ipv6PeriodicRAThread();
    private static final int SLEEP_TIME = 1000; //timeunit in ms
    private static Thread periodicTransmitter;
    private static Ipv6PeriodicTrQueue ipv6Queue;
    private static boolean periodicLoop = true;

    private Ipv6PeriodicRAThread() {
        ipv6Queue = Ipv6PeriodicTrQueue.getInstance();
        periodicTransmitter = new Thread(this);
        periodicTransmitter.start();
        LOG.debug("started the ipv6 periodic RA transmission thread");
    }

    public static Ipv6PeriodicRAThread getInstance() {
        return INSTANCE;
    }

    public static void wakeupPeriodicTransmitter() {
        LOG.debug("in wakeupPeriodicTransmitter");
        periodicTransmitter.interrupt();
    }

    public static void stopIpv6PeriodicRAThread() {
        periodicLoop = false;
        wakeupPeriodicTransmitter();
    }

    @Override
    public void run() {
        while (periodicLoop == true) {
            boolean hasMoreMsg = ipv6Queue.hasMessages();

            while (hasMoreMsg) {
                Uuid portId = ipv6Queue.removeMessage();
                LOG.debug("timeout got for port {}", portId);
                IfMgr ifMgr = IfMgr.getIfMgrInstance();
                ifMgr.transmitUnsolicitedRA(portId);
                hasMoreMsg = ipv6Queue.hasMessages();
            }
            try {
                //sleep the thread for 1s to wait for periodic RA transmssion
                Thread.sleep(SLEEP_TIME);
            } catch (InterruptedException e) {
                LOG.debug("Ipv6PeriodicRAThread interrupted. Continuing periodic RA");
            }
        }
    }
}
