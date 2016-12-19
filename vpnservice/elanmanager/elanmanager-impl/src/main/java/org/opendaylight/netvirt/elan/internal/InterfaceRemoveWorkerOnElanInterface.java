/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.elan.internal;

import com.google.common.util.concurrent.ListenableFuture;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.Callable;
import org.opendaylight.genius.interfacemanager.globals.InterfaceInfo;
import org.opendaylight.netvirt.elan.ElanException;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.instances.ElanInstance;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class InterfaceRemoveWorkerOnElanInterface implements Callable<List<ListenableFuture<Void>>> {

    private static final Logger LOG = LoggerFactory.getLogger(InterfaceRemoveWorkerOnElanInterface.class);

    private String interfaceName;
    private ElanInstance elanInfo;
    private InterfaceInfo interfaceInfo;
    private boolean isInterfaceStateRemoved;
    private ElanInterfaceManager dataChangeListener;
    private boolean isLastElanInterface;

    public InterfaceRemoveWorkerOnElanInterface(String interfaceName, ElanInstance elanInfo,
            InterfaceInfo interfaceInfo, boolean isInterfaceStateRemoved, ElanInterfaceManager dataChangeListener,
            boolean isLastElanInterface) {
        this.interfaceName = interfaceName;
        this.elanInfo = elanInfo;
        this.interfaceInfo = interfaceInfo;
        this.isInterfaceStateRemoved = isInterfaceStateRemoved;
        this.dataChangeListener = dataChangeListener;
        this.isLastElanInterface = isLastElanInterface;
    }

    @Override
    public String toString() {
        return "InterfaceRemoveWorkerOnElanInterface [key=" + interfaceName + ", elanInfo=" + elanInfo
                + ", interfaceInfo=" + interfaceInfo + ", isInterfaceStateRemoved=" + isInterfaceStateRemoved
                + ", isLastElanInterface=" + isLastElanInterface + "]";
    }

    @Override
    @SuppressWarnings("checkstyle:IllegalCatch")
    public List<ListenableFuture<Void>> call() throws Exception {
        List<ListenableFuture<Void>> futures = new ArrayList<>();
        try {
            dataChangeListener.removeEntriesForElanInterface(futures, elanInfo, interfaceInfo, interfaceName,
                    isInterfaceStateRemoved, isLastElanInterface);
        } catch (RuntimeException e) {
            throw new ElanException("Error while processing " + interfaceName + " for " + elanInfo, e);
        }
        return futures;
    }

}
