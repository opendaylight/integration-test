/*
 * Copyright (c) 2015 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.bgpmanager;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.net.Socket;
import java.net.SocketTimeoutException;
import java.net.UnknownHostException;
import org.apache.karaf.shell.commands.Command;
import org.apache.karaf.shell.commands.Option;
import org.apache.karaf.shell.console.OsgiCommandSupport;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Command(scope = "odl", name = "show-bgp", description = "")
public class VtyshCli extends OsgiCommandSupport {
    // public class DisplayBgpConfigCli {

    @Option(name = "--cmd", description = "command to run", required = true, multiValued = false)
    String cmd = null;

    private static final Logger LOGGER = LoggerFactory.getLogger(VtyshCli.class);

    private static int serverPort = 2605;
    private static String serverName = "localhost";
    private static int handlerModule = 0;
    private static final int BGPd = 1;
    public static String passwordCheckStr = "Password:";
    public static String vtyPassword = "sdncbgpc";
    public static String noPaginationCmd = "terminal length 0";
    public static int sockTimeout = 5;

    String[] validCommands = new String[]{
            "display routing ip bgp vpnv4 all",
            "display routing ip bgp vpnv4 rd <rd>",
            "display routing ip bgp vpnv4 all neighbors",
            "display routing ip bgp vpnv4 all neighbors  <ip> routes",
            "display routing ip bgp vpnv4 all  <ip/mask>",
            "display routing ip bgp vpnv4 all summary",
            "display routing ip bgp vpnv4 all tags",
            "display routing ip bgp vpnv4 rd <rd>  tags",
            "display routing ip bgp vpnv4 rd <rd>  <ip>",
            "display routing ip bgp vpnv4 rd <rd>  <ip/mask>",
            "display routing ip bgp neighbors",
            "display routing ip bgp summary",
            "display routing ip bgp ipv4 unicast",
            "display routing ip bgp ipv4 unicast <ip/mask>",
            "display routing bgp neighbors",
            "display routing bgp neighbors <ip>",
            "display routing bgp ipv4 unicast <ip>",
            "display routing bgp ipv4 unicast <ip/mask>"
    };
    private static final Logger logger = LoggerFactory.getLogger(VtyshCli.class);

    // @Override
    protected Object doExecute() throws Exception {
        String sArg;
        cmd = cmd.trim();
        if (cmd.equals("") || cmd.equals("help") ||
            cmd.equals("-help") || cmd.equals("--help")) {
            for (String help : validCommands) {
                System.out.println(help);
            }
            return null;
        }
        String args[] = cmd.split(" ");
        if (args.length == 0) {
            return null;
        }
        sArg = args[0];
        if (sArg == null || sArg.trim().equals("")) {
            System.out.println("Please provide a valid input.");
            return null;
        }
        switch (sArg) {
        case "ip":
        case "bgp":
            handlerModule = BGPd;
            break;
        default:
            System.out.println("Unknown command");
            return null;
        }

        switch (handlerModule) {
        case BGPd:
            try {
                handleCommand(sArg, cmd);
            } catch (IOException ioe) {
                System.out.println("IOException thrown.");
            }
            break;
        default:
            break;
        }
        return null;
    }

    public static void setHostAddr(String hostAddr) {
        serverName = hostAddr;
    }

    public String getHostAddr() {
        return serverName;
    }

    public static void handleCommand(String arg, String cmd) throws IOException {

        StringBuilder inputBgpCmd = new StringBuilder();

        String str, prompt, replacedStr, inputCmd = null;
        char cbuf[] = new char[10];
        char op_buf[];
        Socket socket = null;
        PrintWriter out_to_socket = null;
        BufferedReader in_from_socket = null;
        StringBuilder sb = new StringBuilder();
        int ip = 0, ret;
        StringBuilder temp, temp2;
        char ch, gt = '>', hashChar = '#';

        inputBgpCmd.append("show " + cmd);

        inputCmd = inputBgpCmd.toString();

        try {
            socket = new Socket(serverName, serverPort);

        } catch (UnknownHostException ioe) {
            System.out.println("No host exists: " + ioe.getMessage());
            return;
        } catch (IOException ioe) {
            System.out.println("I/O error occured " + ioe.getMessage());
            return;
        }
        try {
            socket.setSoTimeout(sockTimeout * 1000);
            out_to_socket = new PrintWriter(socket.getOutputStream(), true);
            in_from_socket = new BufferedReader(new InputStreamReader(socket.getInputStream()));

        } catch (IOException ioe) {
            System.out.println("IOException thrown.");
            socket.close();
            return;
        }
        while (true) {
            try {
                ret = in_from_socket.read(cbuf);

            } catch (SocketTimeoutException ste) {
                System.out.println("Read from Socket timed Out while asking for password.");
                socket.close();
                return;
            }
            if (ret == -1) {
                System.out.println("Connection closed by BGPd.");
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
            } catch (SocketTimeoutException ste) {
                System.out.println(sb.toString());
                System.out.println("Read from Socket timed Out while verifying the password.");
                socket.close();
                return;
            }
            if ((ip == (int) gt) || (ip == (int) hashChar)) {
                if (ip == (int) gt) {
                    sb.append(gt);
                } else {
                    sb.append(hashChar);
                }
                break;
            } else if (ip == -1) {
                System.out.println(sb.toString());
                System.out.println("Connection closed by BGPd.");
                socket.close();
                return;
            } else {
                ch = (char) ip;
                sb.append(ch);

            }
        }

        String promptStr = sb.toString();
        prompt = promptStr.trim();
        sb.setLength(0);
        out_to_socket.println(noPaginationCmd);
        while (true) {
            try {
                ip = in_from_socket.read();
            } catch (SocketTimeoutException ste) {
                System.out.println(sb.toString());
                System.out.println("Read from Socket timed Out while sending the term len command..");
                socket.close();
                return;
            }
            if ((ip == (int) gt) || (ip == (int) hashChar)) {
                break;
            } else if (ip == -1) {
                System.out.println(sb.toString());
                System.out.println("Connection closed by BGPd.");
                socket.close();
                return;
            } else {
                ch = (char) ip;
                sb.append(ch);

            }
        }
        sb.setLength(0);

        out_to_socket.println(inputCmd);
        StringBuffer output = new StringBuffer();
        String errorMsg = "";
        while (true) {
            op_buf = new char[100];
            temp = new StringBuilder();
            temp2 = new StringBuilder();
            try {
                ret = in_from_socket.read(op_buf);

            } catch (SocketTimeoutException ste) {
                errorMsg = "Read from Socket timed Out while getting the data.";
                break;
            }
            if (ret == -1) {
                errorMsg = "Connection closed by BGPd";
                break;
            }
            temp2.append(op_buf);

            if (temp2.toString().contains(inputCmd)) {

                replacedStr = temp2.toString().replaceAll(inputCmd, "");
                temp.append(replacedStr);
                temp2.setLength(0);

            } else {
                temp.append(op_buf);
                temp2.setLength(0);

            }

            String outputStr = temp.toString();
            outputStr.replaceAll("^\\s+|\\s+$", "");
            output.append(outputStr);
            if (output.toString().trim().endsWith(prompt)) {
                int index = output.toString().lastIndexOf(prompt);
                String newString = output.toString().substring(0, index);
                output.setLength(0);
                output.append(newString);
                break;
            }
            temp.setLength(0);
        }
        System.out.println(output.toString().trim());
        if (errorMsg.length() > 0) {
            System.out.println(errorMsg);
        }
        socket.close();
        return;

    }

}
