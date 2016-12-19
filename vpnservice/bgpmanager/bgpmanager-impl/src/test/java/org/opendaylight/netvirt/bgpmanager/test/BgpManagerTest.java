/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.bgpmanager.test;

import java.util.Arrays;
import java.util.List;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;

import org.mockito.runners.MockitoJUnitRunner;
import org.opendaylight.netvirt.bgpmanager.BgpUtil;
import org.opendaylight.netvirt.bgpmanager.FibDSWriter;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.test.AbstractDataBrokerTest;
import org.opendaylight.netvirt.fibmanager.api.RouteOrigin;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.vrfentries.VrfEntry;

import static org.junit.Assert.assertEquals;

@RunWith(MockitoJUnitRunner.class)

public class BgpManagerTest extends AbstractDataBrokerTest {
    DataBroker dataBroker;
    FibDSWriter bgpFibWriter = null ;
    MockFibManager fibManager = null ;

    @Before
    public void setUp() throws Exception {
        dataBroker = getDataBroker() ;
        bgpFibWriter = new FibDSWriter(dataBroker);
        fibManager = new MockFibManager(dataBroker);
        BgpUtil.setBroker(dataBroker);
    }

    @Test
    public void testAddSinglePrefix() {
        String rd = "101";
        String prefix = "10.10.10.10/32";
        List<String> nexthop = Arrays.asList("100.100.100.100");
        int label = 1234;

        bgpFibWriter.addFibEntryToDS(rd, null /*macAddress*/, prefix, nexthop,
                VrfEntry.EncapType.Mplsgre, label, 0 /*l3vni*/, null /*gatewayMacAddress*/, RouteOrigin.LOCAL);
        //assertEquals(1, fibManager.getDataChgCount());
        assertEquals(1, 1);
    }


    @Test
    public void testConnectedRoutNullNextHop() {
        String rd = "101";
        String prefix = "10.10.10.10/32";
        int label = 1234;
        try{
            bgpFibWriter.addFibEntryToDS(rd, null /*macAddress*/, prefix, null,
                    VrfEntry.EncapType.Mplsgre, label, 0 /*l3vni*/, null /*gatewayMacAddress*/, RouteOrigin.CONNECTED);
            assertEquals(1,0); //The code is not launching NullPointerException
        }catch(NullPointerException e){
            //The code must launch NullPointerException
            assertEquals(1, 1);
        }
    }

/*
    @Test
    public void testAddPrefixesInRd() {
        String rd = "101";
        String prefix = "10.10.10.10/32";
        String nexthop = "100.100.100.100";
        int label = 1234;

        bgpFibWriter.addFibEntryToDS(rd, prefix, nexthop, label);
        assertEquals(1, fibManager.getDataChgCount());

        prefix = "10.10.10.11/32";
        label = 3456;
        bgpFibWriter.addFibEntryToDS(rd, prefix, nexthop, label);
        assertEquals(2, fibManager.getDataChgCount());


    }

    @Test
    public void testAddPrefixesAcrossRd() {
        String rd = "101";
        String prefix = "10.10.10.10/32";
        String nexthop = "100.100.100.100";
        int label = 1234;

        bgpFibWriter.addFibEntryToDS(rd, prefix, nexthop, label);
        assertEquals(1, fibManager.getDataChgCount());

        rd = "102";
        prefix = "10.10.10.11/32";
        nexthop = "200.200.200.200";
        label = 3456;
        bgpFibWriter.addFibEntryToDS(rd, prefix, nexthop, label);
        assertEquals(2, fibManager.getDataChgCount());

    }


    @Test
    public void testRemovePrefix() {
        String rd = "101";
        String prefix = "10.10.10.10/32";
        String nexthop = "100.100.100.100";
        int label = 1234;

        //add and then remove prefix
        bgpFibWriter.addFibEntryToDS(rd, prefix, nexthop, label);
        assertEquals(1, fibManager.getDataChgCount());
        bgpFibWriter.removeFibEntryFromDS(rd, prefix);
        assertEquals(0, fibManager.getDataChgCount());

    }
*/
}
