/*
 * Copyright (c) 2015 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.bgpmanager.commands;

import org.opendaylight.netvirt.bgpmanager.BgpManager;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.Ipv4Address;

public class Commands {
    private static BgpManager bm;
    private static final long AS_MIN=0;
    private static final long AS_MAX=4294967295L;//2^32-1

    enum Validators {
        IPADDR, INT, ASNUM;
    }

    public Commands(BgpManager bgpm) {
        bm = bgpm;
    }

    public static BgpManager getBgpManager() {
        return bm;
    }

    public static boolean isValid(String val, Validators type, String name) {
        switch (type) {
            case INT : 
                try {
                    int i = Integer.parseInt(val);
                } catch (NumberFormatException nme) {
                    System.err.println("error: value of "+name+" is not an integer");
                    return false;
                }
                break;
            case IPADDR:
                try {
                    Ipv4Address addr = new Ipv4Address(val);
                } catch (Exception e) {
                    System.err.println("error: value of "+name+" is not an IP address");
                    return false;
                }
                break;
            case ASNUM:
                if(!validateAsNumber(val)){
                    return false;
                }
                break;
            default:
                return false;
        }
        return true;
    }

    public static boolean bgpRunning() {
        if (getBgpManager() == null) {
            System.err.println("error: cannot run command, BgpManager not started");
            return false;
        }
        return true;
    }

    private static boolean validateAsNumber(String strAsnum){

        try {
            long asNum = Long.valueOf(strAsnum);
            switch((int)asNum) {
                case 0:
                case 65535:
                case 23456:
                    System.out.println("Reserved AS Number supplied ");
                    return false;
            }
            if (asNum <= AS_MIN || asNum > AS_MAX) {
                System.out.println("Invalid AS Number , supported range [1,"+AS_MAX+"]");
                return false;
            }
        } catch (Exception e) {
            System.out.println("Invalid AS Number ");
            return false;
        }
        return true;
    }
}

