/*
 * Copyright (c) 2015 - 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.fibmanager.shell;

import org.apache.karaf.shell.commands.Command;
import org.apache.karaf.shell.console.OsgiCommandSupport;
import org.opendaylight.netvirt.fibmanager.api.IFibManager;

@Command(scope = "vpnservice", name = "showTransportType", description = "Displays transport type in use for services")
public class ShowTransportTypeCommand extends OsgiCommandSupport {
    private IFibManager fibManager;

    public void setFibManager(IFibManager fibManager) {
        this.fibManager = fibManager;
    }

    @Override
    protected Object doExecute() throws Exception {
        String displayFormat = "%-16s %-16s";
        String cacheVal = fibManager.getReqTransType();
        session.getConsole().println(String.format(displayFormat, "Service Name", "Transport Type"));
        session.getConsole().println("----------------------------------------------");
        session.getConsole().println(String.format(displayFormat, "ELAN" , "VXLAN"));
        session.getConsole().println(String.format(displayFormat, "L3VPN", cacheVal));

        session.getConsole().println("----------------------------------------------------------------------------------------------------------------------");

        return null;
    }
}