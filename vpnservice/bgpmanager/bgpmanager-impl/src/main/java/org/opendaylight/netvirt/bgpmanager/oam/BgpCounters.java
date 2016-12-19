/*
 * Copyright (c) 2015 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.bgpmanager.oam;

import javax.management.JMException;
import javax.management.MBeanServer;
import javax.management.ObjectName;
import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.lang.management.ManagementFactory;
import java.net.Socket;
import java.net.SocketException;
import java.net.SocketTimeoutException;
import java.net.UnknownHostException;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Scanner;
import java.util.TimerTask;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.opendaylight.netvirt.bgpmanager.BgpManager;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


/**
 * Created by ECHIAPT on 8/4/2015.
 */
public class BgpCounters extends TimerTask {

    private static final Logger LOGGER = LoggerFactory.getLogger(BgpCounters.class);
    public static BgpCountersBroadcaster bgpStatsBroadcaster = null;
    public MBeanServer bgpStatsServer = null;
    public  Map <String, String> countersMap = new HashMap<String, String>();
    private String bgpSdncMip = "127.0.0.1";

    public BgpCounters(String mipAddress) {
        bgpSdncMip = mipAddress;
    }

    @Override
    public void run () {
        try {
            LOGGER.debug("Fetching counters from BGP");
            resetCounters();
            fetchCmdOutputs("cmd_ip_bgp_summary.txt","show ip bgp summary");
            fetchCmdOutputs("cmd_bgp_ipv4_unicast_statistics.txt", "show bgp ipv4 unicast statistics");
            fetchCmdOutputs("cmd_ip_bgp_vpnv4_all.txt", "show ip bgp vpnv4 all");
            parse_ip_bgp_summary();
            parse_bgp_ipv4_unicast_statistics();
            parse_ip_bgp_vpnv4_all();
            if (LOGGER.isDebugEnabled()) {
                dumpCounters();
            }
            if (bgpStatsBroadcaster == null) {
                //First time execution
                try {
                    bgpStatsBroadcaster = new BgpCountersBroadcaster();
                    bgpStatsServer = ManagementFactory.getPlatformMBeanServer();
                    ObjectName bgpStatsObj = new ObjectName("SDNC.PM:type=BgpCountersBroadcaster");
                    bgpStatsServer.registerMBean(bgpStatsBroadcaster, bgpStatsObj);
                    LOGGER.info("BGP Counters MBean Registered :::");
                } catch (JMException e) {
                    LOGGER.error("Adding a NotificationBroadcaster failed." , e);
                    return;
                }
            }
            bgpStatsBroadcaster.setBgpCountersMap(countersMap);
            LOGGER.debug("Finished updating the counters from BGP");
        } catch (Exception e) {
            LOGGER.error("Failed to publish bgp counters ", e);
        }
    }

    public void dumpCounters () {
        for (Map.Entry<String, String> entry : countersMap.entrySet()) {
            LOGGER.debug("{}, Value = {}", entry.getKey(), entry.getValue());
        }
    }

