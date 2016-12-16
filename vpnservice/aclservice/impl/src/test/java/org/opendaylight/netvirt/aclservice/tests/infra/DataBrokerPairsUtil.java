/*
 * Copyright (c) 2016 Red Hat, Inc. and others. All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.aclservice.tests.infra;

import javax.inject.Inject;
import org.eclipse.xtext.xbase.lib.Pair;
import org.opendaylight.controller.md.sal.binding.api.DataTreeIdentifier;
import org.opendaylight.controller.md.sal.binding.api.WriteTransaction;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.controller.md.sal.common.api.data.TransactionCommitFailedException;
import org.opendaylight.yangtools.yang.binding.DataObject;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;

/**
 * Utility around {@link WriteTransaction} for working with pairs and tuples of Type/Id/DataObject.
 *
 * <ul><li>{@link Pair}s (TODO or {@link java.util.Map.Entry} ?) of {@link InstanceIdentifier}s and
 * {@link DataObject}s
 * <li>Triples of
 * {@link LogicalDatastoreType}s/InstanceIdentifiers/DataObjects
 * <li>{@link DataTreeIdentifierDataObjectPairBuilder}
 * </ul>
 *
 * @author Michael Vorburger
 */
public class DataBrokerPairsUtil {
    // TODO use, when merged, pending https://git.opendaylight.org/gerrit/#/c/46534/ (and https://git.opendaylight.org/gerrit/#/c/46479/)

    private final WriteTransaction tx;

    @Inject
    public DataBrokerPairsUtil(WriteTransaction tx) {
        super();
        this.tx = tx;
    }

    public <T extends DataObject> void put(LogicalDatastoreType type, Pair<InstanceIdentifier<T>, T> pair)
            throws TransactionCommitFailedException {
        tx.put(type, pair.getKey(), pair.getValue(), true);
    }

    public <T extends DataObject> void put(Pair<DataTreeIdentifier<T>, T> pair)
            throws TransactionCommitFailedException {
        tx.put(pair.getKey().getDatastoreType(), pair.getKey().getRootIdentifier(), pair.getValue(), true);
    }

    public <T extends DataObject> void put(DataTreeIdentifierDataObjectPairBuilder<T> builder)
            throws TransactionCommitFailedException {
        put(builder.build());
    }

}
