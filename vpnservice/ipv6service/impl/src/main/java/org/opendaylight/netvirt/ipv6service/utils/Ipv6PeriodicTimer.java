/*
 * Copyright (c) 2016 Dell Inc. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.ipv6service.utils;

import io.netty.util.Timeout;
import io.netty.util.TimerTask;
import org.opendaylight.netvirt.ipv6service.Ipv6PeriodicRAThread;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;

public class Ipv6PeriodicTimer implements TimerTask {
    public static final Ipv6PeriodicTrQueue IPV6_QUEUE = Ipv6PeriodicTrQueue.getInstance();
    private Uuid portId;

    public Ipv6PeriodicTimer(Uuid id) {
        portId = id;
    }

    @Override
    public void run(Timeout timeout) throws Exception {
        IPV6_QUEUE.addMessage(portId);
        Ipv6PeriodicRAThread ipv6Thread = Ipv6PeriodicRAThread.getInstance();
        ipv6Thread.wakeupPeriodicTransmitter();
    }
}
