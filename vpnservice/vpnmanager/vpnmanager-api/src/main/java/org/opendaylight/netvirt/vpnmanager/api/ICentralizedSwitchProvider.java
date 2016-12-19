/*
 * Copyright (c) 2016 Hewlett Packard Enterprise, Co. and others. All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.vpnmanager.api;

import java.math.BigInteger;

/**
 * ICentralizedSwitchProvider allows to create or interrogate centralized
 * switch:router mappings.<br>
 * The centralized switch is currently implemented using NAPT switch models
 * residing in natservice bundle. As the roles of centralized switch will grow
 * beyond NAT use cases, the associated models and logic need to be renamed
 * and moved to either vpnmanager or new bundle as part of Carbon model changes
 *
 */
public interface ICentralizedSwitchProvider {

    /**
     * Get the primary switch selected for the router if it has previously been
     * allocated.
     *
     * @param routerName
     * @return primary switch id
     */
    BigInteger getPrimarySwitchForRouter(String routerName);

}
