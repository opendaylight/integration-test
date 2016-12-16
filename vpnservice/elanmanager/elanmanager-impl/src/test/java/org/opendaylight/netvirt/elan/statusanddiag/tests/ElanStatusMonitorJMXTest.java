/*
 * Copyright (c) 2016 Red Hat, Inc. and others. All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.elan.statusanddiag.tests;

import org.junit.Test;
import org.opendaylight.netvirt.elan.statusanddiag.ElanStatusMonitorJMX;

/**
 * Test to make sure that ElanStatusMonitorJMX is a valid JMX MBean.
 *
 * @author Michael Vorburger
 */
public class ElanStatusMonitorJMXTest {

    @Test
    public void testRegisterMbean() throws Exception {
        ElanStatusMonitorJMX jmxMBean = new ElanStatusMonitorJMX();
        jmxMBean.init();
    }

}
