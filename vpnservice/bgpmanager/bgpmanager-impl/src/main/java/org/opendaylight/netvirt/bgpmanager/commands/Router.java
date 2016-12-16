/*
 * Copyright (c) 2015 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.bgpmanager.commands;

import org.apache.karaf.shell.commands.Argument;
import org.apache.karaf.shell.commands.Command;
import org.apache.karaf.shell.commands.Option;
import org.apache.karaf.shell.console.OsgiCommandSupport;
import org.opendaylight.netvirt.bgpmanager.BgpManager;

@Command(scope = "odl", name = "bgp-rtr",
         description = "Add or delete BGP router instance")
public class Router extends OsgiCommandSupport {
    private static final String AS = "--as-number";
    private static final String RID = "--router-id";
    private static final String SP = "--stale-path-time";
    private static final String FB = "--f-bit";

    @Argument(name="add|del", description="The desired operation",
              required=true, multiValued = false)
    private String action = null;

    @Option(name=AS, aliases={"-a"},
            description="AS number", 
            required=false, multiValued=false)
    private String asNum = null;

    @Option(name=RID, aliases={"-r"},
            description="Router ID", 
            required=false, multiValued=false)
    private String rid = null;

    @Option(name=SP, aliases={"-s"},
            description="Stale-path time", 
            required=false, multiValued=false)
    private String spt = null;

    @Option(name=FB, aliases={"-f"},
            description="F-bit", 
            required=false, multiValued=false)
    private String fbit = null;

    private Object usage() {
        System.err.println(
            "usage: bgp-rtr ["+AS+" as-number] ["+RID+" router-id] ["
            +SP+" stale-path-time] ["+FB+" on|off] <add | del>");
        return null;
    }       

    @Override
    protected Object doExecute() throws Exception {
        if (!Commands.bgpRunning()) {
            return null;
        }
        BgpManager bm = Commands.getBgpManager();
        switch (action) {
            case "add" : 
                // check: rtr already running?
                long asn = 0;
                int s = 0;
                boolean fb = false; 
                if (asNum == null) {
                    System.err.println("error: "+AS+" is needed");
                    return null;
                }
                if (!Commands.isValid(asNum, Commands.Validators.INT, AS)) {
                    return null;
                }
                asn = Long.valueOf(asNum);
                if (rid != null && 
                !Commands.isValid(rid, Commands.Validators.IPADDR, RID)) {
                    return null;
                }
                if (spt != null) {
                    if (!Commands.isValid(spt, Commands.Validators.INT, SP)) {
                        return null;
                    } else {
                        s = Integer.valueOf(spt);
                    }
                }
                if (fbit != null) {
                    switch (fbit) {
                        case "on": 
                            fb = true;
                            break;
                        case "off": 
                            fb = false;
                            break;
                        default: 
                            System.err.println("error: "+FB+" must be on or off");
                            return null;
                    }
                } 
                bm.startBgp(asn, rid, s, fb);
                break;
            case "del" : 
                // check: nothing to stop?
                if (asNum != null || rid != null || spt != null ||
                fbit != null) {
                    System.err.println("note: option(s) not needed; ignored");
                }
                bm.stopBgp();
                break;
            default :  
                return usage();
        }
        return null;
    }
}
