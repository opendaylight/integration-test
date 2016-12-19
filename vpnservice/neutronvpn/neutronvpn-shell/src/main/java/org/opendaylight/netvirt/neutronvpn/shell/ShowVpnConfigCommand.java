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
import org.opendaylight.netvirt.neutronvpn.interfaces.INeutronVpnManager;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;

@Command(scope = "vpnservice", name = "l3vpn-config-show", description = "Displays Neutron L3VPN configuration")
public class ShowVpnConfigCommand extends OsgiCommandSupport {

    @Option(name = "-vid", aliases = {"--vpnid"}, description = "VPN ID", required = false, multiValued = false)
    String vid;

    private INeutronVpnManager neutronVpnManager;

    public void setNeutronVpnManager(INeutronVpnManager neutronVpnManager) {
        this.neutronVpnManager = neutronVpnManager;
    }

    @Override
    protected Object doExecute() throws Exception {

        Uuid vuuid = null;
        if (vid != null) {
            vuuid = new Uuid(vid);
        }

        for (String p : neutronVpnManager.showVpnConfigCLI(vuuid)) {
            session.getConsole().println(p);
        }
        return null;
    }
}
