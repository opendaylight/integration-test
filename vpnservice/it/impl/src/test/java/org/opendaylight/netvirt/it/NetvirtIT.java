/*
 * Copyright (c) 2016 Red Hat, Inc. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.it;

import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertTrue;
import static org.junit.Assert.fail;
import static org.ops4j.pax.exam.CoreOptions.composite;
import static org.ops4j.pax.exam.CoreOptions.maven;
import static org.ops4j.pax.exam.CoreOptions.vmOption;
import static org.ops4j.pax.exam.CoreOptions.when;
import static org.ops4j.pax.exam.OptionUtils.combine;
import static org.ops4j.pax.exam.karaf.options.KarafDistributionOption.configureConsole;
import static org.ops4j.pax.exam.karaf.options.KarafDistributionOption.editConfigurationFilePut;
import static org.ops4j.pax.exam.karaf.options.KarafDistributionOption.keepRuntimeFolder;
import static org.ops4j.pax.exam.karaf.options.KarafDistributionOption.logLevel;
import static org.ops4j.pax.exam.karaf.options.KarafDistributionOption.replaceConfigurationFile;
import static org.ops4j.pax.exam.karaf.options.LogLevelOption.LogLevel.DEBUG;
import static org.ops4j.pax.exam.karaf.options.LogLevelOption.LogLevel.ERROR;
import static org.ops4j.pax.exam.karaf.options.LogLevelOption.LogLevel.INFO;
import static org.ops4j.pax.exam.karaf.options.LogLevelOption.LogLevel.TRACE;
import static org.ops4j.pax.exam.karaf.options.LogLevelOption.LogLevel.WARN;

import com.google.common.collect.Maps;
import java.io.File;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Properties;
import java.util.concurrent.atomic.AtomicBoolean;
import javax.inject.Inject;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.controller.mdsal.it.base.AbstractMdsalTestBase;
import org.opendaylight.netvirt.it.NetvirtITConstants.DefaultFlow;
import org.opendaylight.ovsdb.utils.mdsal.utils.MdsalUtils;
import org.opendaylight.ovsdb.utils.mdsal.utils.NotifyingDataChangeListener;
import org.opendaylight.ovsdb.utils.ovsdb.it.utils.DockerOvs;
import org.opendaylight.ovsdb.utils.ovsdb.it.utils.ItConstants;
import org.opendaylight.ovsdb.utils.ovsdb.it.utils.NodeInfo;
import org.opendaylight.ovsdb.utils.ovsdb.it.utils.OvsdbItUtils;
import org.opendaylight.ovsdb.utils.southbound.utils.SouthboundUtils;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.itm.op.rev160406.TunnelsState;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.VpnMaps;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.vpnmaps.VpnMap;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.neutronvpn.rev150602.vpnmaps.VpnMapKey;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.rev150105.ovsdb.node.attributes.ConnectionInfo;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.NetworkTopology;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.TopologyId;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.Topology;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.TopologyKey;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.node.TerminationPoint;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.ops4j.pax.exam.Configuration;
import org.ops4j.pax.exam.Option;
import org.ops4j.pax.exam.junit.PaxExam;
import org.ops4j.pax.exam.karaf.options.LogLevelOption;
import org.ops4j.pax.exam.options.MavenUrlReference;
import org.ops4j.pax.exam.spi.reactors.ExamReactorStrategy;
import org.ops4j.pax.exam.spi.reactors.PerClass;
import org.ops4j.pax.exam.util.Filter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Integration tests for Netvirt.
 */
@RunWith(PaxExam.class)
@ExamReactorStrategy(PerClass.class)
public class NetvirtIT extends AbstractMdsalTestBase {
    private static final Logger LOG = LoggerFactory.getLogger(NetvirtIT.class);
    private static final String PHYSNET = "physnet";
    private static OvsdbItUtils itUtils;
    private static MdsalUtils mdsalUtils = null;
    private static SouthboundUtils southboundUtils;
    private static org.opendaylight.netvirt.it.SouthboundUtils nvSouthboundUtils;
    private static FlowITUtil flowITUtil;
    private static AtomicBoolean setup = new AtomicBoolean(false);
    private static final String NETVIRT_TOPOLOGY_ID = "netvirt:1";
    @Inject @Filter(timeout = 60000)
    private static DataBroker dataBroker = null;
    private static String userSpaceEnabled;
    private static final String OVS_ONE_NODE_YML = "ovs-2.5.0-hwvtep.yml";
    private static final String OVS_TWO_NODE_YML = "two_" + OVS_ONE_NODE_YML;
    private static NeutronSecurityGroupUtils neutronSecurityGroupUtils;

    @Override
    public MavenUrlReference getFeatureRepo() {
        return maven()
                .groupId("org.opendaylight.netvirt")
                .artifactId("it-features")
                .classifier("features")
                .type("xml")
                .versionAsInProject();
    }

    @Override
    public String getFeatureName() {
        return "odl-netvirt-openstack-it";
    }

    @Configuration
    @Override
    public Option[] config() {
        Option[] tempOptions = combine(super.config(), DockerOvs.getSysPropOptions());
        return combine(tempOptions, getOtherOptions());
    }

