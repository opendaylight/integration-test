/*
 * Copyright (c) 2016 Red Hat, Inc. and others. All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.aclservice.tests;

import org.opendaylight.infrautils.inject.guice.testutils.AbstractGuiceJsr250Module;
import org.opendaylight.netvirt.aclservice.AclServiceManagerImpl;
import org.opendaylight.netvirt.aclservice.api.AclServiceManager;
import org.opendaylight.netvirt.aclservice.listeners.AclEventListener;
import org.opendaylight.netvirt.aclservice.listeners.AclInterfaceListener;
import org.opendaylight.netvirt.aclservice.listeners.AclInterfaceStateListener;
import org.opendaylight.netvirt.aclservice.listeners.AclNodeListener;

/**
 * Main (non-Test) Dependency Injection (DI) Wiring (currently through Guice).
 *
 * @author Michael Vorburger
 */
public class AclServiceModule extends AbstractGuiceJsr250Module {

    @Override
    protected void configureBindings() {
        bind(AclServiceManager.class).to(AclServiceManagerImpl.class);
        bind(AclInterfaceStateListener.class);
        bind(AclNodeListener.class);
        bind(AclInterfaceListener.class);
        bind(AclEventListener.class);
    }

}
