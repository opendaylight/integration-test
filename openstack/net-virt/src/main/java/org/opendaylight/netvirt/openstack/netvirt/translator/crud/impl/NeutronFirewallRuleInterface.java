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
import org.opendaylight.netvirt.openstack.netvirt.translator.NeutronFirewallRule;
import org.opendaylight.netvirt.openstack.netvirt.translator.crud.INeutronFirewallRuleCRUD;
import org.opendaylight.yangtools.yang.binding.DataObject;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.osgi.framework.BundleContext;
import org.osgi.framework.ServiceRegistration;

public class NeutronFirewallRuleInterface extends AbstractNeutronInterface implements INeutronFirewallRuleCRUD {

    NeutronFirewallRuleInterface(DataBroker dataBroker) {
        super(dataBroker);
    }

    @Override
    public boolean neutronFirewallRuleExists(String uuid) {
        // TODO Auto-generated method stub
        return false;
    }

    @Override
    public NeutronFirewallRule getNeutronFirewallRule(String uuid) {
        // TODO Auto-generated method stub
        return null;
    }

    @Override
    public List<NeutronFirewallRule> getAllNeutronFirewallRules() {
        // TODO Auto-generated method stub
        return null;
    }

    @Override
    public boolean addNeutronFirewallRule(NeutronFirewallRule input) {
        // TODO Auto-generated method stub
        return false;
    }

    @Override
    public boolean removeNeutronFirewallRule(String uuid) {
        // TODO Auto-generated method stub
        return false;
    }

    @Override
    public boolean updateNeutronFirewallRule(String uuid,
            NeutronFirewallRule delta) {
        // TODO Auto-generated method stub
        return false;
    }

    @Override
    public boolean neutronFirewallRuleInUse(String uuid) {
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
        NeutronFirewallRuleInterface neutronFirewallRuleInterface = new NeutronFirewallRuleInterface(dataBroker);
        ServiceRegistration<INeutronFirewallRuleCRUD> neutronFirewallRuleInterfaceRegistration = context.registerService(INeutronFirewallRuleCRUD.class, neutronFirewallRuleInterface, null);
        if(neutronFirewallRuleInterfaceRegistration != null) {
            registrations.add(neutronFirewallRuleInterfaceRegistration);
        }
    }
}
