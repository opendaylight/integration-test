/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.neutronvpn.shell;

import org.apache.karaf.shell.commands.Command;
import org.apache.karaf.shell.console.OsgiCommandSupport;
import org.opendaylight.netvirt.neutronvpn.interfaces.INeutronVpnManager;

@Command(scope = "vpnservice", name = "neutron-ports-show", description = "Displays neutron ports")
public class ShowNeutronPortsCommand extends OsgiCommandSupport {
    private INeutronVpnManager neutronVpnManager;

    public void setNeutronVpnManager(INeutronVpnManager neutronVpnManager) {
        this.neutronVpnManager = neutronVpnManager;
    }

    @Override
    protected Object doExecute() throws Exception {
        for (String p : neutronVpnManager.showNeutronPortsCLI()) {
            session.getConsole().println(p);
        }
        return null;
    }
}
