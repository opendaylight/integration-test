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

@Command(scope = "odl", name = "bgp-connect",
         description = "Add or delete client connection to BGP Config Server")
public class Connect extends OsgiCommandSupport {
    private static final String HOST = "--host";
    private static final String PORT = "--port";

    @Argument(name="add|del", description="The desired operation",
              required=true, multiValued = false)
    String action = null;

    @Option(name=HOST, aliases={"-h"},
            description="IP address of the server", 
            required=false, multiValued=false)
    String host = null;

    @Option(name=PORT, aliases={"-p"},
            description="Thrift port", required=false, 
            multiValued=false)
    String port = null;

    private Object usage() {
        System.err.println(
            "usage: bgp-connect ["+HOST+" h] ["+PORT+" p] <add | del>");
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
                if (host == null || port == null) {
                    System.err.println("error: "+HOST+" and "+PORT+" needed");
                    return null;
                }
                if (!Commands.isValid(host, Commands.Validators.IPADDR, HOST)
                    || !Commands.isValid(port, Commands.Validators.INT, PORT)) {
                    return null;
                }
                // check: already connected?
                bm.startConfig(host, Integer.valueOf(port));
                break;
            case "del" : 
                if (host != null || port != null) {
                    System.err.println("note: option(s) not needed; ignored");
                }
                // check: nothing to stop?
                bm.stopConfig();
                break;
            default : 
                return usage();
        }
        return null;
    }
}
