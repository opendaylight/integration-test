/*
 * Copyright (c) 2016 Red Hat, Inc. and others. All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.aclservice.tests.infra;

import org.eclipse.xtext.xbase.lib.Pair;
import org.opendaylight.controller.md.sal.binding.api.DataTreeIdentifier;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.yangtools.concepts.Builder;
import org.opendaylight.yangtools.yang.binding.DataObject;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;

/**
 * Builder of an {@link DataTreeIdentifier} -&gt; {@link DataObject} Pair.
 *
 * @param <T> DataObject type
 *
 * @author Michael Vorburger
 */
public interface DataTreeIdentifierDataObjectPairBuilder<T extends DataObject>
        extends Builder<Pair<DataTreeIdentifier<T>, T>> {

    // TODO use, when merged, pending https://git.opendaylight.org/gerrit/#/c/46479/

    LogicalDatastoreType type();

    InstanceIdentifier<T> identifier();

    T dataObject();

    @Override
    default Pair<DataTreeIdentifier<T>, T> build() {
        return Pair.of(new DataTreeIdentifier<>(type(), identifier()), dataObject());
    }
}
