/*
 * Copyright (c) 2014, 2015 Red Hat, Inc. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.openstack.netvirt.translator.crud.impl;

import java.util.List;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.netvirt.openstack.netvirt.translator.INeutronObject;
import org.opendaylight.netvirt.openstack.netvirt.translator.NeutronFirewallPolicy;
import org.opendaylight.netvirt.openstack.netvirt.translator.crud.INeutronFirewallPolicyCRUD;
import org.opendaylight.yangtools.yang.binding.DataObject;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.osgi.framework.BundleContext;
import org.osgi.framework.ServiceRegistration;

/**
 */

public class NeutronFirewallPolicyInterface extends AbstractNeutronInterface implements INeutronFirewallPolicyCRUD {

    NeutronFirewallPolicyInterface(final DataBroker dataBroker) {
        super(dataBroker);
    }

    @Override
    public boolean neutronFirewallPolicyExists(String uuid) {
        // TODO Auto-generated method stub
        return false;
    }

    @Override
    public NeutronFirewallPolicy getNeutronFirewallPolicy(String uuid) {
        // TODO Auto-generated method stub
        return null;
    }

    @Override
    public List<NeutronFirewallPolicy> getAllNeutronFirewallPolicies() {
        // TODO Auto-generated method stub
        return null;
    }

    @Override
    public boolean addNeutronFirewallPolicy(NeutronFirewallPolicy input) {
        // TODO Auto-generated method stub
        return false;
    }

    @Override
    public boolean removeNeutronFirewallPolicy(String uuid) {
        // TODO Auto-generated method stub
        return false;
    }

    @Override
    public boolean updateNeutronFirewallPolicy(String uuid,
            NeutronFirewallPolicy delta) {
        // TODO Auto-generated method stub
        return false;
    }

    @Override
    public boolean neutronFirewallPolicyInUse(String uuid) {
        // TODO Auto-generated method stub
        return false;
    }

    @Override
    protected InstanceIdentifier createInstanceIdentifier(DataObject item) {
        // TODO Auto-generated method stub
        return null;
    }

    @Override
    protected DataObject toMd(INeutronObject neutronObject) {
        // TODO Auto-generated method stub
        return null;
    }

    @Override
    protected DataObject toMd(String uuid) {
        // TODO Auto-generated method stub
        return null;
    }

    public static void registerNewInterface(BundleContext context,
                                            final DataBroker dataBroker,
                                            List<ServiceRegistration<?>> registrations) {
        NeutronFirewallPolicyInterface neutronFirewallPolicyInterface = new NeutronFirewallPolicyInterface(dataBroker);
        ServiceRegistration<INeutronFirewallPolicyCRUD> neutronFirewallPolicyInterfaceRegistration = context.registerService(INeutronFirewallPolicyCRUD.class, neutronFirewallPolicyInterface, null);
        if(neutronFirewallPolicyInterfaceRegistration != null) {
            registrations.add(neutronFirewallPolicyInterfaceRegistration);
        }
    }

}