    public void fetchCmdOutputs (String filename, String cmdName) throws  IOException  {
        Socket socket;
        int serverPort = 2605;
        String serverName = bgpSdncMip;
        int sockTimeout = 2;
        PrintWriter out_to_socket;
        BufferedReader in_from_socket;
        char cbuf[] = new char[10];
        char op_buf[];
        StringBuilder sb = new StringBuilder();
        int ip, ret;
        StringBuilder temp;
        char ch, gt = '>', hash = '#';
        String vtyPassword = BgpConstants.QBGP_VTY_PASSWORD;
        String passwordCheckStr = "Password:";
        String enableString = "en";
        String prompt, replacedStr;

        try
        {
            socket = new Socket(serverName, serverPort);

        }
        catch (UnknownHostException ioe) {
            LOGGER.error("No host exists: " + ioe.getMessage());
            return;
        }
        catch (IOException ioe) {
            LOGGER.error("I/O error occured " + ioe.getMessage());
            return;
        }
        try {
            socket.setSoTimeout(sockTimeout*1000);
            out_to_socket = new PrintWriter(socket.getOutputStream(), true);
            in_from_socket = new BufferedReader(new InputStreamReader(socket.getInputStream()));

        } catch (IOException ioe) {
            LOGGER.error("IOException thrown.");
            socket.close();
            return;
        }
        while (true) {
            try {
                ret = in_from_socket.read(cbuf);
            }
            catch (SocketTimeoutException ste) {
                LOGGER.error("Read from Socket timed Out while asking for password.");
                socket.close();
                return;
            }
            catch (IOException ioe) {
                LOGGER.error("Caught IOException");
                socket.close();
                return;
            }
            if (ret == -1) {
                LOGGER.error("Connection closed by BGPd.");
                socket.close();
                return;
            } else {
                sb.append(cbuf);
                if (sb.toString().contains(passwordCheckStr)) {
                    break;
                }
            }
        }

        sb.setLength(0);
        out_to_socket.println(vtyPassword);

        while (true) {
            try {
                ip = in_from_socket.read();
            }
            catch (SocketTimeoutException ste) {
                LOGGER.error(sb.toString());
                LOGGER.error("Read from Socket timed Out while verifying the password.");
                socket.close();
                return;
            }
            if (ip == (int)gt || ip == (int)hash) {
                break;
            } else if (ip == -1) {
                LOGGER.error(sb.toString());
                LOGGER.error("Connection closed by BGPd.");
                socket.close();
                return;
            } else {
                ch = (char)ip;
                sb.append(ch);

            }
        }

        prompt = sb.toString();
        prompt = prompt.trim();
        sb.setLength(0);
        out_to_socket.println(enableString);

        while (true) {
            try {
                ip = in_from_socket.read();
            }
            catch (SocketTimeoutException ste) {
                LOGGER.error(sb.toString());
                LOGGER.error("Read from Socket timed Out while keying the en keyword.");
                socket.close();
                return;
            }
            if (ip == (int)hash) {
                break;
            } else if (ip == -1) {
                LOGGER.error(sb.toString());
                LOGGER.error("Connection closed by BGPd.");
                socket.close();
                return;
            } else {
                ch = (char)ip;
                sb.append(ch);

            }
        }
        sb.setLength(0);
        temp = new StringBuilder();
        File file;
        FileWriter fileWritter;
        BufferedWriter bufferWritter;

        try {
            file = new File(filename);
            if (!file.exists()) {
                file.createNewFile();
            }
            fileWritter = new FileWriter(file.getName(), true);
            bufferWritter = new BufferedWriter(fileWritter);
        } catch (IOException e) {
            return;
        }
        out_to_socket.println(cmdName);
        temp.setLength(0);
        while (true) {
            try {
                op_buf = new char[100];
                ret = in_from_socket.read(op_buf);

            } catch (SocketTimeoutException ste) {
                break;
            } catch (SocketException soc) {
                break;
            } catch (IOException ioe) {
                ioe.printStackTrace();
                break;
            }

            if (ret == -1) {
                break;
            }
            temp.append(op_buf);
        }
        String outputStr = temp.toString();
        StringBuffer output = new StringBuffer();

        outputStr.replaceAll("^\\s+|\\s+$", "");
        output.append(outputStr);
        if (output.toString().trim().contains(prompt)) {
            int index = output.toString().lastIndexOf(prompt);
            String newString = output.toString().substring(0, index);
            output.setLength(0);
            output.append(newString);
        }
        try {
            bufferWritter.write(output.toString().trim());
            temp.setLength(0);
        } catch (IOException e) {
            e.printStackTrace();
            return;
        }
        try {
            bufferWritter.close();
            fileWritter.close();
            socket.close();

        } catch (IOException e) {
            e.printStackTrace();
            return;
        }
    }

    public static boolean validate(final String ip){
        if (ip == null || ip.equals("")) {
            return false;
        }
        final String PATTERN =
                "^(([01]?\\d\\d?|2[0-4]\\d|25[0-5])\\.){3}([01]?\\d\\d?|2[0-4]\\d|25[0-5])$";
        Pattern pattern = Pattern.compile(PATTERN);
        Matcher matcher = pattern.matcher(ip);
        return matcher.matches();
    }


    /*
     * The below function parses the output of "show ip bgp summary" saved in a file.
     * Below is the snippet for the same :-
        <output>
        BGP router identifier 10.183.254.53, local AS number 101
        .....
        Neighbor        V    AS MsgRcvd MsgSent   TblVer  InQ OutQ Up/Down  State/PfxRcd
        10.183.254.76   4   100       3       4        0    0    0 00:01:27        0
        .........
        Total number of neighbors 1
        </output>
     */

