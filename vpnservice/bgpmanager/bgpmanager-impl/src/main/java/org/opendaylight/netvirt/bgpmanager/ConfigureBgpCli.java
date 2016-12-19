/*
 * Copyright (c) 2015 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.bgpmanager;

import java.net.InetAddress;
import java.util.List;

import org.apache.karaf.shell.commands.Command;
import org.apache.karaf.shell.commands.Option;
import org.apache.karaf.shell.console.OsgiCommandSupport;
import org.opendaylight.netvirt.bgpmanager.thrift.gen.af_afi;
import org.opendaylight.netvirt.bgpmanager.thrift.gen.af_safi;

import org.opendaylight.yang.gen.v1.urn.ericsson.params.xml.ns.yang.ebgp.rev150901.Bgp;
import org.opendaylight.yang.gen.v1.urn.ericsson.params.xml.ns.yang.ebgp.rev150901.bgp.Neighbors;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Command(scope = "odl", name = "configure-bgp", description = "")
public class ConfigureBgpCli extends OsgiCommandSupport {

    private static final Logger LOGGER = LoggerFactory.getLogger(ConfigureBgpCli.class);

    private static BgpManager bgpManager;

    private static final long AS_MIN=0;
    private static final long AS_MAX=4294967295L;//2^32-1

    public static void setBgpManager(BgpManager mgr) {
        bgpManager = mgr;
    }

    @Option(name = "-op", aliases = {"--operation","--op"}, description = "[start-bgp-server, stop-bgp-server, add-neighbor, delete-neighbor, graceful-restart, enable-log ]",
            required = false, multiValued = false)
    String op;

    //exec configure-bgp  add-neighbor --ip <neighbor-ip> --as-num <as-num> --address-family <af> --use-source-ip <sip> --ebgp-multihops <em> --next-hop <nh>

    @Option(name = "--as-num", description = "as number of the bgp neighbor", required = false, multiValued = false)
    String asNumber = null;

    @Option(name = "--ip", description = "ip of the bgp neighbor", required = false, multiValued = false)
    String ip = null;

    @Option(name = "--address-family", description = "address family of the bgp neighbor SAFI_IPV4_LABELED_UNICAST|SAFI_MPLS_VPN", 
            required = false, multiValued = false)
    String addressFamily = null;

    @Option(name = "--use-source-ip", description = "source ip to be used for neighborship connection establishment", 
            required = false, multiValued = false)
    String sourceIp = null;

    @Option(name = "--ebgp-multihops", description = "ebgp multihops of the bgp neighbor", 
            required = false, multiValued = false)
    String ebgpMultihops = null;

    @Option(name = "--router-id", description = "router id of the bgp instance", 
            required = false, multiValued = false)
    String routerId = null;

    @Option(name = "--stalepath-time", description = "the time delay after bgp restart stalepaths are cleaned", 
            required = false, multiValued = false)
    String stalePathTime = null;

    @Option(name = "--log-file-path", description = "bgp log file path", 
            required = false, multiValued = false)
    String logFile = null;

    @Option(name = "--log-level", description = "log level emergencies,alerts,critical,errors,warnings,notifications,informational,debugging",
            required = false, multiValued = false)
    String logLevel = null;

    enum LogLevels {
        emergencies,alerts,critical,errors,warnings,notifications,informational,debugging;
    }

    @Override
    protected Object doExecute() throws Exception {
        try {
            if (op == null) {
                System.out.println("Please provide valid operation");
                usage();
                System.out.println("exec configure-bgp -op [start-bgp-server | stop-bgp-server | add-neighbor | delete-neighbor| graceful-restart| enable-log ]");
            }
            switch(op) {
            case "start-bgp-server":
                startBgp();
                break;
            case "stop-bgp-server":
                stopBgp();
                break;
            case "add-neighbor":
                addNeighbor();
                break;
            case "delete-neighbor":
                deleteNeighbor();
                break;
            case "graceful-restart":
                configureGR();
                break;
            case "enable-log" :
                enableBgpLogLevel();
                break;
            default :
                System.out.println("invalid operation");
                usage();
                System.out.println("exec configure-bgp -op [start-bgp-server | stop-bgp-server | add-neighbor | delete-neighbor| graceful-restart| enable-log ]");
            }
        } catch (Exception e) {
            log.error("failed to handle the command",e);
        }
        return null;
    }

    public boolean validateStalepathTime() {
        try {
            int time = Integer.parseInt(stalePathTime);
            if (time < 30 || time > 3600) {
                System.out.println("invalid stale path time valid range [30-3600]");
                printGracefulRestartHelp();
                return false;
            }
        } catch (Exception e) {
            System.out.println("invalid stale path time");
            printGracefulRestartHelp();
            return false;
        }
        return true;
    }

    private void configureGR() throws Exception {
        boolean validStalepathTime = validateStalepathTime();
        if (!validStalepathTime) {
            return;
        }
        bgpManager.configureGR(Integer.parseInt(stalePathTime));
    }

    private void deleteNeighbor() throws Exception {
        if (ip == null || !validateIp(ip)) {
            System.out.println("invalid neighbor ip");
            printDeleteNeighborHelp();
            return;
        }
        long asNo = getAsNumber(ip);
        if (asNo < 0) {
            System.out.println("neighbor does not exist");
            printDeleteNeighborHelp();
            return;
        }
        bgpManager.deleteNeighbor(ip);
    }

    public long getAsNumber(String nbrIp) {
        Bgp conf = bgpManager.getConfig();
        if (conf == null) {
          return -1;
        }
        List<Neighbors> nbrs = conf.getNeighbors();
        if (nbrs == null) {
          return -1;
        }
        for (Neighbors nbr : nbrs) {
          if (nbrIp.equals(nbr.getAddress().getValue())) {
             return nbr.getRemoteAs().longValue();
          }
        }
        return -1;
    }

    private void stopBgp() throws Exception {
        Bgp conf = bgpManager.getConfig();
        if (conf == null) {
            return;
        }
        List<Neighbors> nbrs = conf.getNeighbors();
        if (nbrs != null && nbrs.size() > 0) {
            System.err.println("error: all BGP congiguration must be deleted before stopping the router instance");
            return;
        }
        bgpManager.stopBgp();
    }

    void usage() {
        System.out.println("usage:");
    }

    void printStartBgpHelp() {
        usage();
        System.out.println("exec configure-bgp -op start-bgp-server --as-num <asnum> --router-id <routerid> [--stalepath-time <time>]");
    }

    void printAddNeighborHelp() {
        usage();
        System.out.println("exec configure-bgp -op add-neighbor --ip <neighbor-ip> --as-num <as-num> [--address-family <af>]  [--use-source-ip <sip>] [--ebgp-multihops <em> ]");
    }

    void printDeleteNeighborHelp() {
        usage();
        System.out.println("exec configure-bgp -op delete-neighbor --ip <neighbor-ip>");
    }

    void printEnableLogHelp() {
        usage();
        System.out.println("exec configure-bgp -op enable-logging --filename <filename> --log-level [emergencies|alerts|critical|errors|warnings|notifications|informational|debugging]");
    }

    void printGracefulRestartHelp() {
        usage();
        System.out.println("exec configure-bgp -op graceful-restart --stalepath-time <30-3600>");
    }

    private void startBgp() throws Exception {
        boolean validRouterId = false;

        if (bgpManager.getConfig() != null &&
               bgpManager.getConfig().getAsId() != null) {
            System.out.println("bgp is already started please use stop-bgp-server and start again");
            return;
        }
        if(!validateAsNumber(asNumber)) {
            return;
        }
        validRouterId = validateIp(routerId);
        if (!validRouterId) {
            System.out.println("invalid router id please supply valid ip address");
            printStartBgpHelp();
            return;
        }

        if (stalePathTime != null) {
            boolean validStalepathTime = validateStalepathTime();
            if (!validStalepathTime) {
                return;
            }
        }
        bgpManager.startBgp(Integer.parseInt(asNumber), routerId,
          stalePathTime == null? 0 : Integer.parseInt(stalePathTime), false);
    }

    protected void addNeighbor() throws Exception {
        if(!validateAsNumber(asNumber)) {
            return;
        }

        boolean validIp = validateIp(ip);
        if (!validIp) {
            System.out.println("invalid neighbor ip");
            printAddNeighborHelp();
            return;
        }

        if (sourceIp != null) {
            validIp = validateIp(sourceIp);
            if (!validIp) {
                System.out.println("invalid source ip");
                printAddNeighborHelp();
                return;
            }
        }

        if (ebgpMultihops != null) {
            try {
                long val = Long.valueOf(ebgpMultihops);
                if (val < 1 || val > 255) {
                    System.out.println("invalid ebgpMultihops number , valid range [1,255] ");
                    printAddNeighborHelp();
                    return;
                }
            } catch (Exception e) {
                System.out.println("invalid ebgpMultihops number, valid range [1-255]");
                printAddNeighborHelp();
                return;
            }
        }
        if (addressFamily != null) {
            try {
                af_safi.valueOf(addressFamily);
            } catch (Exception e) {
                System.out.println("invalid addressFamily valid values SAFI_IPV4_LABELED_UNICAST | SAFI_MPLS_VPN");
                printAddNeighborHelp();
                return;
            }
        }
        if (getAsNumber(ip) != -1) {
            System.out.println("neighbor with ip "+ip+" already exists");
            return;
        }
        bgpManager.addNeighbor(ip, Long.valueOf(asNumber));
        if (addressFamily != null) {
            bgpManager.addAddressFamily(ip, af_afi.AFI_IP, 
                                 af_safi.valueOf(addressFamily));
        }
        if (ebgpMultihops != null) {
            bgpManager.addEbgpMultihop(ip, Integer.parseInt(ebgpMultihops));
        }
        if (sourceIp != null) {
            bgpManager.addUpdateSource(ip, sourceIp);
        }
    }

    private boolean validateIp(String inputIp) {
        boolean validIp = false;
        try {
            if (inputIp != null) {
                InetAddress addr = InetAddress.getByName(inputIp);
                if (addr.isMulticastAddress()) {
                    System.out.println("ip cannot be multicast address");
                    return false;
                }
                if (addr.isLoopbackAddress()) {
                    System.out.println("ip cannot be loopback address");
                    return false;
                }
                byte addrBytes[] = addr.getAddress();
                int lastPart = addrBytes[3] & 0xFF;
                int firstPart = addrBytes[0] & 0xFF;
                if (firstPart == 0) {
                    return false;//cannot start with 0 "0.1.2.3"
                }
                if (lastPart == 0 || lastPart == 255) {
                    return false;
                }
                validIp = true;
            }
        } catch (Exception e) {
        }
        return validIp;
    }

    private void enableBgpLogLevel() throws Exception {
        if (logFile == null) {
            System.out.println("Please provide log file name ");
            usage();
            System.out.println("exec configure-bgp -op enable-log --log-file-path <logfile> --log-level <level>");
            return;
        }
        boolean validLoglevel = false;
        try {
            LogLevels.valueOf(logLevel);
            validLoglevel = true;
        } catch (Exception e) {
        }
        if (!validLoglevel) {
            System.out.println("Please provide valid log level emergencies|alerts|critical|errors|warnings|notifications|informational|debugging");
            usage();
            System.out.println("exec configure-bgp -op enable-log --log-file-path <logfile> --log-level <level>");
            return;
        }
        bgpManager.setQbgpLog(logFile, logLevel);
    }

    private boolean validateAsNumber(String strAsnum){

        try {
            long asNum = Long.valueOf(strAsnum);
            switch((int)asNum) {
                case 0:
                case 65535:
                case 23456:
                    System.out.println("reserved AS Number supplied ");
                    printStartBgpHelp();
                    return false;
            }
            if (asNum <= AS_MIN || asNum > AS_MAX) {
                System.out.println("invalid AS Number , supported range [1,"+AS_MAX+"]");
                printStartBgpHelp();
                return false;
            }
        } catch (Exception e) {
            System.out.println("invalid AS Number ");
            printStartBgpHelp();
            return false;
        }
        return true;
    }
}
