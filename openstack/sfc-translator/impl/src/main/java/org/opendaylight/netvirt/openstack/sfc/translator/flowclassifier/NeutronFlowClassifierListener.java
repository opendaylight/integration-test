/*
 * Copyright (c) 2016 Brocade Communications Systems, Inc. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.openstack.sfc.translator.flowclassifier;

import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.DataTreeIdentifier;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.netvirt.openstack.sfc.translator.DelegatingDataTreeListener;
import org.opendaylight.netvirt.openstack.sfc.translator.SfcMdsalHelper;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.access.control.list.rev160218.access.lists.Acl;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.rev150712.Neutron;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.sfc.flow.classifier.rev160511.sfc.flow.classifiers.attributes.SfcFlowClassifiers;
import org.opendaylight.yang.gen.v1.urn.opendaylight.neutron.sfc.flow.classifier.rev160511.sfc.flow.classifiers.attributes.sfc.flow.classifiers.SfcFlowClassifier;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;

/**
 * OpenDaylight Neutron Flow Classifier yang models data change listener
 */
public class NeutronFlowClassifierListener extends DelegatingDataTreeListener<SfcFlowClassifier> {

    private static final InstanceIdentifier<SfcFlowClassifier> flowClassifiersIid =
            InstanceIdentifier.create(Neutron.class).child(SfcFlowClassifiers.class).child(SfcFlowClassifier.class);

    private final SfcMdsalHelper sfcMdsalHelper;

    public NeutronFlowClassifierListener(DataBroker db) {
        super(db, new DataTreeIdentifier<>(LogicalDatastoreType.CONFIGURATION,flowClassifiersIid));
        sfcMdsalHelper = new SfcMdsalHelper(db);

    }

    /**
     * Method removes Acl respective to SfcFlowClassifier which is identified by InstanceIdentifier.
     *
     * @param path - the whole path to SfcFlowClassifier
     * @param deletedSfcFlowClassifier        - SfcFlowClassifier for removing
     */
    @Override
    public void remove(InstanceIdentifier<SfcFlowClassifier> path, SfcFlowClassifier deletedSfcFlowClassifier) {
        Acl aclFlowClassifier = FlowClassifierTranslator.buildAcl(deletedSfcFlowClassifier);
        sfcMdsalHelper.removeAclFlowClassifier(aclFlowClassifier);
    }

    /**
     * Method updates the original SfcFlowClassifier to the update SfcFlowClassifier.
     * Both are identified by same InstanceIdentifier.
     *
     * @param path - the whole path to SfcFlowClassifier
     * @param originalSfcFlowClassifier   - original SfcFlowClassifier (for update)
     * @param updatedSfcFlowClassifier     - changed SfcFlowClassifier (contain updates)
     */
    @Override
    public void update(InstanceIdentifier<SfcFlowClassifier> path,
                       SfcFlowClassifier originalSfcFlowClassifier,
                       SfcFlowClassifier updatedSfcFlowClassifier) {

        Acl aclFlowClassifier = FlowClassifierTranslator.buildAcl(updatedSfcFlowClassifier);
        sfcMdsalHelper.updateAclFlowClassifier(aclFlowClassifier);
    }

    /**
     * Method adds the SfcFlowClassifier which is identified by InstanceIdentifier
     * to device.
     *
     * @param path - the whole path to new SfcFlowClassifier
     * @param sfcFlowClassifier        - new SfcFlowClassifier
     */
    @Override
    public void add(InstanceIdentifier<SfcFlowClassifier> path, SfcFlowClassifier sfcFlowClassifier) {
        // Respective ACL classifier will be written in data store, once the chain is created.
    }

}