    public void parse_ip_bgp_summary() {
        File file = new File("cmd_ip_bgp_summary.txt");
        Scanner scanner;
        String lineFromFile;
        List<String> inputStrs = new ArrayList<String>();
        int i = 0;
        String as,rx, tx;
        boolean startEntries = false;
        String[] result;
        String StrIP;

        try {
            scanner = new Scanner(file);
        } catch (IOException e) {
            LOGGER.error("Could not process the file " + file.getAbsolutePath());
            return ;
        }
        while (scanner.hasNextLine()) {

            lineFromFile = scanner.nextLine();
            inputStrs.add(lineFromFile);
        }
        String str;
        StringBuilder NbrInfoKey = new StringBuilder();

        while (i < inputStrs.size()) {
            str = inputStrs.get(i);
            if (str.contains("State/PfxRcd")) {
                startEntries = true;
            } else if (startEntries == true) {
                result = str.split("\\s+");
               try {
                    StrIP = result[0].trim();
                    if (!validate(StrIP)) {
                        return;
                    }
                    as = result[2];
                    rx = result[3];
                    tx = result[4];

                    NbrInfoKey.setLength(0);
                    NbrInfoKey.append(BgpConstants.BGP_COUNTER_NBR_PKTS_RX).append(":").
                           append("BGP_Nbr_IP_").append(StrIP).append("_AS_").append(as).append("_PktsReceived");
                    countersMap.put(NbrInfoKey.toString(), rx);


                    NbrInfoKey.setLength(0);
                    NbrInfoKey.append(BgpConstants.BGP_COUNTER_NBR_PKTS_TX).append(":").
                           append("BGP_Nbr_IP_").append(StrIP).append("_AS_").append(as).append("_PktsSent");
                    countersMap.put(NbrInfoKey.toString(), tx);
                } catch (Exception e) {
                    return;
                }
            }
            i++;
        }
 }
    /*
     * The below function parses the output of "show bgp ipv4 unicast statistics" saved in a file.
     * Below is the sample output for the same :-
        <output>
        BGP IPv4 Unicast RIB statistics
        ...
        Total Prefixes                :            8
        ......
        </output>
     */

    public void parse_bgp_ipv4_unicast_statistics() {
       File file = new File("cmd_bgp_ipv4_unicast_statistics.txt");
       Scanner scanner;
       String lineFromFile;
       StringBuilder key = new StringBuilder();
       String totPfx = "";
       List<String> inputStrs = new ArrayList<String>();
       try {
           scanner = new Scanner(file);
       } catch (IOException e) {
           System.err.println("Could not process the file " + file.getAbsolutePath());
           return ;
       }
       while (scanner.hasNextLine()) {

           lineFromFile = scanner.nextLine();
           inputStrs.add(lineFromFile);
       }

       int i = 0;
       String instr;
       while (i < inputStrs.size()) {
           instr = inputStrs.get(i);
           if (instr.contains("Total Prefixes")) {
               String[] result = instr.split(":");
               try {
                   totPfx = result[1].trim();
               } catch (Exception e) {
                   totPfx = "0";
               }
               break;
           }
           i++;
       }
        key.setLength(0);
        key.append(BgpConstants.BGP_COUNTER_TOTAL_PFX).append(":").
                append("Bgp_Total_Prefixes");
        countersMap.put(key.toString(), totPfx);
    }

