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
import org.opendaylight.yang.gen.v1.urn.ericsson.params.xml.ns.yang.ebgp.rev150901.Bgp;
import org.opendaylight.yang.gen.v1.urn.ericsson.params.xml.ns.yang.ebgp.rev150901.bgp.AsId;
import org.opendaylight.yang.gen.v1.urn.ericsson.params.xml.ns.yang.ebgp.rev150901.bgp.GracefulRestart;
import org.opendaylight.yang.gen.v1.urn.ericsson.params.xml.ns.yang.ebgp.rev150901.bgp.Logging;
import org.opendaylight.yang.gen.v1.urn.ericsson.params.xml.ns.yang.ebgp.rev150901.bgp.Neighbors;
import org.opendaylight.yang.gen.v1.urn.ericsson.params.xml.ns.yang.ebgp.rev150901.bgp.Networks;
import org.opendaylight.yang.gen.v1.urn.ericsson.params.xml.ns.yang.ebgp.rev150901.bgp.Vrfs;
import org.opendaylight.yang.gen.v1.urn.ericsson.params.xml.ns.yang.ebgp.rev150901.bgp.neighbors.AddressFamilies;
import org.opendaylight.yang.gen.v1.urn.ericsson.params.xml.ns.yang.ebgp.rev150901.bgp.neighbors.EbgpMultihop;
import org.opendaylight.yang.gen.v1.urn.ericsson.params.xml.ns.yang.ebgp.rev150901.bgp.neighbors.UpdateSource;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.Ipv4Address;

import java.io.PrintStream;
import java.util.List;

@Command(scope = "odl", name = "bgp-cache",
         description = "Text dump of BGP config cache")
public class Cache extends OsgiCommandSupport {
    private static final String LST = "--list";
    private static final String OFL = "--out-file";

    @Argument(name="dummy", description="Argument not needed",
              required=false, multiValued = false)
    private String action = null;

    @Option(name=LST, aliases={"-l"},
            description="list vrfs and/or networks",
            required=false, multiValued=true)
    private List<String> list = null;

    @Option(name=OFL, aliases={"-o"},
            description="output file",
            required=false, multiValued=false)
    private String ofile = null;

    private static final String HTSTR = "Host";
    private static final String PTSTR = "Port";
    private static final String ASSTR = "AS-Number";
    private static final String RISTR = "Router-ID";
    private static final String SPSTR = "Stale-Path-Time";
    private static final String FBSTR = "F-bit";
    private static final String LFSTR = "Log-File";
    private static final String LLSTR = "Log-Level";
    private static final String USSTR = "Update-Source";
    private static final String EBSTR = "EBGP-Multihops";
    private static final String AFSTR = "Address-Families";
    private static final String ERSTR = "Export-RTs";
    private static final String IRSTR = "Import-RTs";
    private static final String NHSTR = "Nexthop";
    private static final String LBSTR = "Label";
    private static final String RDSTR = "RD";

    private Object usage() {
        System.err.println
            ("usage: bgp-cache ["+LST+" vrfs | networks] ["+OFL+" file-name]");
        return null;
    }

    public Cache() {
    }

    public Object show() throws Exception {
        return doExecute();
    }

