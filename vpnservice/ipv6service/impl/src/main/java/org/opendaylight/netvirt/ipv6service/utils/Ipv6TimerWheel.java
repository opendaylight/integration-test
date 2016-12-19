/*
 * Copyright (c) 2016 Dell Inc. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.ipv6service.utils;

import io.netty.util.HashedWheelTimer;
import io.netty.util.Timeout;
import io.netty.util.Timer;
import io.netty.util.TimerTask;
import java.util.concurrent.TimeUnit;

public class Ipv6TimerWheel {
    private Timer ipv6PeriodicRATimerWheel;
    public static final Ipv6TimerWheel INSTANCE = new Ipv6TimerWheel();

    private Ipv6TimerWheel() {
        ipv6PeriodicRATimerWheel = new HashedWheelTimer();
    }

    public static Ipv6TimerWheel getInstance() {
        return INSTANCE;
    }

    public Timeout setPeriodicTransmissionTimeout(TimerTask task, long delay, TimeUnit unit) {
        Timeout timeout = null;
        synchronized (ipv6PeriodicRATimerWheel) {
            timeout  = ipv6PeriodicRATimerWheel.newTimeout(task, delay, unit);
        }
        return timeout;
    }

    public void cancelPeriodicTransmissionTimeout(Timeout timeout) {
        if (timeout != null) {
            synchronized (timeout) {
                if (!timeout.isExpired()) {
                    timeout.cancel();
                }
            }
        }
    }
}
