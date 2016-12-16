/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.neutronvpn.shell;

import org.apache.karaf.shell.commands.Command;
import org.apache.karaf.shell.commands.Option;
import org.apache.karaf.shell.console.OsgiCommandSupport;
import org.opendaylight.controller.sal.binding.api.RpcProviderRegistry;
import org.opendaylight.netvirt.neutronvpn.interfaces.INeutronVpnManager;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.CreateL3VPNInputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.CreateL3VPNOutput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.DeleteL3VPNInputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.DeleteL3VPNOutput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.NeutronvpnService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.createl3vpn.input.L3vpn;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.createl3vpn.input.L3vpnBuilder;
import org.opendaylight.yangtools.yang.common.RpcResult;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;

@Command(scope = "vpnservice", name = "configure-l3vpn", description = "Create/Delete Neutron L3VPN")
public class ConfigureL3VpnCommand extends OsgiCommandSupport {

    final Logger Logger = LoggerFactory.getLogger(ConfigureL3VpnCommand.class);

    private INeutronVpnManager neutronVpnManager;
    private RpcProviderRegistry rpcProviderRegistry;
    private NeutronvpnService neutronvpnService;

    public void setNeutronVpnManager(INeutronVpnManager neutronVpnManager) {
        this.neutronVpnManager = neutronVpnManager;
    }

    public void setRpcRegistry(RpcProviderRegistry rpcProviderRegistry) {
        this.rpcProviderRegistry = rpcProviderRegistry;
    }

    @Option(name = "-op", aliases = {"--operation"}, description = "create-l3-vpn/delete-l3-vpn",
            required = false, multiValued = false)
    String op;

    @Option(name = "-vid", aliases = {"--vpnid"}, description = "VPN ID", required = false, multiValued = false)
    String vid;

    @Option(name = "-n", aliases = {"--name"}, description = "VPN Name", required = false, multiValued = false)
    String name;

    @Option(name = "-tid", aliases = {"--tenantid"}, description = "Tenant ID", required = false, multiValued = false)
    String tid;

    @Option(name = "-rd", aliases = {"--rd"}, description = "Route Distinguisher", required = false, multiValued =
            false)
    String rd;

    @Option(name = "-irt", aliases = {"--import-rts"}, description = "List of Import RTs", required = false,
            multiValued = false)
    String irt;

    @Option(name = "-ert", aliases = {"--export-rts"}, description = "List of Export RTs", required = false,
            multiValued = false)
    String ert;

    @Option(name = "-sid", aliases = {"--subnet-uuid"}, description = "List of Subnet IDs", required = false,
            multiValued = false)
    String sid;

    @Override
    protected Object doExecute() throws Exception {

        if (rpcProviderRegistry != null) {
            neutronvpnService = rpcProviderRegistry.getRpcService(NeutronvpnService.class);
            if (neutronvpnService != null) {
                if (op != null) {
                    switch (op) {
                        case "create-l3-vpn":
                            createL3VpnCLI();
                            break;
                        case "delete-l3-vpn":
                            deleteL3VpnCLI();
                            break;
                        default:
                            session.getConsole().println("Invalid argument.");
                            session.getConsole().println(getHelp(""));
                            break;
                    }
                } else {
                    session.getConsole().println("Too few arguments");
                    session.getConsole().println(getHelp(""));
                }
            } else {
                session.getConsole().println("neutronvpnservice not initialized");
            }
        } else {
            session.getConsole().println("rpcProviderRegistryService not initialized");
        }
        return null;
    }