    @Override
    protected Object doExecute() throws Exception {
        if (!Commands.bgpRunning()) {
            return null;
        }
        Bgp config = Commands.getBgpManager().getConfig();
        boolean list_vrfs = false;
        boolean list_nets = false;
        PrintStream ps = System.out;

        if (action != null) {
            return usage();
        }
        if (ofile != null) {
            try {
                ps = new PrintStream(ofile);
            } catch (Exception e) {
                System.err.println("error: cannot create file "+ofile +"; exception: "+e);
                return null;
            }
        }
        if (list != null) {
            for (String item : list) {
                switch (item) {
                    case "vrfs" :
                        list_vrfs = true;
                        break;
                    case "networks" :
                        list_nets = true;
                        break;
                    default:
                        System.err.println("error: unknown value for "+LST+": "+item);
                    return null;
                }
            }
        }
        // we'd normally read this directly from 'config' but
        // legacy behaviour forces to check for a connection
        // that's initiated by default at startup without
        // writing to config.
        String cHost = Commands.getBgpManager().getConfigHost();
        int cPort = Commands.getBgpManager().getConfigPort();
        ps.printf("\nConfiguration Server\n\t%s  %s\n\t%s  %d\n",
                  HTSTR, cHost, PTSTR, cPort);
        if (config == null) {
            return null;
        }
        AsId a = config.getAsId();
        if (a != null) {
            int asNum = a.getLocalAs().intValue();
            Ipv4Address routerId = a.getRouterId();
            Long spt = a.getStalepathTime();
            Boolean afb = a.isAnnounceFbit();
            String rid = (routerId == null) ? "<n/a>" : routerId.getValue();
            int s = (spt == null) ? 0 : spt.intValue();
            //F-bit is always set to ON (hardcoded), in SDN even though the controller is down
            //forwarding state shall be retained.
            String bit = "ON";

            GracefulRestart g = config.getGracefulRestart();
            if (g != null) {
                s = g.getStalepathTime().intValue();
            }
            ps.printf("\nBGP Router\n");
            ps.printf("\t%-15s  %d\n\t%-15s  %s\n\t%-15s  %s\n\t%-15s  %s\n",
                      ASSTR, asNum, RISTR, rid, SPSTR, (s!=0?Integer.toString(s):"default"), FBSTR, bit);
        }

        Logging l = config.getLogging();
        if (l != null) {
            ps.printf("\t%-15s  %s\n\t%-15s  %s\n", LFSTR, l.getFile(),
            LLSTR, l.getLevel());
        }

        List<Neighbors> n = config.getNeighbors();
        if (n != null)  {
            ps.printf("\nNeighbors\n");
            for (Neighbors nbr : n) {
                ps.printf("\t%s\n\t\t%-16s  %d\n", nbr.getAddress().getValue(),
                          ASSTR, nbr.getRemoteAs().intValue());
                EbgpMultihop en = nbr.getEbgpMultihop();
                if (en != null) {
                    ps.printf("\t\t%-16s  %d\n", EBSTR, en.getNhops().intValue());
                }
                UpdateSource us = nbr.getUpdateSource();
                if (us != null) {
                    ps.printf("\t\t%-16s  %s\n", USSTR, us.getSourceIp().getValue());
                }
                ps.printf("\t\t%-16s  IPv4-Labeled-VPN", AFSTR);
                List<AddressFamilies> afs = nbr.getAddressFamilies();
                if (afs != null) {
                    for (AddressFamilies af : afs) {
                        ps.printf(" %s", af.getSafi().intValue() == 4 ?
                                            "IPv4-Labeled-Unicast" : "Unknown");
                    }
                }
                ps.printf("\n");
            }
        }

        if (list_vrfs) {
            List<Vrfs> v = config.getVrfs();
            if (v != null) {
                ps.printf("\nVRFs\n");
                for (Vrfs vrf : v)  {
                    ps.printf("\t%s\n",vrf.getRd());
                    ps.printf("\t\t%s  ", IRSTR);
                    for (String rt : vrf.getImportRts())
                    ps.printf("%s ", rt);
                    ps.printf("\n\t\t%s  ", ERSTR);
                    for (String rt : vrf.getExportRts())
                    ps.printf("%s ", rt);
                    ps.printf("\n");
                }
            }
        }

        if (list_nets) {
            List<Networks> ln = config.getNetworks();
            if (ln != null) {
                ps.printf("\nNetworks\n");
                for (Networks net : ln) {
                    String rd = net.getRd();
                    String pfxlen = net.getPrefixLen();
                    String nh = net.getNexthop().getValue();
                    int label = net.getLabel().intValue();
                    ps.printf("\t%s\n\t\t%-7s  %s\n\t\t%-7s  %s\n\t\t%-7s  %d\n",
                              pfxlen, RDSTR, rd, NHSTR, nh, LBSTR, label);
                }
            }
        }
        if (ofile != null) {
            ps.close();
        }
        return null;
    }
}
