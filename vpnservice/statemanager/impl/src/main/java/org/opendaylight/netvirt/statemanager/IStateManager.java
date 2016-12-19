/*
 * Copyright (c) 2016 Red Hat, Inc. and others. All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.statemanager;

public interface IStateManager {
    /**
     * This method is used to indicate if all netvirt services have been started
     * and netvirt is ready.
     *
     * @param ready indicates the netvirt readiness
     */
    void setReady(boolean ready);
}
