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

import java.util.List;

@Command(scope = "odl", name = "bgp-vrf",
         description = "Add or delete BGP VRFs")
public class Vrf extends OsgiCommandSupport {
    private static final String RD = "--rd";
    private static final String IR = "--import-rts";
    private static final String ER = "--export-rts";

    @Argument(name="add|del", description="The desired operation",
              required=true, multiValued = false)
    private String action = null;

    @Option(name=RD, aliases={"-r"},
            description="Route distinguisher", 
            required=false, multiValued=false)
    private String rd = null;

    @Option(name=IR, aliases={"-i"},
            description="Import route-targets", 
            required=false, multiValued=true)
    private List<String> irts = null;

    @Option(name=ER, aliases={"-e"},
            description="Export route-targets", 
            required=false, multiValued=true)
    private List<String> erts = null;

    private Object usage() {
        System.err.println(
            "usage: bgp-vrf ["+RD+" rd] [<"+IR+" | "+ER+"> rt1] .. [<"+ 
            IR+" | "+ER+"> rtN] <add|del>");
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
                if (rd == null || irts == null || erts == null) {
                    System.err.println("error: all options needed");
                    return null;
                }
                // check: rd exists? rd & rt's in format?
                bm.addVrf(rd, irts, erts);
                break;
            case "del" :  
                if (rd == null) {
                    System.err.println("error: "+RD+" needed");
                    return null;
                }
                if (irts != null || erts != null) {
                    System.err.println("error: some option(s) not needed; ignored");
                }
                // check: rd exists? in format?
                bm.deleteVrf(rd, true);
                break; 
            default : 
                return usage();
        }
        return null;
    }
}
