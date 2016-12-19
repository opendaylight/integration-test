/*
 * Copyright (c) 2016 Red Hat, Inc. and others. All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.statemanager;

import com.google.common.base.Stopwatch;
import java.lang.management.ManagementFactory;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.TimeUnit;
import javax.management.InstanceNotFoundException;
import javax.management.ObjectName;
import org.apache.commons.lang3.tuple.Pair;
import org.opendaylight.controller.config.api.ConfigRegistry;
import org.opendaylight.controller.config.util.ConfigRegistryJMXClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Helper class to find service started by Config Sub System
 *
 * <p>This class will be deprecated when all of netvirt is using blueprint.
 */
public class ConfigStateManager {
    private static final Logger LOG = LoggerFactory.getLogger(ConfigStateManager.class);
    private Map<String, Pair<String, Boolean>> readyMap = new HashMap<>();
    private static final int MODULE_TIMEOUT_SECONDS = 600;
    private static final int RETRY_TIMEOUT_SECONDS = 5;
    private IStateManager stateManager;

    ConfigStateManager(IStateManager stateManager) {
        this.stateManager = stateManager;
    }

    private void initReady() {
    }

    private void getServices() {
        ConfigRegistry configRegistryClient = new ConfigRegistryJMXClient(ManagementFactory.getPlatformMBeanServer());

        for (Map.Entry<String, Pair<String, Boolean>> ready : readyMap.entrySet()) {
            if (ready.getValue().getRight()) {
                continue;
            }

            String moduleName = ready.getKey();
            String instanceName = ready.getValue().getLeft();

            LOG.trace("ConfigStateManager attempting to configure: {}, {}", moduleName, instanceName);

            ObjectName objectName = null;
            try {
                objectName = configRegistryClient.lookupConfigBean(moduleName, instanceName);
                readyMap.put(moduleName, Pair.of(instanceName, true));
                LOG.info("ConfigStateManager found: {}, {}, {}", moduleName, instanceName, objectName);
            } catch (InstanceNotFoundException e) {
                continue;
            }
        }
    }

    private boolean allFound() {
        int count = 0;
        for (Map.Entry<String, Pair<String, Boolean>> ready : readyMap.entrySet()) {
            if (ready.getValue().getRight()) {
                count++;
            }
        }
        return (count == readyMap.size());
    }

    private class WaitForServices implements Runnable {
        public void run() {
            initReady();
            LOG.info("ConfigStateManager looking for services({}): {}", readyMap.size(), readyMap);
            Stopwatch stopWatch = Stopwatch.createStarted();
            for (int i = 0; i < MODULE_TIMEOUT_SECONDS / RETRY_TIMEOUT_SECONDS; i++) {
                getServices();
                if (allFound()) {
                    LOG.info("ConfigStateManager found all services after {}ms",
                            stopWatch.elapsed(TimeUnit.MILLISECONDS));
                    stateManager.setReady(true);
                    return;
                } else {
                    try {
                        Thread.sleep(RETRY_TIMEOUT_SECONDS * 1000);
                    } catch (InterruptedException e) {
                        LOG.warn("ConfigStateManager thread was interrupted", e);
                    }
                }
            }
            LOG.warn("ConfigStateManager failed to find all services({}): {}", readyMap.size(), readyMap);
            throw new RuntimeException("ConfigStateManager did not find all services after "
                    + stopWatch.elapsed(TimeUnit.MILLISECONDS) + "ms");
        }
    }

    public void start() {
        new Thread(new WaitForServices()).start();
    }
}
