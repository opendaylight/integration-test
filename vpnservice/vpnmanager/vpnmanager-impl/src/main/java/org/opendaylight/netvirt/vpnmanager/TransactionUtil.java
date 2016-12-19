/*
 * Copyright (c) 2015 - 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.vpnmanager;

import com.google.common.base.Optional;
import com.google.common.util.concurrent.CheckedFuture;
import com.google.common.util.concurrent.FutureCallback;
import com.google.common.util.concurrent.Futures;
import java.util.concurrent.ExecutionException;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.ReadOnlyTransaction;
import org.opendaylight.controller.md.sal.binding.api.WriteTransaction;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.controller.md.sal.common.api.data.TransactionCommitFailedException;
import org.opendaylight.yangtools.yang.binding.DataObject;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class TransactionUtil {
    private static final Logger LOG = LoggerFactory.getLogger(TransactionUtil.class);

    private TransactionUtil() {
    }

    public static final FutureCallback<Void> DEFAULT_CALLBACK = new FutureCallback<Void>() {
        public void onSuccess(Void result) {
            LOG.debug("Success in Datastore operation");
        }

        public void onFailure(Throwable error) {
            LOG.error("Error in Datastore operation", error);
        };
    };

    public static <T extends DataObject> Optional<T> read(DataBroker dataBroker, LogicalDatastoreType datastoreType,
                                                    InstanceIdentifier<T> path) {

        ReadOnlyTransaction tx = dataBroker.newReadOnlyTransaction();

        Optional<T> result;
        try {
            result = tx.read(datastoreType, path).get();
        } catch (Exception e) {
            throw new RuntimeException(e);
        }

        return result;
    }

    public static <T extends DataObject> void asyncWrite(DataBroker dataBroker, LogicalDatastoreType datastoreType,
                                                   InstanceIdentifier<T> path, T data,
                                                   FutureCallback<Void> callback) {
        WriteTransaction tx = dataBroker.newWriteOnlyTransaction();
        tx.put(datastoreType, path, data, true);
        Futures.addCallback(tx.submit(), callback);
    }

    public static <T extends DataObject> void syncWrite(DataBroker dataBroker, LogicalDatastoreType datastoreType,
                                                  InstanceIdentifier<T> path,
                                                  T data, FutureCallback<Void> callback) {
        WriteTransaction tx = dataBroker.newWriteOnlyTransaction();
        tx.put(datastoreType, path, data, true);
        CheckedFuture<Void, TransactionCommitFailedException> futures = tx.submit();
        try {
            futures.get();
        } catch (InterruptedException | ExecutionException e) {
            LOG.error("Error writing VPN instance to ID info to datastore (path, data) : ({}, {})", path, data);
            throw new RuntimeException(e.getMessage());
        }
    }
}