    public void createL3VpnCLI() {

        if (vid == null) {
            session.getConsole().println("Please supply a valid VPN ID");
            session.getConsole().println(getHelp("create"));
            return;
        }

        if (rd == null) {
            session.getConsole().println("Please supply a valid RD");
            session.getConsole().println(getHelp("create"));
            return;
        }

        if (irt == null) {
            session.getConsole().println("Please supply a valid list of import RTs separated by {,}");
            session.getConsole().println(getHelp("create"));
            return;
        }

        if (ert == null) {
            session.getConsole().println("Please supply a valid list of export RTs separated by {,}");
            session.getConsole().println(getHelp("create"));
            return;
        }

        Uuid vuuid = new Uuid(vid);

        try {
            ArrayList<String> rdList = new ArrayList<>(Arrays.asList(rd.split(",")));
            ArrayList<String> irtList = new ArrayList<>(Arrays.asList(irt.split(",")));
            ArrayList<String> ertList = new ArrayList<>(Arrays.asList(ert.split(",")));
            Uuid tuuid = null;

            if (tid != null) {
                tuuid = new Uuid(tid);
            }

            List<L3vpn> l3vpns = new ArrayList<>();
            L3vpn l3vpn = new L3vpnBuilder().setId(vuuid).setName(name).setRouteDistinguisher(rdList).setImportRT
                    (irtList)
                    .setExportRT(ertList).setTenantId(tuuid).build();
            l3vpns.add(l3vpn);
            Future<RpcResult<CreateL3VPNOutput>> result =
                    neutronvpnService.createL3VPN(new CreateL3VPNInputBuilder().setL3vpn(l3vpns).build());
            RpcResult<CreateL3VPNOutput> rpcResult = result.get();
            if (rpcResult.isSuccessful()) {
                session.getConsole().println("L3VPN created successfully");
                Logger.trace("createl3vpn: {}", result);
            } else {
                session.getConsole().println("error populating createL3VPN : " + result.get().getErrors());
                session.getConsole().println(getHelp("create"));
            }
        } catch (InterruptedException | ExecutionException e) {
            Logger.error("error populating createL3VPN", e);
            session.getConsole().println("error populating createL3VPN : " + e.getMessage());
            session.getConsole().println(getHelp("create"));
        }

        try {
            List<Uuid> sidList = new ArrayList<>();

            if (sid != null) {
                for (String sidStr : sid.split(",")) {
                    Uuid suuid = new Uuid(sidStr);
                    sidList.add(suuid);
                }
            }
            for (Uuid subnet : sidList) {
                neutronVpnManager.addSubnetToVpn(vuuid, subnet);
            }

        } catch (Exception e) {
            Logger.error("error in adding subnet to VPN", e);
            session.getConsole().println("error in adding subnet to VPN : " + e.getMessage());
        }
    }

    public void deleteL3VpnCLI() {

        if (vid == null) {
            session.getConsole().println("Please supply a valid VPN ID");
            session.getConsole().println(getHelp("delete"));
            return;
        }
        Uuid vpnid = new Uuid(vid);
        try {
            List<Uuid> sidList = neutronVpnManager.getSubnetsforVpn(vpnid);
            if (sidList != null) {
                for (Uuid subnet : sidList) {
                    neutronVpnManager.removeSubnetFromVpn(vpnid, subnet);
                }
            }
        } catch (Exception e) {
            Logger.error("error in deleting subnet from VPN", e);
            session.getConsole().println("error in deleting subnet from VPN : " + e.getMessage());
        }

        try {
            List<Uuid> vpnIdList = new ArrayList<>();
            vpnIdList.add(vpnid);

            Future<RpcResult<DeleteL3VPNOutput>> result =
                    neutronvpnService.deleteL3VPN(new DeleteL3VPNInputBuilder().setId(vpnIdList).build());
            RpcResult<DeleteL3VPNOutput> rpcResult = result.get();
            if (rpcResult.isSuccessful()) {
                session.getConsole().println("L3VPN deleted successfully");
                Logger.trace("deletel3vpn: {}", result);
            } else {
                session.getConsole().println("error populating deleteL3VPN : " + result.get().getErrors());
                session.getConsole().println(getHelp("delete"));
            }
        } catch (InterruptedException | ExecutionException e) {
            Logger.error("error populating deleteL3VPN", e);
            session.getConsole().println("error populating deleteL3VPN : " + e.getMessage());
            session.getConsole().println(getHelp("delete"));
        }
    }

    private String getHelp(String cmd) {
        StringBuilder help = new StringBuilder("Usage:");
        switch (cmd) {
            case "create":
                help.append("exec configure-vpn -op/--operation create-l3-vpn -vid/--vpnid <id>\n");
                help.append("-rd/--rd <rd> -irt/--import-rts <irt1,irt2,..> -ert/--export-rts <ert1,ert2,..>\n");
                help.append("[-sid/--subnet-uuid <subnet1,subnet2,..>]\n");
                break;
            case "delete":
                help.append("exec configure-vpn -op/--operation delete-l3-vpn -vid/--vpnid <id> \n");
                break;
            case "":
                help.append("exec configure-vpn -op/--operation create-l3-vpn -vid/--vpnid <id>\n");
                help.append("-rd/--rd <rd> -irt/--import-rts <irt1,irt2,..> -ert/--export-rts <ert1,ert2,..>\n");
                help.append("[-sid/--subnet-uuid <subnet1,subnet2,..>]\n");
                help.append("exec configure-vpn -op/--operation delete-l3-vpn -vid/--vpnid <id> \n");
        }
        return help.toString();
    }

}