    private Option[] getOtherOptions() {
        return new Option[] {
                configureConsole().startLocalConsole(),
                // Use transparent as the default
                when("transparent".equals(System.getProperty("sgm", "transparent"))).useOptions(
                        replaceConfigurationFile(
                                "etc/opendaylight/datastore/initial/config/netvirt-aclservice-config.xml",
                                new File("src/test/resources/initial/netvirt-aclservice-config-transparent.xml"))),
                when("learn".equals(System.getProperty("sgm"))).useOptions(
                        replaceConfigurationFile(
                                "etc/opendaylight/datastore/initial/config/netvirt-aclservice-config.xml",
                                new File("src/test/resources/initial/netvirt-aclservice-config-learn.xml"))),
                when("stateful".equals(System.getProperty("sgm"))).useOptions(
                        replaceConfigurationFile(
                                "etc/opendaylight/datastore/initial/config/netvirt-aclservice-config.xml",
                                new File("src/test/resources/initial/netvirt-aclservice-config-stateful.xml"))),
                when("stateless".equals(System.getProperty("sgm"))).useOptions(
                        replaceConfigurationFile(
                                "etc/opendaylight/datastore/initial/config/netvirt-aclservice-config.xml",
                                new File("src/test/resources/initial/netvirt-aclservice-config-stateless.xml"))),
                // Add our own logging.cfg so we can log to a single karaf.log file
                replaceConfigurationFile("etc/org.ops4j.pax.logging.cfg",
                        new File("src/test/resources/org.ops4j.pax.logging.cfg")),
                vmOption("-javaagent:../jars/org.jacoco.agent.jar=destfile=../../jacoco-it.exec"),
                vmOption("-Xmx2048m"),
                //vmOption("-XX:MaxPermSize=m"),
                keepRuntimeFolder()
        };
    }

    // This won't get used when we use our own logging.cfg file set in getOtherOptions
    // but we keep it for reference.
    @Override
    public Option getLoggingOption() {
        return composite(
                logLevel(LogLevelOption.LogLevel.INFO),
                editConfigurationFilePut(ORG_OPS4J_PAX_LOGGING_CFG,
                        logConfiguration(NetvirtIT.class),
                        INFO.name()),
                editConfigurationFilePut(ORG_OPS4J_PAX_LOGGING_CFG,
                        "log4j.logger.org.opendaylight.netvirt",
                        TRACE.name()),
                editConfigurationFilePut(ORG_OPS4J_PAX_LOGGING_CFG,
                        "log4j.logger.org.opendaylight.genius",
                        TRACE.name()),
                editConfigurationFilePut(ORG_OPS4J_PAX_LOGGING_CFG,
                        "log4j.logger.org.opendaylight.ovsdb.utils.southbound.utils.SouthboundUtils",
                        TRACE.name()),
                /*editConfigurationFilePut(ORG_OPS4J_PAX_LOGGING_CFG,
                        "log4j.logger.org.opendaylight.openflowplugin.impl",
                        DEBUG.name()),*/
                editConfigurationFilePut(ORG_OPS4J_PAX_LOGGING_CFG,
                        "log4j.logger.org.opendaylight.openflowjava.protocol.impl.util.ListDeserializer",
                        ERROR.name()),
                editConfigurationFilePut(ORG_OPS4J_PAX_LOGGING_CFG,
                        "log4j.logger.org.opendaylight.controller.configpusherfeature.internal.FeatureConfigPusher",
                        ERROR.name()),
                editConfigurationFilePut(ORG_OPS4J_PAX_LOGGING_CFG,
                        "log4j.logger.org.apache.aries.blueprint.container.ServiceRecipe",
                        WARN.name()),
                editConfigurationFilePut(ORG_OPS4J_PAX_LOGGING_CFG,
                        "log4j.logger.org.opendaylight.yangtools.yang.parser.repo.YangTextSchemaContextResolver",
                        WARN.name()),
                editConfigurationFilePut(ORG_OPS4J_PAX_LOGGING_CFG,
                        "log4j.logger.org.opendaylight.netvirt.fibmanager.FibNodeCapableListener",
                        DEBUG.name()),
                super.getLoggingOption());
                // TODO trying to get console logged to karaf.log, but doesn't work.
                // wondering if the test stops and the log isn't flushed?
                //editConfigurationFilePut(ORG_OPS4J_PAX_LOGGING_CFG,
                //        "log4j.rootLogger", "INFO, async, stdout, osgi:*"));
    }

    @Before
    @Override
    @SuppressWarnings("checkstyle:IllegalCatch")
    public void setup() throws Exception {
        if (setup.get()) {
            LOG.info("Skipping setUp, already initialized");
            return;
        }

        try {
            super.setup();
        } catch (Exception e) {
            LOG.warn("Failed to setup test", e);
            fail("Failed to setup test: " + e);
        }

        Thread.sleep(10 * 1000);
        getProperties();

        assertNotNull("dataBroker should not be null", dataBroker);
        itUtils = new OvsdbItUtils(dataBroker);
        mdsalUtils = new MdsalUtils(dataBroker);
        assertNotNull("mdsalUtils should not be null", mdsalUtils);
        southboundUtils = new SouthboundUtils(mdsalUtils);
        nvSouthboundUtils = new org.opendaylight.netvirt.it.SouthboundUtils(mdsalUtils);
        assertTrue("Did not find " + NETVIRT_TOPOLOGY_ID, getNetvirtTopology());
        flowITUtil = new FlowITUtil(dataBroker);
        neutronSecurityGroupUtils = new NeutronSecurityGroupUtils(mdsalUtils);

        setup.set(true);
    }

