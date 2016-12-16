/*
 * Copyright (c) 2016 Red Hat, Inc. and others. All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.aclservice;

import javax.inject.Inject;
import javax.inject.Singleton;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.genius.mdsalutil.interfaces.IMdsalApiManager;
import org.opendaylight.infrautils.inject.AbstractLifecycle;
import org.opendaylight.netvirt.aclservice.utils.AclDataUtil;
import org.opendaylight.netvirt.aclservice.utils.AclServiceUtils;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.aclservice.config.rev160806.AclserviceConfig;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.aclservice.config.rev160806.AclserviceConfig.SecurityGroupMode;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Singleton
public class AclServiceImplFactory extends AbstractLifecycle {

    private static final Logger LOG = LoggerFactory.getLogger(AclServiceImplFactory.class);
    //private static final String SECURITY_GROUP_MODE = "security-group-mode";

    private final DataBroker dataBroker;
    private final IMdsalApiManager mdsalManager;
    private SecurityGroupMode securityGroupMode;
    private final AclDataUtil aclDataUtil;
    private final AclServiceUtils aclServiceUtils;

    @Inject
    public AclServiceImplFactory(DataBroker dataBroker, IMdsalApiManager mdsalManager, AclserviceConfig config,
            AclDataUtil aclDataUtil, AclServiceUtils aclServiceUtils) {
        this.dataBroker = dataBroker;
        this.mdsalManager = mdsalManager;
        this.aclDataUtil = aclDataUtil;
        this.aclServiceUtils = aclServiceUtils;
        if (config != null) {
            this.securityGroupMode = config.getSecurityGroupMode();
        }
        LOG.info("AclserviceConfig: {}", config);
    }

    protected InstanceIdentifier<AclserviceConfig> getWildCardPath() {
        return InstanceIdentifier
                .create(AclserviceConfig.class);
    }

    @Override
    protected void start() {
        LOG.info("{} start", getClass().getSimpleName());
    }

    @Override
    protected void stop() {
        LOG.info("{} close", getClass().getSimpleName());
    }

    public AbstractIngressAclServiceImpl createIngressAclServiceImpl() {
        LOG.info("creating ingress acl service using mode {}", securityGroupMode);
        if (securityGroupMode == null || securityGroupMode == SecurityGroupMode.Stateful) {
            return new StatefulIngressAclServiceImpl(dataBroker, mdsalManager, aclDataUtil, aclServiceUtils);
        } else if (securityGroupMode == SecurityGroupMode.Stateless) {
            return new StatelessIngressAclServiceImpl(dataBroker, mdsalManager, aclDataUtil, aclServiceUtils);
        } else if (securityGroupMode == SecurityGroupMode.Transparent) {
            return new TransparentIngressAclServiceImpl(dataBroker, mdsalManager, aclDataUtil, aclServiceUtils);
        } else {
            return new LearnIngressAclServiceImpl(dataBroker, mdsalManager, aclDataUtil, aclServiceUtils);
        }
    }

    public AbstractEgressAclServiceImpl createEgressAclServiceImpl() {
        LOG.info("creating egress acl service using mode {}", securityGroupMode);
        if (securityGroupMode == null || securityGroupMode == SecurityGroupMode.Stateful) {
            return new StatefulEgressAclServiceImpl(dataBroker, mdsalManager, aclDataUtil, aclServiceUtils);
        } else if (securityGroupMode == SecurityGroupMode.Stateless) {
            return new StatelessEgressAclServiceImpl(dataBroker, mdsalManager, aclDataUtil, aclServiceUtils);
        } else if (securityGroupMode == SecurityGroupMode.Transparent) {
            return new TransparentEgressAclServiceImpl(dataBroker, mdsalManager, aclDataUtil, aclServiceUtils);
        } else {
            return new LearnEgressAclServiceImpl(dataBroker, mdsalManager, aclDataUtil, aclServiceUtils);
        }
    }

}