    /*
     *  The below function parses the output of "show ip bgp vpnv4 all" saved in a file.
     *  Below is the sample output for the same :-
     *  show ip bgp vpnv4 all
        <output>
        BGP table version is 0, local router ID is 10.183.181.21
        ......
        Route Distinguisher: 100:1
        *>i15.15.15.15/32   10.183.181.25            0    100      0 ?
        *>i17.18.17.17/32   10.183.181.25            0    100      0 ?
        *>i17.18.17.17/32   10.183.181.25            0    100      0 ?
        *>i17.18.17.17/32   10.183.181.25            0    100      0 ?
        Route Distinguisher: 100:2
        *>i16.16.16.16/32   10.183.181.25            0    100      0 ?
        *>i18.18.18.18/32   10.183.181.25            0    100      0 ?
        *>i17.18.17.17/32   10.183.181.25            0    100      0 ?
        </output>
     */
    public void parse_ip_bgp_vpnv4_all() {
        File file = new File("cmd_ip_bgp_vpnv4_all.txt");
        Scanner scanner;
        String lineFromFile;
        List<String> inputStrs = new ArrayList<String>();

        try {
            scanner = new Scanner(file);
        } catch (IOException e) {
            System.err.println("Could not process the file " + file.getAbsolutePath());
            return ;
        }
        while (scanner.hasNextLine()) {
            lineFromFile = scanner.nextLine();
            inputStrs.add(lineFromFile);
        }
        int i = 0;
        String instr, rd;
        while (i < inputStrs.size()) {
            instr = inputStrs.get(i);
            if (instr.contains("Route Distinguisher")) {
                String[] result = instr.split(":");
                rd = result[1].trim() + "_" + result[2].trim();
                i = processRouteCount(rd, i + 1,  inputStrs);

            }
            i++;
        }

    }

    public int processRouteCount(String rd, int startIndex, List<String> inputStrs) {
        int num = startIndex, route_count = 0;
        String str;
        StringBuilder key = new StringBuilder();
        str = inputStrs.get(num);

        while (str != null && !str.trim().equals("") &&
                num <inputStrs.size()) {
            if (str.contains("Route Distinguisher")) {
                key.setLength(0);
                key.append(BgpConstants.BGP_COUNTER_RD_ROUTE_COUNT).append(":").
                        append("BGP_RD_").append(rd).append("_route_count");
                countersMap.put(key.toString(), Integer.toString(route_count));
                return num - 1;
            }
            route_count++;
            num++;
            if (num == inputStrs.size()) {
                break;
            }
            str = inputStrs.get(num);
        }
        if (route_count == 0) {
            // Erroneous condition, should never happen.
            // Implies that the file contains marker for RD  without routes.
            // will form an infinite loop if not broken
            // by sending a big number back.
            return ~0;
        }
        key.setLength(0);
        key.append(BgpConstants.BGP_COUNTER_RD_ROUTE_COUNT).append(":").
                append("BGP_RD_").append(rd).append("_route_count");
        countersMap.put(key.toString(), Integer.toString(route_count));
        return num - 1;
    }

    public void resetCounters() {
        countersMap.clear();
        resetFile("cmd_ip_bgp_summary.txt");
        resetFile("cmd_bgp_ipv4_unicast_statistics.txt");
        resetFile("cmd_ip_bgp_vpnv4_all.txt");
    }

    public static void resetFile(String fileName) {
        File fileHndl = (new File(fileName));
        PrintWriter writer;
        boolean success;

        success = fileHndl.delete();
        if (!success) {
            try {
                writer = new PrintWriter(fileHndl);
                writer.print("");
                writer.close();
            } catch (Exception e) {
                return;
            }
        }

    }

    public static Map<String, String> parse_ip_bgp_vpnv4_all_summary(Map<String, String> countMap) {
        File file = new File("cmd_ip_bgp_vpnv4_all_summary.txt");
        Scanner scanner;
        String lineFromFile;
        List<String> inputStrs = new ArrayList<String>();
        int i = 0;
        boolean startEntries = false;
        String[] result;
        String StrIP;

        try {
            scanner = new Scanner(file);
        } catch (IOException e) {
            LOGGER.trace("Could not process the file " + file.getAbsolutePath());
            return null;
        }
        while (scanner.hasNextLine()) {

            lineFromFile = scanner.nextLine();
            inputStrs.add(lineFromFile);
        }
        String str;
        while (i < inputStrs.size()) {
            str = inputStrs.get(i);
            LOGGER.trace("str is:: {}", str);
            if (str.contains("State/PfxRcd")) {
                startEntries = true;
            } else if (startEntries == true) {
                result = str.split("\\s+");
                try {
                    StrIP = result[0].trim();
                    LOGGER.trace("strIP " + StrIP);

                    if (!validate(StrIP)) {
                        break;
                    }
                    String state_pfxRcvd = result[9];
                    countMap.put(StrIP, state_pfxRcvd);
                } catch (Exception e) {
                    LOGGER.trace("Exception {} caught while processing ip bgp vpnv4 all summary command output, e");
                    i++;
                    continue;
                }
            }
            i++;
        }
        return countMap;
    }

}
