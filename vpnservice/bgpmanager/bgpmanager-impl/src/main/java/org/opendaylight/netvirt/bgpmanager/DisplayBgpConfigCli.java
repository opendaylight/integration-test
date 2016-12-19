/*
 * Copyright (c) 2015 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.bgpmanager;
import java.io.PrintStream;
import java.util.ArrayList;
import java.util.concurrent.Future;

import com.google.common.base.Optional;
import org.apache.karaf.shell.commands.Command;
import org.apache.karaf.shell.commands.Option;
import org.apache.karaf.shell.console.OsgiCommandSupport;
import org.opendaylight.netvirt.bgpmanager.commands.Cache;
import org.opendaylight.netvirt.bgpmanager.commands.Commands;
import org.opendaylight.genius.utils.clustering.EntityOwnerUtils;

import java.util.Date;

@Command(scope = "odl", name = "display-bgp-config", description="")
public class DisplayBgpConfigCli extends OsgiCommandSupport {

    @Option(name = "--debug", description = "print debug time stamps",
            required = false, multiValued = false)
    Boolean debug = false;

    protected Object doExecute() throws Exception {
        BgpManager bm;
        PrintStream ps = System.out;
        try {
            bm = Commands.getBgpManager();
        } catch (Exception e){
            return null;
        }

        if (debug) {
            ps.printf("\nis ODL Connected to Q-BGP: %s\n", bm.isBgpConnected()?"TRUE":"FALSE");
            //last ODL connection attempted TS
            ps.printf("Last ODL connection attempt TS: %s\n", new Date(bm.getConnectTS()));
            //last successful connected TS
            ps.printf("Last Successful connection TS: %s\n", new Date(bm.getLastConnectedTS()));
            //last ODL started BGP due to configuration trigger TS
            ps.printf("Last ODL started BGP at: %s\n", new Date(bm.getStartTS()));
            //last Quagga attempted to RESTART the connection
            ps.printf("Last Quagga BGP, sent reSync at: %s\n", new Date(bm.getqBGPrestartTS()));

            //stale cleanup start - end TS
            ps.printf("Time taken to create stale fib : %s ms\n", bm.getStaleEndTime() - bm.getStaleStartTime());

            //Config replay start - end TS
            ps.printf("Time taken to create replay configuration : %s ms\n", bm.getCfgReplayEndTime()-bm.getCfgReplayStartTime());

            //Stale cleanup time
            ps.printf("Time taken for Stale FIB cleanup : %s ms\n", bm.getStaleCleanupTime());

            ps.printf("Total stale entries created %d \n", BgpConfigurationManager.getTotalStaledCount());
            ps.printf("Total stale entries cleared %d \n", BgpConfigurationManager.getTotalCleared());

            ArrayList<EntityOwnerUtils.EntityEvent> eventsHistory = EntityOwnerUtils.getEventsHistory();
            try {
                for (EntityOwnerUtils.EntityEvent event : eventsHistory) {
                    ps.printf("%s entity : %s amIOwner:%s hasOwner:%s \n", new Date(event.getTime()).toString(),
                            event.getEntityName(),  event.hasOwner(), event.isOwner());
                }
            } catch (Exception e) {
            }
        }
        Cache cache = new Cache();
        return cache.show();
    }
}