    private void getProperties() {
        Properties props = System.getProperties();
        String addressStr = props.getProperty(NetvirtITConstants.SERVER_IPADDRESS);
        String portStr = props.getProperty(NetvirtITConstants.SERVER_PORT, NetvirtITConstants.DEFAULT_SERVER_PORT);
        String connectionType = props.getProperty(NetvirtITConstants.CONNECTION_TYPE, "active");
        String controllerStr = props.getProperty(NetvirtITConstants.CONTROLLER_IPADDRESS, "0.0.0.0");
        userSpaceEnabled = props.getProperty(NetvirtITConstants.USERSPACE_ENABLED, "no");
        LOG.info("setUp: Using the following properties: mode= {}, ip:port= {}:{}, controller ip: {}, "
                        + "userspace.enabled: {}",
                connectionType, addressStr, portStr, controllerStr, userSpaceEnabled);
    }

    private Boolean getNetvirtTopology() throws Exception {
        LOG.info("getNetvirtTopology: looking for {}...", NETVIRT_TOPOLOGY_ID);
        Boolean found = false;
        TopologyId topologyId = new TopologyId(NETVIRT_TOPOLOGY_ID);
        InstanceIdentifier<Topology> path =
                InstanceIdentifier.create(NetworkTopology.class).child(Topology.class, new TopologyKey(topologyId));
        final NotifyingDataChangeListener netvirtTopologyListener =
                new NotifyingDataChangeListener(LogicalDatastoreType.OPERATIONAL,
                        NotifyingDataChangeListener.BIT_CREATE, path, null);
        netvirtTopologyListener.registerDataChangeListener(dataBroker);
        netvirtTopologyListener.waitForCreation(60000);
        Topology topology = mdsalUtils.read(LogicalDatastoreType.OPERATIONAL, path);
        if (topology != null) {
            LOG.info("getNetvirtTopology: found {}...", NETVIRT_TOPOLOGY_ID);
            found = true;
        }
        netvirtTopologyListener.close();

        return found;
    }

    @SuppressWarnings("checkstyle:IllegalCatch")
    private void validateDefaultFlows(long datapathId, int timeout) {
        LOG.info("Validating default flows");
        for (DefaultFlow defaultFlow : DefaultFlow.values()) {
            try {
                flowITUtil.verifyFlowByFields(datapathId, defaultFlow.getFlowId(), defaultFlow.getTableId(), timeout);
                //flowITUtil.verifyFlowById(datapathId, defaultFlow.getFlowId(), defaultFlow.getTableId());
            } catch (Exception e) {
                LOG.error("Failed to verify flow id : {}", defaultFlow.getFlowId());
                fail("Failed to verify flow id : " + defaultFlow.getFlowId());
            }
        }
    }

    private void addLocalIp(NodeInfo nodeInfo, String ip) {
        LOG.info("addlocalIp: nodeinfo: {}, local_ip: {}", nodeInfo.ovsdbNode.getNodeId(), ip);
        Map<String, String> otherConfigs = Maps.newHashMap();
        otherConfigs.put("local_ip", ip);
        assertTrue(nvSouthboundUtils.addOpenVSwitchOtherConfig(nodeInfo.ovsdbNode, otherConfigs));
    }

    /**
     * Test for basic southbound events to netvirt.
     * <pre>The test will:
     * - connect to an OVSDB node and verify it is added to operational
     * - then verify that br-int was created on the node and stored in operational
     * - a port is then added to the bridge to verify that it is ignored by netvirt
     * - remove the bridge
     * - remove the node and verify it is not in operational
     * </pre>
     */
    @Test
    @SuppressWarnings("checkstyle:IllegalCatch")
    public void testNetVirt() throws InterruptedException {
        int ovs1 = 1;
        System.getProperties().setProperty(ItConstants.DOCKER_COMPOSE_FILE_NAME, OVS_ONE_NODE_YML);
        try (DockerOvs ovs = new DockerOvs()) {
            Boolean isUserSpace = userSpaceEnabled.equals("yes");
            LOG.info("isUserSpace: {}, usingExternalDocker: {}", isUserSpace, ovs.usingExternalDocker());
            NetOvs netOvs = getNetOvs(ovs, isUserSpace);

            NodeInfo nodeInfo = connectOvs(netOvs, ovs1, ovs);

            disconnectOvs(nodeInfo);
        } catch (Exception e) {
            LOG.error("testNetVirt: Exception thrown by OvsDocker.OvsDocker()", e);
            fail("testNetVirt: Exception thrown by OvsDocker.OvsDocker() : " + e.getMessage());
        }
    }

    private static final String NETWORK1_NAME = "net1";
    private static final String NETWORK1_SEGID = "101";
    private static final String NETWORK1_IPPFX = "10.1.1.";
    private static final String NETWORK1_IPV6_PREFIX = "2001:db8:1111::";

    private static final String NETWORK2_NAME = "net2";
    private static final String NETWORK2_SEGID = "201";
    private static final String NETWORK2_IPPFX = "20.1.1.";
    private static final String NETWORK2_IPV6_PREFIX = "2001:db8:2222::";

    private static final String ROUTER1_NAME = "router1";

