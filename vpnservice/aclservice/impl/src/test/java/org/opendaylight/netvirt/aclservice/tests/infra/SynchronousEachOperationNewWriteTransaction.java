/*
 * Copyright (c) 2016 Red Hat, Inc. and others. All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.aclservice.tests.infra;

import com.google.common.base.Preconditions;
import com.google.common.util.concurrent.CheckedFuture;
import com.google.common.util.concurrent.ListenableFuture;
import javax.inject.Inject;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.WriteTransaction;
import org.opendaylight.controller.md.sal.common.api.TransactionStatus;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.controller.md.sal.common.api.data.TransactionCommitFailedException;
import org.opendaylight.yangtools.yang.binding.DataObject;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.opendaylight.yangtools.yang.common.RpcResult;

/**
 * WriteTransaction which wraps each operation into a new synchronously committed transaction.
 *
 * <p>This is mainly intended for writing simple readable tests. In production
 * code, you typically will not want to create a new transaction for each of
 * your operations, but instead create one once, and re-use it for a number of
 * operations.
 *
 * @author Michael Vorburger
 */
@SuppressWarnings("deprecation")
public class SynchronousEachOperationNewWriteTransaction implements WriteTransaction {
    // TODO when https://git.opendaylight.org/gerrit/#/c/46335/ is merged, then
    // rename class & implements WriteableDataStore instead of WriteTransaction
    // (and change JavaDoc)

    // TODO MOVE elsewhere.. I've already written a kinda similar class
    // elsewhere in the Gerrit for assertBeans with DataBroker.. de-dupe this!

    // TODO @deprecate org.opendaylight.genius.mdsalutil.MDSALUtil.syncWrite() with this

    private final DataBroker broker;

    @Inject
    public SynchronousEachOperationNewWriteTransaction(DataBroker broker) {
        super();
        this.broker = Preconditions.checkNotNull(broker);
    }

    @Override
    public boolean cancel() {
        throw new UnsupportedOperationException();
    }

    @Override
    public ListenableFuture<RpcResult<TransactionStatus>> commit() {
        throw new UnsupportedOperationException();
    }

    @Override
    public Object getIdentifier() {
        throw new UnsupportedOperationException();
    }

    @Override
    public CheckedFuture<Void, TransactionCommitFailedException> submit() {
        throw new UnsupportedOperationException();
    }

    protected void submit(WriteTransaction tx) throws OperationFailedRuntimeException {
        try {
            tx.submit().checkedGet();
        } catch (TransactionCommitFailedException e) {
            throw new OperationFailedRuntimeException(e);
        }
    }

    @Override
    public <T extends DataObject> void put(LogicalDatastoreType store, InstanceIdentifier<T> path, T data)
            throws OperationFailedRuntimeException {
        WriteTransaction tx = broker.newWriteOnlyTransaction();
        tx.put(store, path, data);
        submit(tx);
    }

    @Override
    public <T extends DataObject> void put(LogicalDatastoreType store, InstanceIdentifier<T> path, T data,
            boolean createMissingParents) throws OperationFailedRuntimeException {
        WriteTransaction tx = broker.newWriteOnlyTransaction();
        tx.put(store, path, data, createMissingParents);
        submit(tx);
    }

    @Override
    public <T extends DataObject> void merge(LogicalDatastoreType store, InstanceIdentifier<T> path, T data)
            throws OperationFailedRuntimeException {
        WriteTransaction tx = broker.newWriteOnlyTransaction();
        tx.merge(store, path, data);
        submit(tx);
    }

    @Override
    public <T extends DataObject> void merge(LogicalDatastoreType store, InstanceIdentifier<T> path, T data,
            boolean createMissingParents) throws OperationFailedRuntimeException {
        WriteTransaction tx = broker.newWriteOnlyTransaction();
        tx.merge(store, path, data, createMissingParents);
        submit(tx);
    }

    @Override
    public void delete(LogicalDatastoreType store, InstanceIdentifier<?> path) throws OperationFailedRuntimeException {
        WriteTransaction tx = broker.newWriteOnlyTransaction();
        tx.delete(store, path);
        submit(tx);
    }

}
