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

@Command(scope = "vpnservice", name = "fib-show", description = "Displays fib entries")
public class ShowFibCommand extends OsgiCommandSupport {
    private IFibManager fibManager;

    public void setFibManager(IFibManager fibManager) {
        this.fibManager = fibManager;
    }

    @Override
    protected Object doExecute() throws Exception {
        for (String p : fibManager.printFibEntries()) {
            session.getConsole().println(p);
        }
        return null;
    }
}