    /**
     * Test a basic neutron use case. This test constructs a Neutron network, subnet, and two "vm" ports
     * and validates that the correct flows are installed on OVS. Then it pings from one VM port to the other.
     * @throws InterruptedException if we're interrupted while waiting for some mdsal operation to complete
     */
    @Test
    @SuppressWarnings("checkstyle:IllegalCatch")
    public void testNeutronNet() throws InterruptedException {
        int ovs1 = 1;
        System.getProperties().setProperty(ItConstants.DOCKER_COMPOSE_FILE_NAME, OVS_ONE_NODE_YML);
        try (DockerOvs ovs = new DockerOvs()) {
            Boolean isUserSpace = userSpaceEnabled.equals("yes");
            LOG.info("isUserSpace: {}, usingExternalDocker: {}", isUserSpace, ovs.usingExternalDocker());
            NetOvs netOvs = getNetOvs(ovs, isUserSpace);
            netOvs.createNetwork(NETWORK1_NAME, NETWORK1_SEGID);
            netOvs.createSubnet(NETWORK1_NAME, NetvirtITConstants.IPV4, NETWORK1_IPPFX);

            //Creating default SG
            LOG.info("Installing default SG");
            List<Uuid> sgList = new ArrayList<>();
            sgList.add(neutronSecurityGroupUtils.createDefaultSG());

            NodeInfo nodeInfo = connectOvs(netOvs, ovs1, ovs);
            String port1 = addPort(netOvs, nodeInfo, ovs1, NETWORK1_NAME, sgList);
            String port2 = addPort(netOvs, nodeInfo, ovs1, NETWORK1_NAME, sgList);

            int rc = netOvs.ping(port1, port2);
            netOvs.logState(ovs1, "node 1 after ping");
            if (isUserSpace) {
                LOG.info("Ping status rc: {}, ignored for UserSpace", rc);
            } else {
                assertTrue("Ping failed between VM1 and VM2", rc == 0);
            }

            destroyOvs(netOvs);
            disconnectOvs(nodeInfo);
        } catch (Exception e) {
            LOG.error("testNeutronNet: Exception thrown by OvsDocker.OvsDocker()", e);
            fail("testNeutronNet: Exception thrown by OvsDocker.OvsDocker() : " + e.getMessage());
        }
    }

    /**
     * Test a basic neutron use case. This test constructs a Neutron network, IPv6 subnet, two "vm" ports
     * and validates that pings from one VM port to the other are successful.
     * @throws InterruptedException if we're interrupted while waiting for some mdsal operation to complete
     */
    @Test
    @SuppressWarnings("checkstyle:IllegalCatch")
    public void testNeutronIpv6L2Connectivity() throws InterruptedException {
        int ovs1 = 1;
        System.getProperties().setProperty(ItConstants.DOCKER_COMPOSE_FILE_NAME, OVS_ONE_NODE_YML);
        try (DockerOvs ovs = new DockerOvs()) {
            Boolean isUserSpace = userSpaceEnabled.equals("yes");
            LOG.info("isUserSpace: {}, usingExternalDocker: {}", isUserSpace, ovs.usingExternalDocker());
            NetOvs netOvs = getNetOvs(ovs, isUserSpace);

            netOvs.createNetwork(NETWORK1_NAME, NETWORK1_SEGID);
            netOvs.createSubnet(NETWORK1_NAME, NetvirtITConstants.IPV6, NETWORK1_IPV6_PREFIX);

            LOG.info("Installing default SG");
            List<Uuid> sgList = new ArrayList<>();
            sgList.add(neutronSecurityGroupUtils.createDefaultSG());

            NodeInfo nodeInfo = connectOvs(netOvs, ovs1, ovs);
            String port1 = addPort(netOvs, nodeInfo, ovs1, NETWORK1_NAME, sgList);
            String port2 = addPort(netOvs, nodeInfo, ovs1, NETWORK1_NAME, sgList);

            int rc = netOvs.ping6(port1, port2);
            LOG.info("Ping6 status rc: {}, ignored for isUserSpace: {}", rc, isUserSpace);
            netOvs.logState(ovs1, "node 1 after ping");
            if (isUserSpace) {
                LOG.info("Ping status rc: {}, ignored for UserSpace", rc);
            } else {
                assertTrue("L2Connectivity (Ping6) failed from VM1 to VM2", rc == 0);
            }

            destroyOvs(netOvs);
            disconnectOvs(nodeInfo);
        } catch (Exception e) {
            LOG.error("testNeutronIpv6L2Connectivity: Exception thrown by OvsDocker.OvsDocker()", e);
            fail("testNeutronIpv6L2Connectivity: Exception thrown by OvsDocker.OvsDocker() : " + e.getMessage());
        }
    }

