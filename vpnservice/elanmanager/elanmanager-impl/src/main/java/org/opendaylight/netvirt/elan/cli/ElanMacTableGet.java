/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.elan.cli;

import java.text.SimpleDateFormat;
import java.util.Collection;
import java.util.Date;
import org.apache.karaf.shell.commands.Argument;
import org.apache.karaf.shell.commands.Command;
import org.apache.karaf.shell.console.OsgiCommandSupport;
import org.opendaylight.netvirt.elan.utils.ElanCLIUtils;
import org.opendaylight.netvirt.elanmanager.api.IElanService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.forwarding.entries.MacEntry;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Command(scope = "elanmactable", name = "show", description = "get Elan Mac table")
public class ElanMacTableGet extends OsgiCommandSupport {

    private static final Logger LOG = LoggerFactory.getLogger(ElanMacTableGet.class);

    @Argument(index = 0, name = "elanName", description = "ELAN-NAME", required = true, multiValued = false)
    private String elanName;
    private IElanService elanProvider;

    public void setElanProvider(IElanService elanServiceProvider) {
        this.elanProvider = elanServiceProvider;
    }

    @Override
    protected Object doExecute() throws Exception {
        LOG.debug("Executing updating ElanInterface command" + "\t");
        Collection<MacEntry> macTables = elanProvider.getElanMacTable(elanName);
        if (!macTables.isEmpty()) {
            SimpleDateFormat formatter = new SimpleDateFormat("dd-MM-yy:HH:mm:ss");
            session.getConsole().println(getMacTableHeaderOutput());
            session.getConsole().println(elanName);
            for (MacEntry mac : macTables) {
                boolean isStatic = mac.isIsStaticAddress();
                session.getConsole().println(String.format(ElanCLIUtils.MAC_TABLE_CLI_FORMAT, "", mac.getInterface(),
                        mac.getMacAddress().getValue(), ""));
                session.getConsole().println(String.format(ElanCLIUtils.MAC_TABLE_CLI_FORMAT, "", isStatic, "", isStatic
                        ? "-"
                        : formatter.format(new Date(mac.getControllerLearnedForwardingEntryTimestamp().longValue()))));
            }
        }
        return null;
    }

    private Object getMacTableHeaderOutput() {
        StringBuilder headerBuilder = new StringBuilder();
        headerBuilder.append(
                String.format(ElanCLIUtils.MAC_TABLE_CLI_FORMAT, "Elan Instance", "Interface Name", "MacAddress", ""));
        headerBuilder.append('\n');
        headerBuilder.append(String.format(ElanCLIUtils.MAC_TABLE_CLI_FORMAT, "", "Is Static?", "" , "TimeStamp"));
        headerBuilder.append('\n');
        headerBuilder.append(ElanCLIUtils.HEADER_UNDERLINE);
        return headerBuilder.toString();
    }
}

