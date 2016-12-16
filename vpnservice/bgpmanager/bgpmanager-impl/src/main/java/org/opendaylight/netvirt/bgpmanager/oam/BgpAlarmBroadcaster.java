/*
 * Copyright (c) 2015 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.bgpmanager.oam;

import java.lang.management.ManagementFactory;
import java.util.ArrayList;
import javax.management.AttributeChangeNotification;
import javax.management.JMException;
import javax.management.MBeanServer;
import javax.management.Notification;
import javax.management.NotificationBroadcasterSupport;
import javax.management.ObjectName;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class BgpAlarmBroadcaster extends NotificationBroadcasterSupport implements BgpAlarmBroadcasterMBean {
    private static final Logger LOG = LoggerFactory.getLogger(BgpAlarmBroadcaster.class);
    private long sequenceNumber;

    public BgpAlarmBroadcaster () {
        this.sequenceNumber = 1;
    }

    public void init() {
        // Set up the Infra for Posting BGP Alarms as JMX notifications.
        try {
            MBeanServer mbs = ManagementFactory.getPlatformMBeanServer();
            ObjectName alarmObj = new ObjectName("SDNC.FM:name=BgpAlarmObj");
            mbs.registerMBean(this, alarmObj);
        } catch (JMException e) {
            LOG.error("Adding a NotificationBroadcaster failed.", e);
        }
        LOG.info("{} start", getClass().getSimpleName());
    }

    public void sendBgpAlarmInfo(String pfx, int code , int subcode) {
        Notification n;
        String alarmAddText, alarmSrc = "BGP";
        BgpAlarmErrorCodes userAlarm;
        ArrayList<String> arrayList = new ArrayList<String>();

        userAlarm = BgpAlarmErrorCodes.checkErrorSubcode(subcode);
        alarmAddText = "Peer=" + pfx;
        arrayList.clear();
        arrayList.add(userAlarm.getAlarmType());
        arrayList.add(alarmAddText);
        arrayList.add(alarmSrc);
        n = new AttributeChangeNotification(this, sequenceNumber++, System.currentTimeMillis(),
                                            "raise Alarm Object notified", "raiseAlarmObject",
                                            "ArrayList", "", arrayList);
        sendNotification(n);
        LOG.info("BGP: Alarm :"+ userAlarm.getAlarmType() + " has been posted.");
    }
}