    /**
     * Test for IPv4 East West Routing support in netvirt.
     * <pre>The test will:
     * - connect to an OVSDB node and verify it is added to operational
     * - create two Neutron networks with an IPv4 subnet in each of the network
     * - associate a default security group
     * - spawn (using namespaces) a VM in each of the network
     * - verify that ping fails (as there is no Neutron Router to route the traffic)
     * - create a Neutron router and associate both the subnets to the router
     * - verify that ping is successful after associating the subnets to the router.
     * - remove the bridge
     * - remove the node and verify it is not in operational
     * - Note: Currently security groups are not validated and the test-cases are executed in
     *   transparent security-group mode as the necessary kernel modules are missing in Jenkins.
     * </pre>
     * @throws InterruptedException if we're interrupted while waiting for some mdsal operation to complete
     */
    @Test
    @SuppressWarnings("checkstyle:IllegalCatch")
    public void testNeutronNetL3() throws InterruptedException {
        int ovs1 = 1;
        System.getProperties().setProperty(ItConstants.DOCKER_COMPOSE_FILE_NAME, OVS_ONE_NODE_YML);
        try (DockerOvs ovs = new DockerOvs()) {
            Boolean isUserSpace = userSpaceEnabled.equals("yes");
            LOG.info("isUserSpace: {}, usingExternalDocker: {}", isUserSpace, ovs.usingExternalDocker());
            NetOvs netOvs = getNetOvs(ovs, isUserSpace);

            //create 2 networks
            netOvs.createNetwork(NETWORK1_NAME, NETWORK1_SEGID);
            netOvs.createSubnet(NETWORK1_NAME, NetvirtITConstants.IPV4, NETWORK1_IPPFX);

            netOvs.createNetwork(NETWORK2_NAME, NETWORK2_SEGID);
            netOvs.createSubnet(NETWORK2_NAME, NetvirtITConstants.IPV4, NETWORK2_IPPFX);

            //Creating default SG
            LOG.info("Installing default SG");
            List<Uuid> sgList = new ArrayList<>();
            sgList.add(neutronSecurityGroupUtils.createDefaultSG());

            NodeInfo nodeInfo = connectOvs(netOvs, ovs1, ovs);
            //create 2 "vms" ports
            String port1 = addPort(netOvs, nodeInfo, ovs1, NETWORK1_NAME, sgList);
            String port2 = addPort(netOvs, nodeInfo, ovs1, NETWORK2_NAME, sgList);

            int rc = netOvs.ping(port1, port2);
            netOvs.logState(ovs1, "after ping without router");
            assertTrue("Ping should fail without router", rc != 0);

            //create neutron router and add the networks
            addRouter(netOvs, ROUTER1_NAME);
            netOvs.createRouterInterface(ROUTER1_NAME, NETWORK1_NAME);
            netOvs.createRouterInterface(ROUTER1_NAME, NETWORK2_NAME);

            rc = netOvs.ping(port1, port2);
            netOvs.logState(ovs1, "after ping with router");
            if (isUserSpace) {
                LOG.info("Ping status rc: {}, ignored for UserSpace", rc);
            } else {
                assertTrue("Ping (with router) failed between VM1 and VM2", rc == 0);
            }

            destroyOvs(netOvs);
            disconnectOvs(nodeInfo);
        } catch (Exception e) {
            LOG.error("testNeutronNetL3: Exception thrown by OvsDocker.OvsDocker()", e);
            fail("testNeutronNetL3: Exception thrown by OvsDocker.OvsDocker() : " + e.getMessage());
        }
    }

    /**
     * Test for IPv6 East West Routing support in netvirt.
     * <pre>The test will:
     * - connect to an OVSDB node and verify it is added to operational
     * - create two Neutron networks with an IPv6 subnet in each of the network
     * - associate a default security group
     * - spawn (using namespaces) a VM in each of the network
     * - verify that ping6 fails (as there is no Neutron Router to route the traffic)
     * - create a Neutron router and associate both the subnets to the router
     * - verify that ping is successful after associating the subnets to the router.
     * - remove the bridge
     * - remove the node and verify it is not in operational
     * - Note: Currently security groups are not validated and the test-cases are executed in
     *   transparent security-group mode as the necessary kernel modules are missing in Jenkins.
     * </pre>
     * @throws InterruptedException if we're interrupted while waiting for some mdsal operation to complete
     */
    @Test
    @SuppressWarnings("checkstyle:IllegalCatch")
    public void testNeutronIpv6EastWestConnectivity() throws InterruptedException {
        int ovs1 = 1;
        System.getProperties().setProperty(ItConstants.DOCKER_COMPOSE_FILE_NAME, OVS_ONE_NODE_YML);
        try (DockerOvs ovs = new DockerOvs()) {
            Boolean isUserSpace = userSpaceEnabled.equals("yes");
            LOG.info("isUserSpace: {}, usingExternalDocker: {}", isUserSpace, ovs.usingExternalDocker());
            NetOvs netOvs = getNetOvs(ovs, isUserSpace);

            //create 2 networks
            netOvs.createNetwork(NETWORK1_NAME, NETWORK1_SEGID);
            netOvs.createSubnet(NETWORK1_NAME, NetvirtITConstants.IPV6, NETWORK1_IPV6_PREFIX);

            netOvs.createNetwork(NETWORK2_NAME, NETWORK2_SEGID);
            netOvs.createSubnet(NETWORK2_NAME, NetvirtITConstants.IPV6, NETWORK2_IPV6_PREFIX);

            LOG.info("Installing default Security Group");
            List<Uuid> sgList = new ArrayList<>();
            sgList.add(neutronSecurityGroupUtils.createDefaultSG());

            NodeInfo nodeInfo = connectOvs(netOvs, ovs1, ovs);
            //create 2 "vms" ports
            String port1 = addPort(netOvs, nodeInfo, ovs1, NETWORK1_NAME, sgList);
            String port2 = addPort(netOvs, nodeInfo, ovs1, NETWORK2_NAME, sgList);

            int rc = netOvs.ping6(port1, port2);
            netOvs.logState(ovs1, "after ping6 without router");
            assertTrue("Ping6 should fail without router", rc != 0);

            //create neutron router and add the networks
            addRouter(netOvs, ROUTER1_NAME);
            netOvs.createRouterInterface(ROUTER1_NAME, NETWORK1_NAME);
            netOvs.createRouterInterface(ROUTER1_NAME, NETWORK2_NAME);

            rc = netOvs.ping6(port1, port2);
            netOvs.logState(ovs1, "after ping with router");
            if (isUserSpace) {
                LOG.info("Ping6 status rc: {}, ignored for UserSpace", rc);
            } else {
                assertTrue("Ping6 (with router) failed between VM1 and VM2", rc == 0);
            }

            destroyOvs(netOvs);
            disconnectOvs(nodeInfo);
        } catch (Exception e) {
            LOG.error("testNeutronIpv6EastWestConnectivity: Exception thrown by OvsDocker.OvsDocker()", e);
            fail("testNeutronIpv6EastWestConnectivity: Exception thrown by OvsDocker.OvsDocker() : " + e.getMessage());
        }
    }

