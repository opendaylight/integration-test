/*
 * Copyright (c) 2016 Red Hat, Inc. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.ipv6service.utils;

import static org.junit.Assert.assertEquals;

import org.junit.Before;
import org.junit.Test;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.Ipv6Address;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.MacAddress;

/**
 * Unit test fort {@link Ipv6ServiceUtilsTest}.
 */
public class Ipv6ServiceUtilsTest {
    private Ipv6ServiceUtils instance;

    @Before
    public void initTest() {
        instance = Ipv6ServiceUtils.getInstance();
    }

    /**
     *  Test getIpv6LinkLocalAddressFromMac with different MACAddress values.
     */
    @Test
    public void testgetIpv6LinkLocalAddressFromMac() {
        MacAddress mac = new MacAddress("fa:16:3e:4e:18:0c");
        Ipv6Address expectedLinkLocalAddress = new Ipv6Address("fe80:0:0:0:f816:3eff:fe4e:180c");
        assertEquals(expectedLinkLocalAddress, instance.getIpv6LinkLocalAddressFromMac(mac));

        mac = new MacAddress("fa:16:3e:4e:18:c0");
        expectedLinkLocalAddress = new Ipv6Address("fe80:0:0:0:f816:3eff:fe4e:18c0");
        assertEquals(expectedLinkLocalAddress, instance.getIpv6LinkLocalAddressFromMac(mac));

        mac = new MacAddress("0a:16:03:04:08:0c");
        expectedLinkLocalAddress = new Ipv6Address("fe80:0:0:0:816:3ff:fe04:80c");
        assertEquals(expectedLinkLocalAddress, instance.getIpv6LinkLocalAddressFromMac(mac));

        mac = new MacAddress("f4:00:00:0f:00:6b");
        expectedLinkLocalAddress = new Ipv6Address("fe80:0:0:0:f600:ff:fe0f:6b");
        assertEquals(expectedLinkLocalAddress, instance.getIpv6LinkLocalAddressFromMac(mac));

        mac = new MacAddress("50:7B:9D:78:54:F3");
        expectedLinkLocalAddress = new Ipv6Address("fe80:0:0:0:527b:9dff:fe78:54f3");
        assertEquals(expectedLinkLocalAddress, instance.getIpv6LinkLocalAddressFromMac(mac));
    }
}
