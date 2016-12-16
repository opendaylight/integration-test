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
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.ReadOnlyTransaction;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.DhcpConfig;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.google.common.base.Optional;

@Command(scope = "vpnservice", name = "dhcp-show", description = "showing parameters for DHCP Service")
public class DhcpShowCommand extends OsgiCommandSupport {

    final Logger Logger = LoggerFactory.getLogger(DhcpShowCommand.class);


    private DataBroker dataBroker;
    Integer leaseDuration = null;
    String defDomain = null;

    public void setDataBroker(DataBroker broker) {
        this.dataBroker = broker;
    }

    @Override
    protected Object doExecute() throws Exception {
        try {
            InstanceIdentifier<DhcpConfig> iid = InstanceIdentifier.create(DhcpConfig.class);
            DhcpConfig dhcpConfig = read(iid);
            if (dhcpConfig == null || dhcpConfig.getConfigs() == null) {
                //TODO: Should we print the defaults?
                session.getConsole().println("Failed to get DHCP Configuration. Try again");
                return null;
            }
            if (!dhcpConfig.getConfigs().isEmpty()) {
                leaseDuration = dhcpConfig.getConfigs().get(0).getLeaseDuration();
                defDomain = dhcpConfig.getConfigs().get(0).getDefaultDomain();
            }
            session.getConsole().println("Lease Duration: " + ((leaseDuration != null) ? leaseDuration:86400));
            session.getConsole().println("Default Domain: " + ((defDomain != null) ? defDomain:"openstacklocal"));
        } catch (Exception e) {
            session.getConsole().println("Failed to fetch configuration parameters. Try again");
            Logger.error("Failed to fetch DHCP parameters",e);
        }
        return null;
    }

    private DhcpConfig read(InstanceIdentifier<DhcpConfig> iid) {

        ReadOnlyTransaction tx = dataBroker.newReadOnlyTransaction();
        Optional<DhcpConfig> result = Optional.absent();
        try {
            result = tx.read(LogicalDatastoreType.CONFIGURATION, iid).get();
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
        if (result.isPresent()) {
            return result.get();
        }
        return null;
    }

}
