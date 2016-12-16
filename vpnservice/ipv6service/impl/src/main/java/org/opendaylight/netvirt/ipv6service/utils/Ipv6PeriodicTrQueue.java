/*
 * Copyright (c) 2016 Dell Inc. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.ipv6service.utils;

import java.util.concurrent.ConcurrentLinkedQueue;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;

public class Ipv6PeriodicTrQueue {
    private static final Ipv6PeriodicTrQueue INSTANCE = new Ipv6PeriodicTrQueue();
    private ConcurrentLinkedQueue ipv6PeriodicQueue;

    private Ipv6PeriodicTrQueue() {
        ipv6PeriodicQueue = new ConcurrentLinkedQueue();
    }

    public static Ipv6PeriodicTrQueue getInstance() {
        return INSTANCE;
    }

    public boolean addMessage(Uuid portId) {
        return (ipv6PeriodicQueue.add(portId));
    }

    public Uuid removeMessage() {
        return (Uuid)ipv6PeriodicQueue.poll();
    }

    public void clearTimerQueue() {
        ipv6PeriodicQueue.clear();
        return;
    }

    public boolean hasMessages() {
        return (!ipv6PeriodicQueue.isEmpty());
    }
}
