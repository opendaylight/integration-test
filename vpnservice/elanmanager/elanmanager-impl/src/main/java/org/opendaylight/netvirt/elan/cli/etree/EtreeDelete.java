/*
 * Copyright (c) 2016 Hewlett Packard Enterprise, Co. and others. All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.elan.cli.etree;

import org.apache.karaf.shell.commands.Argument;
import org.apache.karaf.shell.commands.Command;
import org.apache.karaf.shell.console.OsgiCommandSupport;
import org.opendaylight.netvirt.elanmanager.api.IElanService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Command(scope = "etree", name = "delete", description = "Deleting the Etree Instance")
public class EtreeDelete extends OsgiCommandSupport {

    @Argument(index = 0, name = "etreeName", description = "ETREE-NAME", required = true, multiValued = false)
    private String etreeName;

    private static final Logger LOG = LoggerFactory.getLogger(EtreeDelete.class);
    private IElanService elanProvider;

    public void setElanProvider(IElanService elanServiceProvider) {
        this.elanProvider = elanServiceProvider;
    }

    @Override
    protected Object doExecute() throws Exception {
        LOG.debug("Executing the Deletion of EtreeInstance command" + "\t" + etreeName + "\t");
        boolean isSuccess = elanProvider.deleteEtreeInstance(etreeName);
        if (isSuccess) {
            session.getConsole().println("Etree Instance deleted successfully");
        } else {
            session.getConsole().println("Etree Instance failed to delete");
        }
        return null;
    }
}