    /**
     * Test IPv4 multi-node use-case in netvirt.
     * <pre>The test will:
     * - create two nodes and verify it is added to operational
     * - create a Neutron network with an IPv4 subnet
     * - associate a default security group
     * - spawn (using namespaces) a VM in each of the node
     * - verify that ping is successful between the VMs spread across two nodes
     * - remove the bridge
     * - remove the node and verify it is not in operational
     * - Note: Currently security groups are not validated and the test-cases are executed in
     *   transparent security-group mode as the necessary kernel modules are missing in Jenkins.
     * </pre>
     * @throws InterruptedException if we're interrupted while waiting for some mdsal operation to complete
     */
    @Test
    @SuppressWarnings("checkstyle:IllegalCatch")
    public void testNeutronNetTwoNodes() throws InterruptedException {
        int ovs1 = 1;
        int ovs2 = 2;
        System.getProperties().setProperty(ItConstants.DOCKER_COMPOSE_FILE_NAME, OVS_TWO_NODE_YML);
        try (DockerOvs ovs = new DockerOvs()) {
            Boolean isUserSpace = userSpaceEnabled.equals("yes");
            LOG.info("isUserSpace: {}, usingExternalDocker: {}", isUserSpace, ovs.usingExternalDocker());
            NetOvs netOvs = getNetOvs(ovs, isUserSpace);

            netOvs.createNetwork(NETWORK1_NAME, NETWORK1_SEGID);
            netOvs.createSubnet(NETWORK1_NAME, NetvirtITConstants.IPV4, NETWORK1_IPPFX);

            //Creating default SG
            LOG.info("Installing default SG");
            List<Uuid> sgList = new ArrayList<>();
            sgList.add(neutronSecurityGroupUtils.createDefaultSG());

            NodeInfo nodeInfo = connectOvs(netOvs, ovs1, ovs);
            NodeInfo nodeInfo2 = connectOvs(netOvs, ovs2, ovs);
            String port1 = addPort(netOvs, nodeInfo, ovs1, NETWORK1_NAME, sgList);
            String port2 = addPort(netOvs, nodeInfo2, ovs2, NETWORK1_NAME, sgList);

            int rc = netOvs.ping(port1, port2);
            netOvs.logState(ovs1, "node 1 after ping");
            netOvs.logState(ovs2, "node 2 after ping");
            if (isUserSpace) {
                LOG.info("Ping status rc: {}, ignored for UserSpace", rc);
            } else {
                assertTrue("Ping failed between VM1 and VM2", rc == 0);
            }

            destroyOvs(netOvs);
            disconnectOvs(nodeInfo);
            disconnectOvs(nodeInfo2);
        } catch (Exception e) {
            LOG.error("testNeutronNetTwoNodes: Exception thrown by OvsDocker.OvsDocker()", e);
            fail("testNeutronNetTwoNodes: Exception thrown by OvsDocker.OvsDocker() : " + e.getMessage());
        }
    }

    /**
     * Test VM connectivity on a provider network.
     * <pre>The test will:
     * - create two nodes and verify it is added to operational
     * - create a Flat external neutron network with an IPv4 subnet
     * - spawn (using namespaces) a VM in each of the node
     * - verify that ping is successful between the VMs spread across two nodes
     * - remove the bridge
     * - remove the node and verify it is not in operational
     * </pre>
     * @throws InterruptedException if we're interrupted while waiting for some mdsal operation to complete
     */
    @Test
    @SuppressWarnings("checkstyle:IllegalCatch")
    public void testProviderNetTwoNodes() throws InterruptedException {
        int ovs1 = 1;
        int ovs2 = 2;
        Properties props = System.getProperties();
        props.setProperty(ItConstants.DOCKER_COMPOSE_FILE_NAME, "two_ovs-2.5.1-dual-nic.yml");
        props.setProperty(ItConstants.DOCKER_WAIT_FOR_PING_SECS, "20");

        //Remove the ovsdb.controller.ipaddress to force DockerOvs to create it's own network
        //since that is the only way this docker compose file works (it uses the "odl" network)
        //We reset the env. in the finally clause
        String controllerIpAddress = props.getProperty(ItConstants.CONTROLLER_IPADDRESS);
        props.remove(ItConstants.CONTROLLER_IPADDRESS);
        try (DockerOvs ovs = new DockerOvs()) {
            if (ovs.usingExternalDocker()) {
                LOG.debug("testProviderNetTwoNodes - Not configured to run docker, skipping this test");
                return;
            }
            Boolean isUserSpace = userSpaceEnabled.equals("yes");
            LOG.info("isUserSpace: {}, usingExternalDocker: {}", isUserSpace, ovs.usingExternalDocker());

            NetOvs netOvs = getNetOvs(ovs, isUserSpace);

            NodeInfo nodeInfo = connectOvs(netOvs, ovs1, ovs);
            NodeInfo nodeInfo2 = connectOvs(netOvs, ovs2, ovs);

            netOvs.createFlatNetwork(NETWORK1_NAME, NETWORK1_SEGID, PHYSNET);
            netOvs.createSubnet(NETWORK1_NAME, NetvirtITConstants.IPV4, NETWORK1_IPPFX);

            String port1 = addPort(netOvs, nodeInfo, ovs1, NETWORK1_NAME, null);
            String port2 = addPort(netOvs, nodeInfo2, ovs2, NETWORK1_NAME, null);

            int rc = netOvs.ping(port1, port2);
            netOvs.logState(ovs1, "node 1 after ping");
            netOvs.logState(ovs2, "node 2 after ping");
            if (isUserSpace) {
                LOG.info("Ping status rc: {}, ignored for UserSpace", rc);
            } else {
                assertTrue("Ping failed between VM1 and VM2", rc == 0);
            }

            destroyOvs(netOvs);
            disconnectOvs(nodeInfo);
            disconnectOvs(nodeInfo2);
        } catch (Exception e) {
            LOG.error("testProviderNet: Exception thrown by OvsDocker.OvsDocker()", e);
            fail("testProviderNet: Exception thrown by OvsDocker.OvsDocker() : " + e.getMessage());
        } finally {
            if (controllerIpAddress != null) {
                props.setProperty(ItConstants.CONTROLLER_IPADDRESS, controllerIpAddress);
            }
        }
    }

