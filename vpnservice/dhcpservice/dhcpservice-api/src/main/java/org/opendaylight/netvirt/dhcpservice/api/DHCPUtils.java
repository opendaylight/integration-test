/*
 * Copyright (c) 2015 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.dhcpservice.api;


import java.math.BigInteger;
import java.net.InetAddress;
import java.net.UnknownHostException;
import java.util.List;

public abstract class DHCPUtils {

    public static byte[] byteToByteArray(byte value) {
        return new byte[] {value};
    }

    public static byte[] shortToByteArray(short value) {
        return new byte[] { (byte) ((value >> 8) & 0xff), (byte) (value & 0xff) };
    }

    public static byte[] intToByteArray(int value) {
        return new byte[] {(byte) ((value >> 24) & 0xff), (byte) ((value >> 16) & 0xff),
            (byte) ((value >> 8) & 0xff), (byte) (value & 0xff) };
    }

    public static byte[] inetAddrToByteArray(InetAddress address) {
        return address.getAddress();
    }

    public static byte[] strAddrToByteArray(String addr) {
        try {
            return InetAddress.getByName(addr).getAddress();
        } catch (UnknownHostException e) {
            return null;
        }
    }

    public static byte[] strListAddrsToByteArray(List<String> strList) {
        byte[] result = new byte[strList.size() * 4];
        byte[] addr = new byte[4];
        try {
            for (int i = 0; i < strList.size(); i++) {
                addr = InetAddress.getByName(strList.get(i)).getAddress();
                System.arraycopy(addr, 0, result, i * 4, 4);
            }
        } catch (UnknownHostException e) {
            return null;
        }
        return result;
    }

    public static short byteArrayToShort(byte[] ba) {
        if (ba == null || ba.length != 2) {
            return 0;
        }
        return (short) ((0xff & ba[0]) << 8 | (0xff & ba[1]));
    }

    public static InetAddress byteArrayToInetAddr(byte[] ba) {
        try {
            return InetAddress.getByAddress(ba);
        } catch (UnknownHostException e) {
            return null;
        }
    }

    public static byte[] strMacAddrtoByteArray(String macAddress) {
        if (macAddress == null) {
            return null;
        }
        String[] bytes = macAddress.split(":");
        byte[] result = new byte[bytes.length];
        for (int i = 0; i < bytes.length; i++) {
            BigInteger temp = new BigInteger(bytes[i], 16);
            byte[] raw = temp.toByteArray();
            result[i] = raw[raw.length - 1];
        }
        return result;
    }

    public static String byteArrayToString(byte[] bytes) {
        StringBuilder str = new StringBuilder();
        for (byte b : bytes) {
            str.append(Integer.toHexString((b >>> 4) & 0x0F));
            str.append(Integer.toHexString(b & 0x0F));
            str.append(":");
        }
        str.deleteCharAt(str.lastIndexOf(":"));
        return str.toString();
    }
}
