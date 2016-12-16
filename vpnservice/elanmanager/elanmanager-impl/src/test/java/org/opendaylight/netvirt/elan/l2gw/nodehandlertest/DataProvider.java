/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.elan.l2gw.nodehandlertest;

import java.util.ArrayList;
import java.util.List;

/**
 * Created by eaksahu on 8/12/2016.
 */
public class DataProvider {

    static String logicalSwitchDataD1 = "ls0,100,ls1,200";
    static String logicalSwitchDataD2 = "ls3,300,ls4,400";
    static String logicalSwitchDataHaConfig = "ls5,500,ls2,600";

    static String localUcasMacDataD1 = "10:00:00:00:00:01,10.10.10.1,192.168.122.10,ls0,"
            + "10:00:00:00:00:02,10.10.10.2,192.168.122.10,ls0,"
            + "10:00:00:00:00:03,10.10.10.3,192.168.122.10,ls1,"
            + "10:00:00:00:00:04,10.10.10.4,192.168.122.10,ls1";
    static String localUcasMacDataD2 = "10:00:00:00:00:05,10.10.10.5,192.168.122.40,ls3,"
            + "10:00:00:00:00:06,10.10.10.6,192.168.122.40,ls3,"
            + "10:00:00:00:00:07,10.10.10.7,192.168.122.40,ls4,"
            + "10:00:00:00:00:08,10.10.10.8,192.168.122.40,ls4,";

    public static String getLogicalSwitchDataHaConfig() {
        return logicalSwitchDataHaConfig;
    }

    static String localMcastDataD1 = "FF:FF:FF:FF:FF:FF,ls0,192.168.122.10";
    static String localMcastDataD2 = "AF:FF:FF:FF:FF:FF,ls3,192.168.122.10";

    static String remoteMcastDataD1 = "FF:FF:FF:FF:FF:FF,ls0,192.168.122.20,192.168.122.30,"
            + "33:33:33:33:33:33,ls0,192.168.122.10,192.168.122.30,"
            + "44:44:44:44:44:44,ls1,192.168.122.40,192.168.122.30";

    static String remoteMcastDataD2 = "AF:FF:FF:FF:FF:FF,ls3,192.168.122.20,192.168.122.30,"
            + "33:33:33:33:33:13,ls3,192.168.122.10,192.168.122.30,"
            + "44:44:44:44:44:14,ls3,192.168.122.40,192.168.122.30";

    static String remoteUcasteMacDataD1 = "20:00:00:00:00:01,11.10.10.1,192.168.122.20,ls0,"
            + "20:00:00:00:00:02,11.10.10.2,192.168.122.20,ls0,"
            + "20:00:00:00:00:03,11.10.10.3,192.168.122.30,ls1,"
            + "20:00:00:00:00:04,11.10.10.4,192.168.122.30,ls1";
    static String remoteUcasteMacDataD2 = "20:00:00:00:00:05,11.10.10.5,192.168.122.50,ls3,"
            + "20:00:00:00:00:06,11.10.10.6,192.168.122.50,ls3,"
            + "20:00:00:00:00:07,11.10.10.7,192.168.122.60,ls4,"
            + "20:00:00:00:00:08,11.10.10.8,192.168.122.60,ls4";

    static String globalTerminationPointIpD1 = "192.168.122.10,"
            + "192.168.122.20,"
            + "192.168.122.30,"
            + "192.168.122.40";
    static String globalTerminationPointIpD2 = "192.168.122.10,"
            + "192.168.122.20,"
            + "192.168.122.30,"
            + "192.168.122.40";

    public static List<String> getPortNameListD1() {
        List<String> portNames = new ArrayList<>();
        portNames.add("s3-eth1");
        portNames.add("s3-eth2");
        portNames.add("s3-eth3");
        portNames.add("s3-eth4");
        portNames.add("s3-eth5");
        portNames.add("s3-eth6");
        portNames.add("s3-eth7");
        return portNames;
    }

    public static List<String> getPortNameListD2() {
        List<String> portNames = new ArrayList<>();
        portNames.add("s3-eth1");
        portNames.add("s3-eth2");
        portNames.add("s3-eth3");
        portNames.add("s3-eth4");
        portNames.add("s3-eth5");
        portNames.add("s3-eth6");
        portNames.add("s3-eth7");
        return portNames;
    }

    public static String getLogicalSwitchDataD1() {
        return logicalSwitchDataD1;
    }

    public static String getLogicalSwitchDataD2() {
        return logicalSwitchDataD2;
    }

    public static String getLocalUcasMacDataD1() {
        return localUcasMacDataD1;
    }

    public static String getLocalUcasMacDataD2() {
        return localUcasMacDataD2;
    }

    public static String getLocalMcastDataD1() {
        return localMcastDataD1;
    }

    public static String getLocalMcastDataD2() {
        return localMcastDataD2;
    }

    public static String getRemoteMcastDataD1() {
        return remoteMcastDataD1;
    }

    public static String getRemoteMcastDataD2() {
        return remoteMcastDataD2;
    }

    public static String getRemoteUcasteMacDataD1() {
        return remoteUcasteMacDataD1;
    }

    public static String getRemoteUcasteMacDataD2() {
        return remoteUcasteMacDataD2;
    }

    public static String getGlobalTerminationPointIpD1() {
        return globalTerminationPointIpD1;
    }

    public static String getGlobalTerminationPointIpD2() {
        return globalTerminationPointIpD2;
    }

}