    /**
     * Test for IPv4 East West Routing support in a multi-node setup.
     * <pre>The test will:
     * - create two nodes and verify it is added to operational
     * - create two Neutron networks with an IPv4 subnet in each of the network
     * - associate a default security group
     * - spawn (using namespaces) a VM in network1 on node1
     * - spawn a second VM in network2 on node2
     * - verify that ping fails (as there is no Neutron Router to route the traffic)
     * - create a Neutron router and associate both the subnets to the router
     * - verify that tunnels are created between the two nodes
     * - verify that ping is successful after associating the subnets to the router.
     * - remove the bridge
     * - remove the node and verify it is not in operational
     * - Note: Currently security groups are not validated and the test-cases are executed in
     *   transparent security-group mode as the necessary kernel modules are missing in Jenkins.
     * </pre>
     * @throws InterruptedException if we're interrupted while waiting for some mdsal operation to complete
     */
    @Test
    @SuppressWarnings("checkstyle:IllegalCatch")
    public void testNeutronNetL3TwoNodes() throws InterruptedException {
        int ovs1 = 1;
        int ovs2 = 2;
        System.getProperties().setProperty(ItConstants.DOCKER_COMPOSE_FILE_NAME, OVS_TWO_NODE_YML);
        try (DockerOvs ovs = new DockerOvs()) {
            Boolean isUserSpace = userSpaceEnabled.equals("yes");
            LOG.info("isUserSpace: {}, usingExternalDocker: {}", isUserSpace, ovs.usingExternalDocker());
            NetOvs netOvs = getNetOvs(ovs, isUserSpace);

            //Creating default SG
            LOG.info("Installing default SG");
            List<Uuid> sgList = new ArrayList<>();
            sgList.add(neutronSecurityGroupUtils.createDefaultSG());

            //create 2 networks
            netOvs.createNetwork(NETWORK1_NAME, NETWORK1_SEGID);
            netOvs.createSubnet(NETWORK1_NAME, NetvirtITConstants.IPV4, NETWORK1_IPPFX);

            netOvs.createNetwork(NETWORK2_NAME, NETWORK2_SEGID);
            netOvs.createSubnet(NETWORK2_NAME, NetvirtITConstants.IPV4, NETWORK2_IPPFX);

            NodeInfo nodeInfo = connectOvs(netOvs, ovs1, ovs);
            NodeInfo nodeInfo2 = connectOvs(netOvs, ovs2, ovs);
            //create 2 "vms" ports
            String port1 = addPort(netOvs, nodeInfo, ovs1, NETWORK1_NAME, sgList);
            String port2 = addPort(netOvs, nodeInfo2, ovs2, NETWORK2_NAME, sgList);

            int rc = netOvs.ping(port1, port2);
            netOvs.logState(ovs1, "node 1 after ping without router");
            netOvs.logState(ovs2, "node 2 after ping without router");
            assertTrue("Ping should fail without router", rc != 0);

            //create neutron router and add the networks
            addRouter(netOvs, ROUTER1_NAME);
            netOvs.createRouterInterface(ROUTER1_NAME, NETWORK1_NAME);
            netOvs.createRouterInterface(ROUTER1_NAME, NETWORK2_NAME);

            waitForTunnels();
            rc = netOvs.ping(port1, port2);
            netOvs.logState(ovs1, "node 1 after ping with router");
            netOvs.logState(ovs2, "node 2 after ping with router");
            if (isUserSpace) {
                LOG.info("Ping status rc: {}, ignored for UserSpace", rc);
            } else {
                assertTrue("Ping (with router) failed between VM1 and VM2", rc == 0);
            }

            destroyOvs(netOvs);
            disconnectOvs(nodeInfo);
            disconnectOvs(nodeInfo2);
        } catch (Exception e) {
            LOG.error("testNeutronNetL3TwoNodes: Exception thrown by OvsDocker.OvsDocker()", e);
            fail("testNeutronNetL3TwoNodes: Exception thrown by OvsDocker.OvsDocker() : " + e.getMessage());
        }
    }

    private NetOvs getNetOvs(DockerOvs ovs, Boolean isUserSpace) {
        NetOvs netOvs;
        if (ovs.usingExternalDocker()) {
            netOvs = new RealNetOvsImpl(ovs, isUserSpace, mdsalUtils, southboundUtils);
        } else {
            netOvs = new DockerNetOvsImpl(ovs, isUserSpace, mdsalUtils, southboundUtils);
        }
        return netOvs;
    }

