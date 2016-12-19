/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.elan.cli.l2gw;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.PrintStream;
import java.util.Map;
import java.util.concurrent.ConcurrentMap;
import org.apache.karaf.shell.commands.Command;
import org.apache.karaf.shell.commands.Option;
import org.apache.karaf.shell.console.OsgiCommandSupport;
import org.opendaylight.genius.utils.cache.CacheUtil;
import org.opendaylight.genius.utils.hwvtep.HwvtepHACache;
import org.opendaylight.netvirt.elanmanager.utils.ElanL2GwCacheUtils;
import org.opendaylight.netvirt.neutronvpn.api.l2gw.L2GatewayDevice;
import org.opendaylight.netvirt.neutronvpn.api.l2gw.utils.L2GatewayCacheUtils;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.Node;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Command(scope = "l2gw", name = "show-cache", description = "display l2gateways cache")
public class L2GwUtilsCacheCli extends OsgiCommandSupport {
    private static final Logger LOG = LoggerFactory.getLogger(L2GwUtilsCacheCli.class);

    private static final String DEMARCATION = "=================================";

    @Option(name = "-cache", aliases = {"--cache"}, description = "cache name",
            required = false, multiValued = false)
    String cacheName = null;

    @Option(name = "-elan", aliases = {"--elan"}, description = "elan name",
            required = false, multiValued = false)
    String elanName;

    @Override
    protected Object doExecute() throws IOException {
        if (cacheName == null) {
            session.getConsole().println("Available caches");
            session.getConsole().println(ElanL2GwCacheUtils.L2GATEWAY_CONN_CACHE_NAME);
            session.getConsole().println(L2GatewayCacheUtils.L2GATEWAY_CACHE_NAME);
            session.getConsole().println("HA");
            session.getConsole().println("HA_EVENTS");
            return null;
        }
        switch (cacheName) {
            case ElanL2GwCacheUtils.L2GATEWAY_CONN_CACHE_NAME:
                dumpElanL2GwCache();
                break;
            case L2GatewayCacheUtils.L2GATEWAY_CACHE_NAME:
                dumpL2GwCache();
                break;
            case "HA":
                dumpHACache(session.getConsole());
                break;
            case "HA_EVENTS":
                dumpHACacheEvents();
                break;
            default:
                break;
        }
        return null;
    }

    private void dumpHACacheEvents() throws IOException {
        try (FileOutputStream fileOutputStream = new FileOutputStream(new File("hwvtep.events.txt"))) {
            session.getConsole().println("Dumping to file hwvtep.events.txt");
            PrintStream fos = new PrintStream(fileOutputStream);
            dumpHACache(fos);
            fos.close();
            session.getConsole().println("Dumped to file " + new File("hwvtep.events.txt").getAbsolutePath());
        }
    }

    private void dumpHACache(PrintStream printStream) {

        printStream.println("HA enabled nodes");
        for (InstanceIdentifier<Node> id : HwvtepHACache.getInstance().getHAChildNodes()) {
            String nodeId = id.firstKeyOf(Node.class).getNodeId().getValue();
            printStream.println(nodeId);
        }

        printStream.println("HA parent nodes");
        for (InstanceIdentifier<Node> id : HwvtepHACache.getInstance().getHAParentNodes()) {
            String nodeId = id.firstKeyOf(Node.class).getNodeId().getValue();
            printStream.println(nodeId);
            for (InstanceIdentifier<Node> childId : HwvtepHACache.getInstance().getChildrenForHANode(id)) {
                nodeId = childId.firstKeyOf(Node.class).getNodeId().getValue();
                printStream.println("    " + nodeId);
            }
        }

        printStream.println("Connected Nodes");
        Map<String, Boolean> nodes = HwvtepHACache.getInstance().getConnectedNodes();
        for (String nodeId : nodes.keySet()) {
            printStream.print(nodeId);
            printStream.print("    : connected : ");
            printStream.println(nodes.get(nodeId));
        }
    }

    private void dumpL2GwCache() {
        ConcurrentMap<String, L2GatewayDevice> devices = (ConcurrentMap<String, L2GatewayDevice>) CacheUtil
                .getCache(L2GatewayCacheUtils.L2GATEWAY_CACHE_NAME);
        if (devices == null) {
            session.getConsole().println("no devices are present in cache");
            return;
        }
        for (String deviceName : devices.keySet()) {
            session.getConsole().println("device " + devices.get(deviceName));
        }
    }

    private void dumpElanL2GwCache() {
        if (elanName == null) {
            ConcurrentMap<String, ConcurrentMap<String, L2GatewayDevice>> cache =
                    (ConcurrentMap<String, ConcurrentMap<String, L2GatewayDevice>>) CacheUtil.getCache(
                            cacheName);
            if (cache == null) {
                session.getConsole().println("no devices are present in elan cache");
            }
            for (String elan : cache.keySet()) {
                print(elan, cache.get(elan));
                session.getConsole().println(DEMARCATION);
                session.getConsole().println(DEMARCATION);
            }
            return;
        }
        ConcurrentMap<String, L2GatewayDevice> elanDevices = ElanL2GwCacheUtils
                .getInvolvedL2GwDevices(elanName);
        print(elanName, elanDevices);
    }

    private void print(String elan, ConcurrentMap<String, L2GatewayDevice> devices) {
        session.getConsole().println("Elan name : " + elan);
        session.getConsole().println("No of devices in elan " + devices.keySet().size());
        for (String deviceName : devices.keySet()) {
            session.getConsole().println("device " + devices.get(deviceName));
        }
    }
}
