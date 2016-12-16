/*
 * Copyright (c) 2016 NEC Corporation and others. All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.openstack.netvirt.api;

/**
 *  This interface to resubmit the flows to ACL learn and Egress service.
 */
public interface ResubmitAclLearnProvider {
    Status programResubmit(Long dpid);
}