    private NodeInfo connectOvs(NetOvs netOvs, int ovsInstance, DockerOvs ovs) throws Exception {
        LOG.info("connectOvs enter: netOvs {}", ovsInstance);
        netOvs.logState(ovsInstance, "node " + ovsInstance + " idle");
        ConnectionInfo connectionInfo =
                SouthboundUtils.getConnectionInfo(ovs.getOvsdbAddress(ovsInstance), ovs.getOvsdbPort(ovsInstance));
        NodeInfo nodeInfo = itUtils.createNodeInfo(connectionInfo, null);
        nodeInfo.connect();
        LOG.info("connectOvs: node {} should be connected: {}",
                ovsInstance, nodeInfo.ovsdbNode.getNodeId());
        String localIp = netOvs.getInstanceIp(ovsInstance);
        addLocalIp(nodeInfo, localIp);

        validateDefaultFlows(nodeInfo.datapathId, 2 * 60 * 1000);
        netOvs.logState(ovsInstance, "node " + ovsInstance + " default flows");
        LOG.info("connectOvs exit: netOvs {}", ovsInstance);
        return nodeInfo;
    }

    private void disconnectOvs(NodeInfo nodeInfo) throws Exception {
        LOG.info("disconnectOvs enter: {}", nodeInfo.ovsdbNode.getNodeId().getValue());
        nodeInfo.disconnect();
        Thread.sleep(5000);
        LOG.info("disconnectOvs exit: {}", nodeInfo.ovsdbNode.getNodeId().getValue());
    }

    private void destroyOvs(NetOvs netOvs) throws InterruptedException {
        LOG.info("destroyOvs enter");
        netOvs.destroy();
        // This sleep allows netvirt and genius to run properly cleanup of neutron ports
        // and networks deleted by destroy()
        Thread.sleep(5000);
        LOG.info("destroyOvs exit");
    }

    private String addPort(NetOvs netOvs, NodeInfo nodeInfo, int ovsInstance, String networkName,
            List<Uuid> securityGroupList) throws Exception {
        String port = netOvs.createPort(ovsInstance, nodeInfo.bridgeNode, networkName, securityGroupList);
        LOG.info("addPort enter: Bridge node: {}, Created port: {} on network: {}",
                nodeInfo.bridgeNode.getNodeId().getValue(), netOvs.getPortInfo(port), networkName);

        InstanceIdentifier<TerminationPoint> tpIid =
                southboundUtils.createTerminationPointInstanceIdentifier(nodeInfo.bridgeNode, port);
        final NotifyingDataChangeListener portOperationalListener =
                new NotifyingDataChangeListener(LogicalDatastoreType.OPERATIONAL,
                        NotifyingDataChangeListener.BIT_CREATE, tpIid, null);
        portOperationalListener.registerDataChangeListener(dataBroker);

        netOvs.preparePortForPing(port);

        portOperationalListener.waitForCreation(10000);
        portOperationalListener.clear();
        portOperationalListener.close();
        // TODO: find better wait condition, what event indicates the port is added
        // in the models and is ready for use
        Thread.sleep(30000);
        netOvs.logState(ovsInstance, "node " + ovsInstance + " " + nodeInfo.bridgeNode.getNodeId().getValue()
                + " after port " + netOvs.getPortInfo(port));
        LOG.info("addPort exit: Bridge node: {}, Created port: {} on network: {}",
                nodeInfo.bridgeNode.getNodeId().getValue(), netOvs.getPortInfo(port), networkName);
        return port;
    }

    private void addRouter(NetOvs netOvs, String routerName) throws Exception {
        LOG.info("addRouter enter: {}", routerName);
        String routerId = netOvs.createRouter(routerName);

        //wait for VpnMap update before starting to use the router
        InstanceIdentifier<VpnMap> vpnIid = InstanceIdentifier.builder(VpnMaps.class)
                .child(VpnMap.class, new VpnMapKey(new Uuid(routerId)))
                .build();
        final NotifyingDataChangeListener vpnMapListener =
                new NotifyingDataChangeListener(LogicalDatastoreType.CONFIGURATION,
                        NotifyingDataChangeListener.BIT_CREATE, vpnIid, null);
        vpnMapListener.registerDataChangeListener(dataBroker);
        vpnMapListener.waitForCreation(10000);
        vpnMapListener.close();
        LOG.info("addRouter exit: {}", routerName);
    }

    private void waitForTunnels() throws InterruptedException {
        LOG.info("waitForTunnels enter");
        InstanceIdentifier<TunnelsState> tunIid = InstanceIdentifier.builder(TunnelsState.class).build();
        for (int i = 0; i < 10; i++) {
            TunnelsState tunnelsState = mdsalUtils.read(LogicalDatastoreType.OPERATIONAL, tunIid);
            LOG.info("waitForTunnels try {}, {}", i, tunnelsState);
            if (tunnelsState != null && tunnelsState.getStateTunnelList() != null) {
                // TODO: add more verification to validate the two tunnels are the right ones
                // i.e. check host ips or other parts of the model
                if (tunnelsState.getStateTunnelList().size() == 2) {
                    LOG.info("waitForTunnels found both tunnels");
                    break;
                } else {
                    LOG.info("waitForTunnels try {}, size: {}", i, tunnelsState.getStateTunnelList().size());
                }
            } else {
                Thread.sleep(1000);
            }
        }
        Thread.sleep(3000);
        LOG.info("waitForTunnels exit");
    }
}
