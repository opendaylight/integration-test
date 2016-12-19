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
import org.opendaylight.netvirt.bgpmanager.thrift.gen.af_afi;
import org.opendaylight.netvirt.bgpmanager.thrift.gen.af_safi;

@Command(scope = "odl", name = "bgp-nbr",
         description = "Add or delete BGP neighbor")
public class Neighbor extends OsgiCommandSupport {
    private static final String IP = "--ip-address";
    private static final String AS = "--as-number";
    private static final String MH = "--ebgp-multihop";
    private static final String US = "--update-source";
    private static final String AF = "--address-family";
   
    @Argument(index=0, name="add|del", description="The desired operation",
              required=true, multiValued = false)
    String action = null;

    @Option(name=IP, aliases = {"-i"},
            description="Neighbor's IP address", 
            required=false, multiValued=false)
    String nbrIp = null; 

    @Option(name=AS, aliases = {"-a"},  
            description="AS number", 
            required=false, multiValued=false)
    String asNum = null;

    @Option(name=MH, aliases = {"-e"},  
            description="EBGP-multihop hops", 
            required=false, multiValued=false)
    String nHops = null;

    @Option(name=US, aliases = {"-u"},  
            description="Update source address", 
            required=false, multiValued=false)
    String srcIp = null;

    @Option(name=AF, aliases = {"-f"},  
            description="Address family", 
            required=false, multiValued=false)
    String addrFamily = null;

    private Object usage() {
        System.err.println(
            "usage: bgp-nbr ["+IP+" nbr-ip-address] ["+AS+" asnum] ["
            +MH+" hops] ["+US+" source] ["+AF+" lu] <add|del>");
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
                if (nbrIp == null) {
                    System.err.println("error: "+IP+" needed");
                    return null;
                }
                if (bm.getConfig() == null) {
                    System.err.println("error: Bgp config is not present");
                    return null;
                }
                long asn = 0;
                int hops = 0;
                if (!Commands.isValid(nbrIp, Commands.Validators.IPADDR, IP)) {
                    return null;
                }
                if (asNum != null) {
                    if (!Commands.isValid(asNum, Commands.Validators.INT, AS)) {
                        return null;
                    } else {
                        asn = Long.valueOf(asNum);
                    }
                }
                bm.addNeighbor(nbrIp, asn);
                if (nHops != null) {
                    if (!Commands.isValid(nHops, Commands.Validators.INT, MH)) {
                        return null;
                    } else {
                        hops = Integer.valueOf(nHops);
                    }
                    bm.addEbgpMultihop(nbrIp, hops);
                }
                if (srcIp != null) { 
                    if (!Commands.isValid(srcIp, Commands.Validators.IPADDR, US)) {
                        return null;
                    }
                    bm.addUpdateSource(nbrIp, srcIp);
                }
                if (addrFamily != null) {
                    if (!addrFamily.equals("lu"))  {
                        System.err.println("error: "+AF+" must be lu");
                        return null;
                    }
                    af_afi afi = af_afi.findByValue(1);
                    af_safi safi = af_safi.findByValue(4);
                    bm.addAddressFamily(nbrIp, afi, safi); 
                }
                break;
            case "del" :  
                if (nbrIp == null) {
                    System.err.println("error: "+IP+" needed");
                    return null;
                }
                if (!Commands.isValid(nbrIp, Commands.Validators.IPADDR, IP)) {
                    return null;
                }
                if (asNum != null || nHops != null || srcIp != null
                || addrFamily != null) {
                    System.err.println("note: some option(s) not needed; ignored");
                }
                bm.deleteNeighbor(nbrIp);
                break;
            default :  
                return usage();
        }
        return null;
    }
}
