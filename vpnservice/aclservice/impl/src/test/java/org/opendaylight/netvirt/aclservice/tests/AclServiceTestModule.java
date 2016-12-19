/*
 * Copyright (c) 2016 Red Hat, Inc. and others. All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.aclservice.tests;

import static org.mockito.Mockito.mock;
import static org.opendaylight.yangtools.testutils.mockito.MoreAnswers.realOrException;

import com.google.common.util.concurrent.Futures;
import com.google.inject.AbstractModule;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.Future;
import org.mockito.Mockito;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.WriteTransaction;
import org.opendaylight.controller.md.sal.binding.test.DataBrokerTestModule;
import org.opendaylight.genius.mdsalutil.interfaces.IMdsalApiManager;
import org.opendaylight.genius.mdsalutil.interfaces.testutils.TestIMdsalApiManager;
import org.opendaylight.netvirt.aclservice.tests.infra.SynchronousEachOperationNewWriteTransaction;
import org.opendaylight.netvirt.aclservice.utils.AclClusterUtil;
import org.opendaylight.netvirt.aclservice.utils.AclConstants;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.AllocateIdInput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.AllocateIdOutput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.AllocateIdOutputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.CreateIdPoolInput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.IdManagerService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.ReleaseIdInput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.aclservice.config.rev160806.AclserviceConfig;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.aclservice.config.rev160806.AclserviceConfig.SecurityGroupMode;
import org.opendaylight.yangtools.yang.common.RpcResult;
import org.opendaylight.yangtools.yang.common.RpcResultBuilder;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Test Dependency Injection (DI) Wiring (currently through Guice).
 *
 * @author Michael Vorburger
 */
public class AclServiceTestModule extends AbstractModule {
    private static final Logger LOG = LoggerFactory.getLogger(AclServiceTestModule.class);

    final SecurityGroupMode securityGroupMode;

    AclServiceTestModule(SecurityGroupMode securityGroupMode) {
        super();
        this.securityGroupMode = securityGroupMode;
    }

    @Override
    protected void configure() {
        bind(DataBroker.class).toInstance(DataBrokerTestModule.dataBroker());
        bind(AclserviceConfig.class).toInstance(aclServiceConfig());

        bind(AclClusterUtil.class).toInstance(() -> true);

        TestIMdsalApiManager singleton = TestIMdsalApiManager.newInstance();
        bind(IMdsalApiManager.class).toInstance(singleton);
        bind(TestIMdsalApiManager.class).toInstance(singleton);

        bind(WriteTransaction.class).to(SynchronousEachOperationNewWriteTransaction.class);

        bind(IdManagerService.class).toInstance(Mockito.mock(TestIdManagerService.class, realOrException()));
    }

    private AclserviceConfig aclServiceConfig() {
        AclserviceConfig aclServiceConfig = mock(AclserviceConfig.class);
        Mockito.when(aclServiceConfig.getSecurityGroupMode()).thenReturn(securityGroupMode);
        return aclServiceConfig;
    }

    private abstract static class TestIdManagerService implements IdManagerService {

        private static Map<String, Integer> cacheMap = new HashMap<>();

        static {
            cacheMap.put(AclServiceTestBase.SG_UUID_1, AclServiceTestBase.FLOW_PRIORITY_SG_1);
            cacheMap.put(AclServiceTestBase.SG_UUID_2, AclServiceTestBase.FLOW_PRIORITY_SG_2);
        }

        @Override
        public Future<RpcResult<Void>> createIdPool(CreateIdPoolInput input) {
            return Futures.immediateFuture(RpcResultBuilder.<Void>success().build());
        }

        @Override
        public Future<RpcResult<AllocateIdOutput>> allocateId(AllocateIdInput input) {
            String key = input.getIdKey();
            long flowPriority = cacheMap.get(key) == null ? AclConstants.PROTO_MATCH_PRIORITY : cacheMap.get(key);
            AllocateIdOutputBuilder output = new AllocateIdOutputBuilder();
            output.setIdValue(flowPriority);

            LOG.info("ID allocated for key {}: {}", key, flowPriority);

            RpcResultBuilder<AllocateIdOutput> allocateIdRpcBuilder = RpcResultBuilder.success();
            allocateIdRpcBuilder.withResult(output.build());
            return Futures.immediateFuture(allocateIdRpcBuilder.build());
        }

        @Override
        public Future<RpcResult<Void>> releaseId(ReleaseIdInput input) {
            return Futures.immediateFuture(RpcResultBuilder.<Void>success().build());
        }
    }

}
