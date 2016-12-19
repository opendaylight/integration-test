/*
 * Copyright (c) 2015 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.bgpmanager;

import com.google.common.base.Optional;
import io.netty.util.concurrent.GlobalEventExecutor;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.lang.reflect.Constructor;
import java.net.InetAddress;
import java.net.NetworkInterface;
import java.util.Arrays;
import java.util.Enumeration;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Timer;
import java.util.TimerTask;
import java.util.concurrent.Callable;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeoutException;
import java.util.concurrent.atomic.AtomicBoolean;
import org.opendaylight.controller.config.api.osgi.WaitingServiceTracker;
import org.opendaylight.controller.md.sal.binding.api.ClusteredDataTreeChangeListener;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.controller.md.sal.binding.api.DataChangeListener;
import org.opendaylight.controller.md.sal.common.api.clustering.EntityOwnershipChange;
import org.opendaylight.controller.md.sal.common.api.clustering.EntityOwnershipListener;
import org.opendaylight.controller.md.sal.common.api.clustering.EntityOwnershipService;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.genius.datastoreutils.AsyncDataTreeChangeListenerBase;
import org.opendaylight.genius.utils.clustering.EntityOwnerUtils;
import org.opendaylight.netvirt.bgpmanager.api.IBgpManager;
import org.opendaylight.netvirt.bgpmanager.commands.ClearBgpCli;
import org.opendaylight.netvirt.bgpmanager.oam.BgpAlarms;
import org.opendaylight.netvirt.bgpmanager.oam.BgpConstants;
import org.opendaylight.netvirt.bgpmanager.oam.BgpCounters;
import org.opendaylight.netvirt.bgpmanager.oam.BgpAlarms;
import org.opendaylight.netvirt.bgpmanager.thrift.client.BgpRouter;
import org.opendaylight.netvirt.bgpmanager.thrift.client.BgpRouterException;
import org.opendaylight.netvirt.bgpmanager.thrift.client.BgpSyncHandle;
import org.opendaylight.netvirt.bgpmanager.thrift.gen.Routes;
import org.opendaylight.netvirt.bgpmanager.thrift.gen.Update;
import org.opendaylight.netvirt.bgpmanager.thrift.gen.af_afi;
import org.opendaylight.netvirt.bgpmanager.thrift.gen.af_safi;
import org.opendaylight.netvirt.bgpmanager.thrift.gen.protocol_type;
import org.opendaylight.netvirt.bgpmanager.thrift.gen.qbgpConstants;
import org.opendaylight.netvirt.bgpmanager.thrift.server.BgpThriftService;
import org.opendaylight.netvirt.fibmanager.api.RouteOrigin;
import org.opendaylight.yang.gen.v1.urn.ericsson.params.xml.ns.yang.ebgp.rev150901.Bgp;
import org.opendaylight.yang.gen.v1.urn.ericsson.params.xml.ns.yang.ebgp.rev150901.EncapType;
import org.opendaylight.yang.gen.v1.urn.ericsson.params.xml.ns.yang.ebgp.rev150901.ProtocolType;
import org.opendaylight.yang.gen.v1.urn.ericsson.params.xml.ns.yang.ebgp.rev150901.bgp.AsId;
import org.opendaylight.yang.gen.v1.urn.ericsson.params.xml.ns.yang.ebgp.rev150901.bgp.AsIdBuilder;
import org.opendaylight.yang.gen.v1.urn.ericsson.params.xml.ns.yang.ebgp.rev150901.bgp.ConfigServer;
import org.opendaylight.yang.gen.v1.urn.ericsson.params.xml.ns.yang.ebgp.rev150901.bgp.ConfigServerBuilder;
import org.opendaylight.yang.gen.v1.urn.ericsson.params.xml.ns.yang.ebgp.rev150901.bgp.GracefulRestart;
import org.opendaylight.yang.gen.v1.urn.ericsson.params.xml.ns.yang.ebgp.rev150901.bgp.GracefulRestartBuilder;
import org.opendaylight.yang.gen.v1.urn.ericsson.params.xml.ns.yang.ebgp.rev150901.bgp.Logging;
import org.opendaylight.yang.gen.v1.urn.ericsson.params.xml.ns.yang.ebgp.rev150901.bgp.LoggingBuilder;
import org.opendaylight.yang.gen.v1.urn.ericsson.params.xml.ns.yang.ebgp.rev150901.bgp.Neighbors;
import org.opendaylight.yang.gen.v1.urn.ericsson.params.xml.ns.yang.ebgp.rev150901.bgp.NeighborsBuilder;
import org.opendaylight.yang.gen.v1.urn.ericsson.params.xml.ns.yang.ebgp.rev150901.bgp.NeighborsKey;
import org.opendaylight.yang.gen.v1.urn.ericsson.params.xml.ns.yang.ebgp.rev150901.bgp.Networks;
import org.opendaylight.yang.gen.v1.urn.ericsson.params.xml.ns.yang.ebgp.rev150901.bgp.NetworksBuilder;
import org.opendaylight.yang.gen.v1.urn.ericsson.params.xml.ns.yang.ebgp.rev150901.bgp.NetworksKey;
import org.opendaylight.yang.gen.v1.urn.ericsson.params.xml.ns.yang.ebgp.rev150901.bgp.Vrfs;
import org.opendaylight.yang.gen.v1.urn.ericsson.params.xml.ns.yang.ebgp.rev150901.bgp.VrfsBuilder;
import org.opendaylight.yang.gen.v1.urn.ericsson.params.xml.ns.yang.ebgp.rev150901.bgp.VrfsKey;
import org.opendaylight.yang.gen.v1.urn.ericsson.params.xml.ns.yang.ebgp.rev150901.bgp.neighbors.AddressFamilies;
import org.opendaylight.yang.gen.v1.urn.ericsson.params.xml.ns.yang.ebgp.rev150901.bgp.neighbors.AddressFamiliesBuilder;
import org.opendaylight.yang.gen.v1.urn.ericsson.params.xml.ns.yang.ebgp.rev150901.bgp.neighbors.AddressFamiliesKey;
import org.opendaylight.yang.gen.v1.urn.ericsson.params.xml.ns.yang.ebgp.rev150901.bgp.neighbors.EbgpMultihop;
import org.opendaylight.yang.gen.v1.urn.ericsson.params.xml.ns.yang.ebgp.rev150901.bgp.neighbors.EbgpMultihopBuilder;
import org.opendaylight.yang.gen.v1.urn.ericsson.params.xml.ns.yang.ebgp.rev150901.bgp.neighbors.UpdateSource;
import org.opendaylight.yang.gen.v1.urn.ericsson.params.xml.ns.yang.ebgp.rev150901.bgp.neighbors.UpdateSourceBuilder;
import org.opendaylight.yang.gen.v1.urn.huawei.params.xml.ns.yang.l3vpn.rev140815.vpn.instances.VpnInstance;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.inet.types.rev130715.Ipv4Address;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.FibEntries;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.fibentries.VrfTables;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.vrfentries.VrfEntry;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.vrfentries.VrfEntryBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.l3vpn.rev130911.vpn.instance.op.data.VpnInstanceOpDataEntry;
import org.opendaylight.yangtools.concepts.ListenerRegistration;
import org.opendaylight.yangtools.yang.binding.DataObject;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.opendaylight.genius.utils.batching.DefaultBatchHandler;
import org.osgi.framework.BundleContext;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import java.util.concurrent.atomic.AtomicInteger;
import org.opendaylight.yangtools.yang.binding.DataObject;

public class BgpConfigurationManager {
    private static final Logger LOG = LoggerFactory.getLogger(BgpConfigurationManager.class);
    private static DataBroker dataBroker;
    private static FibDSWriter fibDSWriter;
    public static IBgpManager bgpManager;
    private final BundleContext bundleContext;
    private static Bgp config;
    private static BgpRouter bgpRouter;
    private static BgpThriftService updateServer;
    private BgpCounters bgpCounters;
    private BgpAlarms bgpAlarms;
    private Timer bgpCountersTimer;
    private Timer bgpAlarmsTimer;
    private static final String DEF_LOGFILE = "/var/log/bgp_debug.log";
    private static final String DEF_LOGLEVEL = "errors";
    private static final String UPDATE_PORT = "bgp.thrift.service.port";
    private static final String CONFIG_HOST = "vpnservice.bgpspeaker.host.name";
    private static final String CONFIG_PORT = "vpnservice.bgpspeaker.thrift.port";
    private static final String DEF_UPORT = "6644";
    private static final String DEF_CHOST = "127.0.0.1";
    private static final String DEF_CPORT = "7644";
    private static final String SDNC_BGP_MIP = "sdnc_bgp_mip";
    private static final String BGP_SDNC_MIP = "bgp_sdnc_mip";
    private static final String CLUSTER_CONF_FILE = "/cluster/etc/cluster.conf";
    private static final Timer ipActivationCheckTimer = new Timer();
    private static final int STALE_FIB_WAIT = 60;
    private static final int RESTART_DEFAULT_GR = 90;
    private long StaleStartTime = 0;
    private long StaleEndTime = 0;
    private long CfgReplayStartTime = 0;
    private long CfgReplayEndTime = 0;
    private long StaleCleanupTime = 0;
    private static final int dsRetryCoount = 100; //100 retries, each after waitTimeBetweenEachTryMillis seconds.
    private static final long waitTimeBetweenEachTryMillis = 1000L; //one second sleep after every retry

    public String getBgpSdncMipIp() { return readThriftIpForCommunication(BGP_SDNC_MIP);}
    public long getStaleCleanupTime() {
        return StaleCleanupTime;
    }

    public void setStaleCleanupTime(long staleCleanupTime) {
        StaleCleanupTime = staleCleanupTime;
    }

    public long getCfgReplayEndTime() {
        return CfgReplayEndTime;
    }

    public void setCfgReplayEndTime(long cfgReplayEndTime) {
        CfgReplayEndTime = cfgReplayEndTime;
    }

    public long getCfgReplayStartTime() {
        return CfgReplayStartTime;
    }

    public void setCfgReplayStartTime(long cfgReplayStartTime) {
        CfgReplayStartTime = cfgReplayStartTime;
    }

    public long getStaleEndTime() {
        return StaleEndTime;
    }

    public void setStaleEndTime(long staleEndTime) {
        StaleEndTime = staleEndTime;
    }

    public long getStaleStartTime() {
        return StaleStartTime;
    }

    public void setStaleStartTime(long staleStartTime) {
        StaleStartTime = staleStartTime;
    }


    // to have stale FIB map (RD, Prefix)
    //  number of seconds wait for route sync-up between ODL and BGP
    private static final int BGP_RESTART_ROUTE_SYNC_SEC = 600;

    static String odlThriftIp = "127.0.0.1";
    static String bgpThriftIp = "127.0.0.1";
    private static String cHostStartup;
    private static String cPortStartup;
    private static CountDownLatch initer = new CountDownLatch(1);
    //static IITMProvider itmProvider;
    //map<rd, map<prefix/len, nexthop/label>>
    private static Map<String, Map<String, String>> staledFibEntriesMap = new ConcurrentHashMap<>();

    static final String BGP_ENTITY_TYPE_FOR_OWNERSHIP = "bgp";
    static final String BGP_ENTITY_NAME = "bgp";

    static int totalStaledCount = 0;
    static int totalCleared = 0;

    private static final Class[] reactors = {
            ConfigServerReactor.class, AsIdReactor.class,
            GracefulRestartReactor.class, LoggingReactor.class,
            NeighborsReactor.class, UpdateSourceReactor.class,
            EbgpMultihopReactor.class, AddressFamiliesReactor.class,
            NetworksReactor.class, VrfsReactor.class, BgpReactor.class
    };

    private ListenerRegistration<DataChangeListener>[] registrations;

    final BgpConfigurationManager bgpConfigurationManager;

    public BgpConfigurationManager(final DataBroker dataBroker,
                                   final EntityOwnershipService entityOwnershipService,
                                   final FibDSWriter fibDSWriter,
                                   final BundleContext bundleContext)
            throws InterruptedException, ExecutionException, TimeoutException {
        BgpConfigurationManager.dataBroker = dataBroker;
        BgpConfigurationManager.fibDSWriter = fibDSWriter;
        this.bundleContext = bundleContext;
        String uPort = getProperty(UPDATE_PORT, DEF_UPORT);
        cHostStartup = getProperty(CONFIG_HOST, DEF_CHOST);
        cPortStartup = getProperty(CONFIG_PORT, DEF_CPORT);
        LOG.info("UpdateServer at localhost:" + uPort + " ConfigServer at "
                + cHostStartup + ":" + cPortStartup);
        VtyshCli.setHostAddr(cHostStartup);
        ClearBgpCli.setHostAddr(cHostStartup);
        setEntityOwnershipService(entityOwnershipService);
        bgpRouter = BgpRouter.getInstance();
        odlThriftIp = readThriftIpForCommunication(SDNC_BGP_MIP);
        bgpThriftIp = readThriftIpForCommunication(BGP_SDNC_MIP);
        registerCallbacks();

        LOG.info("BGP Configuration manager initialized");
        initer.countDown();

        bgpConfigurationManager = this;
        BgpUtil.batchSize = BgpUtil.BATCH_SIZE;
        if (Integer.getInteger("batch.size") != null) {
            BgpUtil.batchSize = Integer.getInteger("batch.size");
        }
        BgpUtil.batchInterval = BgpUtil.PERIODICITY;
        if (Integer.getInteger("batch.wait.time") != null) {
            BgpUtil.batchInterval = Integer.getInteger("batch.wait.time");
        }
        BgpUtil.registerWithBatchManager(new DefaultBatchHandler(dataBroker, LogicalDatastoreType.CONFIGURATION, BgpUtil.batchSize, BgpUtil.batchInterval));

        GlobalEventExecutor.INSTANCE.execute(new Runnable() {
            @Override
            public void run() {
                final WaitingServiceTracker<IBgpManager> tracker = WaitingServiceTracker.create(
                        IBgpManager.class, bundleContext);
                bgpManager = tracker.waitForService(WaitingServiceTracker.FIVE_MINUTES);
                updateServer = new BgpThriftService(Integer.parseInt(uPort), bgpManager, fibDSWriter);
                updateServer.start();
                LOG.info("BgpConfigurationManager initialized. IBgpManager={}", bgpManager);
            }
        });
    }

    private Object createListener(Class<?> cls) {
        Constructor<?> ctor;
        Object obj = null;

        try {
            ctor = cls.getConstructor(BgpConfigurationManager.class);
            obj = ctor.newInstance(this);
        } catch (Exception e) {
            LOG.error("Failed to create listener object", e);
        }
        return obj;
    }

    private void registerCallbacks() {
        String emsg = "Failed to register listener";
        registrations = new ListenerRegistration[reactors.length];
        InstanceIdentifier<?> iid = InstanceIdentifier.create(Bgp.class);
        for (Class reactor : reactors) {
            Object obj = createListener(reactor);
            String dclName = obj.getClass().getName();
            try {
                AsyncDataTreeChangeListenerBase dcl = (AsyncDataTreeChangeListenerBase) obj;
                dcl.registerListener(LogicalDatastoreType.CONFIGURATION, dataBroker);
            } catch (Exception e) {
                LOG.error(emsg, e);
                throw new IllegalStateException(emsg + " " + dclName, e);
            }
        }
    }

    public void close() {
        if (updateServer != null) {
            updateServer.stop();
        }
        LOG.info("{} close", getClass().getSimpleName());
    }

    private boolean configExists() throws InterruptedException, ExecutionException, TimeoutException {
        InstanceIdentifier.InstanceIdentifierBuilder<Bgp> iib =
                InstanceIdentifier.builder(Bgp.class);
        InstanceIdentifier<Bgp> iid = iib.build();
        Optional<Bgp> b = BgpUtil.read(dataBroker,
                LogicalDatastoreType.CONFIGURATION, iid);
        return b.isPresent();
    }

    private String getProperty(String var, String def) {
        String s = bundleContext.getProperty(var);
        return (s == null ? def : s);
    }

    boolean ignoreClusterDcnEventForFollower() {
        return !EntityOwnerUtils.amIEntityOwner(BGP_ENTITY_TYPE_FOR_OWNERSHIP, BGP_ENTITY_NAME);
    }

    public Bgp get() {
        config = getConfig();
        return config;
    }

    public void setEntityOwnershipService(final EntityOwnershipService entityOwnershipService) {
        try {
            EntityOwnerUtils.registerEntityCandidateForOwnerShip(entityOwnershipService,
                    BGP_ENTITY_TYPE_FOR_OWNERSHIP, BGP_ENTITY_NAME, new EntityOwnershipListener() {
                @Override
                public void ownershipChanged(EntityOwnershipChange ownershipChange) {
                    LOG.trace("entity owner change event fired");
                    if (ownershipChange.hasOwner() && ownershipChange.isOwner()) {
                        LOG.trace("This PL is the Owner");
                        activateMIP();
                        bgpRestarted();
                    } else {
                        LOG.info("Not owner: hasOwner: {}, isOwner: {}",ownershipChange.hasOwner(),
                                ownershipChange.isOwner() );
                    }
                }
            });
        } catch (Exception e) {
            LOG.error("failed to register bgp entity", e);
        }
    }

    private static final String addWarn =
            "Config store updated; undo with Delete if needed.";
    private static final String delWarn =
            "Config store updated; undo with Add if needed.";
    private static final String updWarn =
            "Update operation not supported; Config store updated;"
                    + " restore with another Update if needed.";

    public class ConfigServerReactor
            extends AsyncDataTreeChangeListenerBase<ConfigServer, ConfigServerReactor>
            implements AutoCloseable, ClusteredDataTreeChangeListener <ConfigServer> {
        private static final String yangObj = "config-server ";

        public ConfigServerReactor() {
            super(ConfigServer.class, ConfigServerReactor.class);
        }

        @Override
        protected synchronized void
        add(InstanceIdentifier<ConfigServer> iid, ConfigServer val) {
            LOG.trace("received bgp connect config host {}", val.getHost().getValue());
            if (ignoreClusterDcnEventForFollower()) {
                return;
            }

            try {
                initer.await();
            } catch (Exception e) {
            }
            LOG.debug("issueing bgp router connect to host {}", val.getHost().getValue());
            synchronized (BgpConfigurationManager.this) {
                boolean res = bgpRouter.connect(val.getHost().getValue(),
                        val.getPort().intValue());
                if (!res) {
                    LOG.error(yangObj + "Add failed; " + addWarn);
                }
            }
        }

        @Override
        protected ConfigServerReactor getDataTreeChangeListener() {
            return ConfigServerReactor.this;
        }

        @Override
        protected InstanceIdentifier<ConfigServer> getWildCardPath() {
            return InstanceIdentifier.create(Bgp.class).child(ConfigServer.class);
        }

        @Override
        protected synchronized void
        remove(InstanceIdentifier<ConfigServer> iid, ConfigServer val) {
            LOG.trace("received bgp disconnect");
            if (ignoreClusterDcnEventForFollower()) {
                return;
            }
            synchronized (BgpConfigurationManager.this) {
                bgpRouter.disconnect();
            }
        }

        @Override
        protected void update(InstanceIdentifier<ConfigServer> iid,
                              ConfigServer oldval, ConfigServer newval) {
            LOG.trace("received bgp Connection update");
            if (ignoreClusterDcnEventForFollower()) {
                return;
            }
            LOG.error(yangObj + updWarn);
        }

        @Override
        public void close() {
            try {
                super.close();
            } catch (Exception e) {
                LOG.error("ConfigServerReactor failed to close: ", e);
            }
        }
    }

    private BgpRouter getClient(String yangObj) {
        if (bgpRouter == null) {
            LOG.warn("{}: configuration received when BGP is inactive", yangObj);
        }
        return bgpRouter;
    }

    public class AsIdReactor
            extends AsyncDataTreeChangeListenerBase<AsId, AsIdReactor>
            implements AutoCloseable, ClusteredDataTreeChangeListener<AsId> {

        private static final String yangObj = "as-id ";

        public AsIdReactor() {
            super(AsId.class, AsIdReactor.class);
        }

        @Override
        protected synchronized void
        add(InstanceIdentifier<AsId> iid, AsId val) {
            LOG.error("received bgp add asid {}",val);
            if (ignoreClusterDcnEventForFollower()) {
                return;
            }
            LOG.debug("received add router config asNum {}", val.getLocalAs().longValue());
            synchronized (BgpConfigurationManager.this) {
                BgpRouter br = getClient(yangObj);
                if (br == null) {
                    LOG.error("no bgp router client found exiting asid add");
                    return;
                }
                long asNum = val.getLocalAs().longValue();
                Ipv4Address routerId = val.getRouterId();
                Boolean afb = val.isAnnounceFbit();
                String rid = (routerId == null) ? "" : routerId.getValue();
                int stalepathTime = (int) getStalePathtime(RESTART_DEFAULT_GR, val);
                boolean announceFbit = true;
                try {
                    br.startBgp(asNum, rid, stalepathTime, announceFbit);
                    if (getBgpCounters() == null) {
                        startBgpCountersTask();
                    }
                    if (getBgpAlarms() == null) {
                        startBgpAlarmsTask();
                    }
                } catch (BgpRouterException bre) {
                    if (bre.getErrorCode() == BgpRouterException.BGP_ERR_ACTIVE) {
                        LOG.error(yangObj + "Add requested when BGP is already active");
                    } else {
                        LOG.error(yangObj + "Add received exception: \""
                                + bre + "\"; " + addWarn);
                    }
                } catch (Exception e) {
                    LOG.error(yangObj + "Add received exception: \"" + e + "\"; " + addWarn);
                }
            }
        }

        @Override
        protected AsIdReactor getDataTreeChangeListener() {
            return AsIdReactor.this;
        }

        @Override
        protected InstanceIdentifier<AsId> getWildCardPath() {
            return InstanceIdentifier.create(Bgp.class).child(AsId.class);
        }

        @Override
        protected synchronized void
        remove(InstanceIdentifier<AsId> iid, AsId val) {
            LOG.error("received delete router config asNum {}", val.getLocalAs().longValue());
            if (ignoreClusterDcnEventForFollower()) {
                return;
            }
            synchronized (BgpConfigurationManager.this) {
                BgpRouter br = getClient(yangObj);
                if (br == null) {
                    return;
                }
                long asNum = val.getLocalAs().longValue();
                try {
                    br.stopBgp(asNum);
                } catch (Exception e) {
                    LOG.error(yangObj + " Delete received exception:  \"" + e + "\"; " + delWarn);
                }
                if (getBgpCounters() != null) {
                    stopBgpCountersTask();
                }
                if (getBgpAlarms() != null) {
                    stopBgpAlarmsTask();
                }
            }
        }

        @Override
        protected void update(InstanceIdentifier<AsId> iid,
                              AsId oldval, AsId newval) {
            if (ignoreClusterDcnEventForFollower()) {
                return;
            }
            LOG.error(yangObj + updWarn);
        }

        @Override
        public void close() {
            try {
                super.close();
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    public class GracefulRestartReactor
            extends AsyncDataTreeChangeListenerBase<GracefulRestart, GracefulRestartReactor>
            implements AutoCloseable, ClusteredDataTreeChangeListener<GracefulRestart> {

        private static final String yangObj = "graceful-restart ";

        public GracefulRestartReactor() {
            super(GracefulRestart.class, GracefulRestartReactor.class);
        }

        @Override
        protected synchronized void
        add(InstanceIdentifier<GracefulRestart> iid, GracefulRestart val) {
            if (ignoreClusterDcnEventForFollower()) {
                return;
            }
            synchronized (BgpConfigurationManager.this) {
                BgpRouter br = getClient(yangObj);
                if (br == null) {
                    return;
                }
                try {
                    br.addGracefulRestart(val.getStalepathTime().intValue());
                } catch (Exception e) {
                    LOG.error(yangObj + "Add received exception: \"" + e + "\"; " + addWarn);
                }
            }
        }

        @Override
        protected GracefulRestartReactor getDataTreeChangeListener() {
            return GracefulRestartReactor.this;
        }

        @Override
        protected InstanceIdentifier<GracefulRestart> getWildCardPath() {
            return InstanceIdentifier.create(Bgp.class).child(GracefulRestart.class);
        }

        @Override
        protected synchronized void
        remove(InstanceIdentifier<GracefulRestart> iid, GracefulRestart val) {
            if (ignoreClusterDcnEventForFollower()) {
                return;
            }
            LOG.debug("received delete GracefulRestart config val {}", val.getStalepathTime().intValue());
            synchronized (BgpConfigurationManager.this) {
                BgpRouter br = getClient(yangObj);
                if (br == null) {
                    return;
                }
                try {
                    br.delGracefulRestart();
                } catch (Exception e) {
                    LOG.error(yangObj + " Delete received exception:  \"" + e + "\"; "
                            + delWarn);
                }
            }
        }

        @Override
        protected void update(InstanceIdentifier<GracefulRestart> iid,
                              GracefulRestart oldval, GracefulRestart newval) {
            if (ignoreClusterDcnEventForFollower()) {
                return;
            }
            LOG.debug("received update GracefulRestart config val {}", newval.getStalepathTime().intValue());
            synchronized (BgpConfigurationManager.this) {
                BgpRouter br = getClient(yangObj);
                if (br == null) {
                    return;
                }
                try {
                    br.addGracefulRestart(newval.getStalepathTime().intValue());
                } catch (Exception e) {
                    LOG.error(yangObj + "update received exception: \"" + e + "\"; " + addWarn);
                }
            }
        }

        @Override
        public void close() {
            try {
                super.close();
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    public class LoggingReactor
            extends AsyncDataTreeChangeListenerBase<Logging, LoggingReactor>
            implements AutoCloseable, ClusteredDataTreeChangeListener<Logging> {

        private static final String yangObj = "logging ";

        public LoggingReactor() {
            super(Logging.class, LoggingReactor.class);
        }

        @Override
        protected synchronized void
        add(InstanceIdentifier<Logging> iid, Logging val) {
            if (ignoreClusterDcnEventForFollower()) {
                return;
            }
            synchronized (BgpConfigurationManager.this) {
                BgpRouter br = getClient(yangObj);
                if (br == null) {
                    return;
                }
                try {
                    br.setLogging(val.getFile(), val.getLevel());
                } catch (Exception e) {
                    LOG.error(yangObj + "Add received exception: \"" + e + "\"; "
                            + addWarn);
                }
            }
        }

        @Override
        protected LoggingReactor getDataTreeChangeListener() {
            return LoggingReactor.this;
        }

        @Override
        protected InstanceIdentifier<Logging> getWildCardPath() {
            return InstanceIdentifier.create(Bgp.class).child(Logging.class);
        }

        @Override
        protected synchronized void
        remove(InstanceIdentifier<Logging> iid, Logging val) {
            if (ignoreClusterDcnEventForFollower()) {
                return;
            }
            LOG.debug("received remove Logging config val {}", val.getLevel());
            synchronized (BgpConfigurationManager.this) {
                BgpRouter br = getClient(yangObj);
                if (br == null) {
                    return;
                }
                try {
                    br.setLogging(DEF_LOGFILE, DEF_LOGLEVEL);
                } catch (Exception e) {
                    LOG.error(yangObj + " Delete received exception:  \"" + e + "\"; "
                            + delWarn);
                }
            }
        }

        @Override
        protected void update(InstanceIdentifier<Logging> iid,
                              Logging oldval, Logging newval) {
            if (ignoreClusterDcnEventForFollower()) {
                return;
            }
            synchronized (BgpConfigurationManager.this) {
                BgpRouter br = getClient(yangObj);
                if (br == null) {
                    return;
                }
                try {
                    br.setLogging(newval.getFile(), newval.getLevel());
                } catch (Exception e) {
                    LOG.error(yangObj + "newval received exception: \"" + e + "\"; "
                            + addWarn);
                }
            }
        }

        @Override
        public void close() {
            try {
                super.close();
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    public class NeighborsReactor
            extends AsyncDataTreeChangeListenerBase<Neighbors, NeighborsReactor>
            implements AutoCloseable, ClusteredDataTreeChangeListener<Neighbors> {

        private static final String yangObj = "neighbors ";

        public NeighborsReactor() {
            super(Neighbors.class, NeighborsReactor.class);
        }

        @Override
        protected synchronized void
        add(InstanceIdentifier<Neighbors> iid, Neighbors val) {
            if (ignoreClusterDcnEventForFollower()) {
                return;
            }
            LOG.debug("received add Neighbors config val {}", val.getAddress().getValue());
            synchronized (BgpConfigurationManager.this) {
                BgpRouter br = getClient(yangObj);
                if (br == null) {
                    return;
                }
                String peerIp = val.getAddress().getValue();
                long as = val.getRemoteAs().longValue();
                try {
                    //itmProvider.buildTunnelsToDCGW(new IpAddress(peerIp.toCharArray()));
                    br.addNeighbor(peerIp, as);

                } catch (Exception e) {
                    LOG.error(yangObj + "Add received exception: \"" + e + "\"; "
                            + addWarn);
                }
            }
        }

        @Override
        protected NeighborsReactor getDataTreeChangeListener() {
            return NeighborsReactor.this;
        }

        @Override
        protected InstanceIdentifier<Neighbors> getWildCardPath() {
            return InstanceIdentifier.create(Bgp.class).child(Neighbors.class);
        }

        @Override
        protected synchronized void
        remove(InstanceIdentifier<Neighbors> iid, Neighbors val) {
            if (ignoreClusterDcnEventForFollower()) {
                return;
            }
            LOG.debug("received remove Neighbors config val {}", val.getAddress().getValue());
            synchronized (BgpConfigurationManager.this) {
                BgpRouter br = getClient(yangObj);
                if (br == null) {
                    return;
                }
                String peerIp = val.getAddress().getValue();
                try {
                    //itmProvider.deleteTunnelsToDCGW(new IpAddress(val.getAddress().getValue().toCharArray()));
                    br.delNeighbor(peerIp);
                } catch (Exception e) {
                    LOG.error(yangObj + " Delete received exception:  \"" + e + "\"; "
                            + delWarn);
                }
            }
        }

        @Override
        protected void update(InstanceIdentifier<Neighbors> iid,
                              Neighbors oldval, Neighbors newval) {
            if (ignoreClusterDcnEventForFollower()) {
                return;
            }
            //purposefully nothing to do.
        }

        @Override
        public void close() {
            try {
                super.close();
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    public class EbgpMultihopReactor
            extends AsyncDataTreeChangeListenerBase<EbgpMultihop, EbgpMultihopReactor>
            implements AutoCloseable, ClusteredDataTreeChangeListener<EbgpMultihop> {

        private static final String yangObj = "ebgp-multihop ";

        public EbgpMultihopReactor() {
            super(EbgpMultihop.class, EbgpMultihopReactor.class);
        }

        @Override
        protected synchronized void
        add(InstanceIdentifier<EbgpMultihop> iid, EbgpMultihop val) {
            if (ignoreClusterDcnEventForFollower()) {
                return;
            }
            LOG.debug("received add EbgpMultihop config val {}", val.getPeerIp().getValue());
            synchronized (BgpConfigurationManager.this) {
                BgpRouter br = getClient(yangObj);
                if (br == null) {
                    return;
                }
                String peerIp = val.getPeerIp().getValue();
                try {
                    br.addEbgpMultihop(peerIp, val.getNhops().intValue());
                } catch (Exception e) {
                    LOG.error(yangObj + "Add received exception: \"" + e + "\"; "
                            + addWarn);
                }
            }
        }

        @Override
        protected EbgpMultihopReactor getDataTreeChangeListener() {
            return EbgpMultihopReactor.this;
        }

        @Override
        protected InstanceIdentifier<EbgpMultihop> getWildCardPath() {
            return InstanceIdentifier.create(Bgp.class).child(Neighbors.class).child(EbgpMultihop.class);
        }

        @Override
        protected synchronized void
        remove(InstanceIdentifier<EbgpMultihop> iid, EbgpMultihop val) {
            if (ignoreClusterDcnEventForFollower()) {
                return;
            }
            LOG.debug("received remove EbgpMultihop config val {}", val.getPeerIp().getValue());
            synchronized (BgpConfigurationManager.this) {
                BgpRouter br = getClient(yangObj);
                if (br == null) {
                    return;
                }
                String peerIp = val.getPeerIp().getValue();
                try {
                    br.delEbgpMultihop(peerIp);
                } catch (Exception e) {
                    LOG.error(yangObj + " Delete received exception:  \"" + e + "\"; "
                            + delWarn);
                }
            }
        }

        @Override
        protected void update(InstanceIdentifier<EbgpMultihop> iid,
                              EbgpMultihop oldval, EbgpMultihop newval) {
            if (ignoreClusterDcnEventForFollower()) {
                return;
            }
            LOG.error(yangObj + updWarn);
        }

        @Override
        public void close() {
            try {
                super.close();
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    public class UpdateSourceReactor
            extends AsyncDataTreeChangeListenerBase<UpdateSource, UpdateSourceReactor>
            implements AutoCloseable, ClusteredDataTreeChangeListener<UpdateSource> {

        private static final String yangObj = "update-source ";

        public UpdateSourceReactor() {
            super(UpdateSource.class, UpdateSourceReactor.class);
        }

        @Override
        protected synchronized void
        add(InstanceIdentifier<UpdateSource> iid, UpdateSource val) {
            if (ignoreClusterDcnEventForFollower()) {
                return;
            }
            LOG.debug("received add UpdateSource config val {}", val.getSourceIp().getValue());
            synchronized (BgpConfigurationManager.this) {
                BgpRouter br = getClient(yangObj);
                if (br == null) {
                    return;
                }
                String peerIp = val.getPeerIp().getValue();
                try {
                    br.addUpdateSource(peerIp, val.getSourceIp().getValue());
                } catch (Exception e) {
                    LOG.error(yangObj + "Add received exception: \"" + e + "\"; "
                            + addWarn);
                }
            }
        }

        @Override
        protected UpdateSourceReactor getDataTreeChangeListener() {
            return UpdateSourceReactor.this;
        }

        @Override
        protected InstanceIdentifier<UpdateSource> getWildCardPath() {
            return InstanceIdentifier.create(Bgp.class).child(Neighbors.class).child(UpdateSource.class);
        }

        @Override
        protected synchronized void
        remove(InstanceIdentifier<UpdateSource> iid, UpdateSource val) {
            if (ignoreClusterDcnEventForFollower()) {
                return;
            }
            LOG.debug("received remove UpdateSource config val {}", val.getSourceIp().getValue());
            synchronized (BgpConfigurationManager.this) {
                BgpRouter br = getClient(yangObj);
                if (br == null) {
                    return;
                }
                String peerIp = val.getPeerIp().getValue();
                try {
                    br.delUpdateSource(peerIp);
                } catch (Exception e) {
                    LOG.error(yangObj + " Delete received exception:  \"" + e + "\"; "
                            + delWarn);
                }
            }
        }

        @Override
        protected void update(InstanceIdentifier<UpdateSource> iid,
                              UpdateSource oldval, UpdateSource newval) {
            if (ignoreClusterDcnEventForFollower()) {
                return;
            }
            LOG.error(yangObj + updWarn);
        }

        @Override
        public void close() {
            try {
                super.close();
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    public class AddressFamiliesReactor
            extends AsyncDataTreeChangeListenerBase<AddressFamilies, AddressFamiliesReactor>
            implements AutoCloseable, ClusteredDataTreeChangeListener<AddressFamilies> {

        private static final String yangObj = "address-families ";

        public AddressFamiliesReactor() {
            super(AddressFamilies.class, AddressFamiliesReactor.class);
        }

        @Override
        protected synchronized void
        add(InstanceIdentifier<AddressFamilies> iid, AddressFamilies val) {
            if (ignoreClusterDcnEventForFollower()) {
                return;
            }
            LOG.debug("received add AddressFamilies config val {}", val.getPeerIp().getValue());
            synchronized (BgpConfigurationManager.this) {
                BgpRouter br = getClient(yangObj);
                if (br == null) {
                    return;
                }
                String peerIp = val.getPeerIp().getValue();
                af_afi afi = af_afi.findByValue(val.getAfi().intValue());
                af_safi safi = af_safi.findByValue(val.getSafi().intValue());
                try {
                    br.addAddressFamily(peerIp, afi, safi);
                } catch (Exception e) {
                    LOG.error(yangObj + "Add received exception: \"" + e + "\"; "
                            + addWarn);
                }
            }
        }

        @Override
        protected AddressFamiliesReactor getDataTreeChangeListener() {
            return AddressFamiliesReactor.this;
        }

        @Override
        protected InstanceIdentifier<AddressFamilies> getWildCardPath() {
            return InstanceIdentifier.create(Bgp.class).child(Neighbors.class).child(AddressFamilies.class);
        }

        @Override
        protected synchronized void
        remove(InstanceIdentifier<AddressFamilies> iid, AddressFamilies val) {
            if (ignoreClusterDcnEventForFollower()) {
                return;
            }
            LOG.debug("received remove AddressFamilies config val {}", val.getPeerIp().getValue());
            synchronized (BgpConfigurationManager.this) {
                BgpRouter br = getClient(yangObj);
                if (br == null) {
                    return;
                }
                String peerIp = val.getPeerIp().getValue();
                af_afi afi = af_afi.findByValue(val.getAfi().intValue());
                af_safi safi = af_safi.findByValue(val.getSafi().intValue());
                try {
                    br.delAddressFamily(peerIp, afi, safi);
                } catch (Exception e) {
                    LOG.error(yangObj + " Delete received exception:  \"" + e + "\"; "
                            + delWarn);
                }
            }
        }

        @Override
        protected void update(InstanceIdentifier<AddressFamilies> iid,
                              AddressFamilies oldval, AddressFamilies newval) {
            if (ignoreClusterDcnEventForFollower()) {
                return;
            }
            LOG.error(yangObj + updWarn);
        }

        @Override
        public void close() {
            try {
                super.close();
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    public class NetworksReactor
            extends AsyncDataTreeChangeListenerBase<Networks, NetworksReactor>
            implements AutoCloseable, ClusteredDataTreeChangeListener<Networks> {

        private static final String yangObj = "networks ";

        public NetworksReactor() {
            super(Networks.class, NetworksReactor.class);
        }
        @Override
        public NetworksReactor getDataTreeChangeListener() {
            return NetworksReactor.this;
        }

        @Override
        protected synchronized void
        add(InstanceIdentifier<Networks> iid, Networks val) {
            if (ignoreClusterDcnEventForFollower()) {
                return;
            }
            LOG.debug("received add Networks config val {}", val.getPrefixLen());
            synchronized (BgpConfigurationManager.this) {
                BgpRouter br = getClient(yangObj);
                if (br == null) {
                    return;
                }
                String rd = val.getRd();
                String pfxlen = val.getPrefixLen();
                String nh = val.getNexthop().getValue();
                Long label = val.getLabel();
                int lbl = (label == null) ? qbgpConstants.LBL_NO_LABEL
                        : label.intValue();
                int l3vni = (val.getL3vni() == null) ? qbgpConstants.LBL_NO_LABEL
                        :val.getL3vni().intValue();

                ProtocolType protocolType = val.getProtocolType();
                int ethernetTag = val.getEthtag().intValue();
                String esi = val.getEsi();
                String macaddress = val.getMacaddress();
                EncapType encapType = val.getEncapType();
                String routerMac = val.getRoutermac();

                try {
                    br.addPrefix(rd, pfxlen, nh, lbl, l3vni, BgpUtil.convertToThriftProtocolType(protocolType), ethernetTag, esi, macaddress, BgpUtil.convertToThriftEncapType(encapType), routerMac);
                } catch (Exception e) {
                    LOG.error(yangObj + "Add received exception: \"" + e + "\"; " + addWarn);
                }
            }
        }

        @Override
        protected InstanceIdentifier<Networks> getWildCardPath() {
            return InstanceIdentifier.create(Bgp.class).child(Networks.class);
        }

        @Override
        protected synchronized void
        remove(InstanceIdentifier<Networks> iid, Networks val) {
            if (ignoreClusterDcnEventForFollower()) {
                return;
            }
            LOG.debug("received remove Networks config val {}", val.getPrefixLen());
            synchronized (BgpConfigurationManager.this) {
                BgpRouter br = getClient(yangObj);
                if (br == null) {
                    return;
                }
                String rd = val.getRd();
                String pfxlen = val.getPrefixLen();
                Long label = val.getLabel();
                int lbl = (label == null) ? 0 : label.intValue();
                if (rd == null && lbl > 0) {
                    //LU prefix is being deleted.
                    rd = Integer.toString(lbl);
                }
                try {
                    br.delPrefix(rd, pfxlen);
                } catch (Exception e) {
                    LOG.error(yangObj + " Delete received exception:  \"" + e + "\"; "
                            + delWarn);
                }
            }
        }

        @Override
        protected void update(final InstanceIdentifier<Networks> iid,
                              final Networks oldval, final Networks newval) {
            if (ignoreClusterDcnEventForFollower()) {
                return;
            }
            if(oldval.equals(newval)){
                //Update: OLD and New values are same, no need to trigger remove/add.
                LOG.debug("received Updated for the same OLD and New values. RD: {}, Prefix: {}, Label: {}, NH: {}",
                        oldval.getRd(), oldval.getPrefixLen(), oldval.getLabel(), oldval.getNexthop());
                return;
            }
            LOG.debug("received update networks config val {}", newval.getPrefixLen());
            remove(iid, oldval);
            timer.schedule(new TimerTask() {
                @Override
                public void run() {
                    add(iid, newval);
                }
            }, Integer.getInteger("bgp.nexthop.update.delay.in.secs", 5) * 1000);
        }

        @Override
        public void close() {
            try {
                super.close();
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    static Timer timer = new Timer();

    public class VrfsReactor
            extends AsyncDataTreeChangeListenerBase<Vrfs, VrfsReactor>
            implements AutoCloseable, ClusteredDataTreeChangeListener<Vrfs> {

        private static final String yangObj = "vrfs ";

        public VrfsReactor() {
            super(Vrfs.class, VrfsReactor.class);
        }

        @Override
        protected synchronized void
        add(InstanceIdentifier<Vrfs> iid, Vrfs val) {
            if (ignoreClusterDcnEventForFollower()) {
                return;
            }
            LOG.debug("received add Vrfs config val {}", val.getRd());
            synchronized (BgpConfigurationManager.this) {
                BgpRouter br = getClient(yangObj);
                if (br == null) {
                    return;
                }
                try {
                    br.addVrf(val.getLayerType(), val.getRd(), val.getImportRts(),
                            val.getExportRts());
                } catch (Exception e) {
                    LOG.error(yangObj + "Add received exception: \"" + e + "\"; "
                            + addWarn);
                }
            }
        }

        @Override
        protected VrfsReactor getDataTreeChangeListener() {
            return VrfsReactor.this;
        }

        @Override
        protected InstanceIdentifier<Vrfs> getWildCardPath() {
            return InstanceIdentifier.create(Bgp.class).child(Vrfs.class);
        }

        @Override
        protected synchronized void
        remove(InstanceIdentifier<Vrfs> iid, Vrfs val) {
            if (ignoreClusterDcnEventForFollower()) {
                return;
            }
            LOG.debug("received remove Vrfs config val {}", val.getRd());
            synchronized (BgpConfigurationManager.this) {
                BgpRouter br = getClient(yangObj);
                if (br == null) {
                    return;
                }
                try {
                    br.delVrf(val.getRd());
                } catch (Exception e) {
                    LOG.error(yangObj + " Delete received exception:  \"" + e + "\"; "
                            + delWarn);
                }
            }
        }

        @Override
        protected void update(InstanceIdentifier<Vrfs> iid,
                              Vrfs oldval, Vrfs newval) {
            if (ignoreClusterDcnEventForFollower()) {
                return;
            }
            LOG.debug("VRFS: Update getting triggered for VRFS rd {}", oldval.getRd());
            LOG.error(yangObj + updWarn);
        }

        @Override
        public void close() {
            try {
                super.close();
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    Future lastCleanupJob;
    Future lastReplayJobFt = null;
    protected void activateMIP() {
        try {
            LOG.trace("BgpReactor: Executing MIP Activate command");
            Process process_bgp = Runtime.getRuntime().exec("cluster ip -a sdnc_bgp_mip");
            Process process_os = Runtime.getRuntime().exec("cluster ip -a sdnc_os_mip");
            LOG.trace("bgpMIP Activated");

        } catch (IOException io) {
            //LOG.error("IO Exception got while activating mip:  ", io);
        } catch (Exception e) {
            //LOG.error("Exception got while activating mip: ", e);
        }
    }

    AtomicBoolean started = new AtomicBoolean(false);

    public class BgpReactor
            extends AsyncDataTreeChangeListenerBase<Bgp, BgpReactor>
            implements AutoCloseable, ClusteredDataTreeChangeListener<Bgp> {

        private static final String yangObj = "Bgp ";

        public BgpReactor() {
            super(Bgp.class, BgpReactor.class);
        }


        @Override
        protected synchronized void
        add(InstanceIdentifier<Bgp> iid, Bgp val) {
            LOG.error("received add Bgp config replaying the config");

            try {
                initer.await();
            } catch (Exception e) {
            }
            synchronized (BgpConfigurationManager.this) {
                config = val;
                if (ignoreClusterDcnEventForFollower()) {
                    return;
                }
                activateMIP();
                if (isIpAvailable(odlThriftIp)) {
                    bgpRestarted();
                } else {
                    ipActivationCheckTimer.scheduleAtFixedRate(new TimerTask() {
                        @Override
                        public void run() {
                            if (isIpAvailable(odlThriftIp)) {
                                bgpRestarted();
                                ipActivationCheckTimer.cancel();
                            } else {
                                LOG.trace("waiting for odlThriftIP: {} to be present", odlThriftIp);
                            }
                        }
                    }, 10000L, 10000L);
                }
            }
        }

        @Override
        protected BgpReactor getDataTreeChangeListener() {
            return BgpReactor.this;
        }

        @Override
        protected InstanceIdentifier<Bgp> getWildCardPath() {
            return InstanceIdentifier.create(Bgp.class);
        }

        @Override
        protected synchronized void
        remove(InstanceIdentifier<Bgp> iid, Bgp val) {
            if (ignoreClusterDcnEventForFollower()) {
                return;
            }
            LOG.debug("received remove Bgp config");
            synchronized (BgpConfigurationManager.this) {
                config = null;
            }
        }

        @Override
        protected void update(InstanceIdentifier<Bgp> iid,
                              Bgp oldval, Bgp newval) {
            if (ignoreClusterDcnEventForFollower()) {
                return;
            }
            synchronized (BgpConfigurationManager.this) {
                config = newval;
            }
        }

        @Override
        public void close() {
            try {
                super.close();
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    public String readThriftIpForCommunication( String mipAddr) {
        File f = new File(CLUSTER_CONF_FILE);
        if (!f.exists()) {
            return  DEF_CHOST;
        }
        BufferedReader br = null;
        try {
            br = new BufferedReader(new InputStreamReader(
                    new FileInputStream(f)));
            String line = br.readLine();
            while (line != null) {
                if (line.contains(mipAddr)) {
                    line = line.trim();
                    return line.substring(line.lastIndexOf(" ") + 1);
                }
                line = br.readLine();
            }
        } catch (Exception e) {
        } finally {
            try {
                br.close();
            } catch (Exception ignore) {
            }
        }
        return DEF_CHOST;
    }

    public boolean isIpAvailable(String odlip) {

        try {
            if (odlip != null) {
                if ("127.0.0.1".equals(odlip)) {
                    return true;
                }
                Enumeration e = NetworkInterface.getNetworkInterfaces();
                while (e.hasMoreElements()) {
                    NetworkInterface n = (NetworkInterface) e.nextElement();
                    Enumeration ee = n.getInetAddresses();
                    while (ee.hasMoreElements()) {
                        InetAddress i = (InetAddress) ee.nextElement();
                        if (odlip.equals(i.getHostAddress())) {
                            return true;
                        }
                        ;
                    }
                }
            }
        } catch (Exception e) {
        }
        return false;
    }

    public static long getStalePathtime(int defValue, AsId as_num) {
        long spt = 0;
        try {
            spt = getConfig().getGracefulRestart().getStalepathTime();
        } catch (Exception e) {
            try {
                spt = as_num.getStalepathTime();
                LOG.trace("BGP config/Stale-path time is not set using graceful");
            } catch (Exception ignore) {
                LOG.trace("BGP AS id is not set using graceful");
                spt = defValue;
            }
        }
        if (spt == 0) {
            LOG.trace("BGP config/Stale-path time is not set using graceful/start-bgp");
            spt = defValue;
        }
        return spt;
    }

    public synchronized void bgpRestarted() {
        /*
         * If there a thread which in the process of stale cleanup, cancel it
         * and start a new thread (to avoid processing same again).
         */
        if (previousReplayJobInProgress()) {
            cancelPreviousReplayJob();
        }
        Runnable task = new Runnable() {
            @Override
            public void run() {
                try {
                    LOG.info("running bgp replay task ");
                    if (get() == null) {
                        String host = getConfigHost();
                        int port = getConfigPort();
                        LOG.info("connecting  to bgp host {} ", host);

                        boolean res = bgpRouter.connect(host, port);
                        LOG.info("no config to push in bgp replay task ");
                        return;
                    }
                    setStaleStartTime(System.currentTimeMillis());
                    LOG.info("started creating stale fibDSWriter  map ");
                    createStaleFibMap();
                    setStaleEndTime(System.currentTimeMillis());
                    LOG.info("took {} msecs for stale fibDSWriter map creation ", getStaleEndTime()- getStaleStartTime());
                    LOG.info("started bgp config replay ");
                    setCfgReplayStartTime(System.currentTimeMillis());
                    replay();
                    setCfgReplayEndTime(System.currentTimeMillis());
                    LOG.info("took {} msecs for bgp replay ", getCfgReplayEndTime() - getCfgReplayStartTime());
                    long route_sync_time = getStalePathtime(BGP_RESTART_ROUTE_SYNC_SEC, config.getAsId());
                    Thread.sleep(route_sync_time * 1000L);
                    setStaleCleanupTime(route_sync_time);
                    new RouteCleanup().call();
                } catch (Exception eCancel) {
                    LOG.error("Stale Cleanup Task Cancelled", eCancel);
                }
            }
        };
        lastReplayJobFt = executor.submit(task);
    }

    private boolean previousReplayJobInProgress() {
        return lastReplayJobFt != null && !lastReplayJobFt.isDone();
    }

    private void cancelPreviousReplayJob() {
        try {
            LOG.error("cancelling already running bgp replay task");
            lastReplayJobFt.cancel(true);
            lastReplayJobFt = null;
            Thread.sleep(2000);
        } catch (Throwable e) {
            LOG.error("Failed to cancel previous replay job ",e);
        }
    }

    private static void doRouteSync() throws InterruptedException, ExecutionException, TimeoutException {
        BgpSyncHandle bsh = BgpSyncHandle.getInstance();
        LOG.error("Starting BGP route sync");
        try {
            bgpRouter.initRibSync(bsh);
        } catch (Exception e) {
            LOG.error("Route sync aborted, exception when initializing: " + e);
            return;
        }
        while (bsh.getState() != bsh.DONE) {
            Routes routes = null;
            try {
                routes = bgpRouter.doRibSync(bsh);
            } catch (Exception e) {
                LOG.error("Route sync aborted, exception when syncing: " + e);
                return;
            }
            Iterator<Update> updates = routes.getUpdatesIterator();
            while (updates.hasNext()) {
                Update u = updates.next();
                Map<String, Map<String, String>> stale_fib_rd_map = BgpConfigurationManager.getStaledFibEntriesMap();
                String rd = u.getRd();
                String nexthop = u.getNexthop();

                // TODO: decide correct label here
                int label = u.getL3label();

                String prefix = u.getPrefix();
                int plen = u.getPrefixlen();


                // TODO: protocol type will not be available in "update"
                // use "rd" to query vrf table and obtain the protocol_type. Currently using PROTOCOL_EVPN as default.
                onUpdatePushRoute(
                        protocol_type.PROTOCOL_EVPN,
                        rd,
                        prefix,
                        plen,
                        nexthop,
                        u.getEthtag(),
                        u.getEsi(),
                        u.getMacaddress(),
                        label,
                        u.getRoutermac()
                );

            }
        }
        try {
            LOG.error("Ending BGP route-sync");
            bgpRouter.endRibSync(bsh);
        } catch (Exception e) {
        }
    }

    /* onUpdatePushRoute
     * Get Stale fibDSWriter map, and compare current route/fibDSWriter entry.
     *  - Entry compare shall include NextHop, Label.
     *  - If entry matches: delete from STALE Map. NO Change to FIB Config DS.
     *  - If entry not found, add to FIB Config DS.
     *  - If entry found, but either Label/NextHop doesn't match.
     *      - Update FIB Config DS with modified values.
     *      - delete from Stale Map.
     */

    public static void onUpdatePushRoute(protocol_type protocolType,
                                         String rd,
                                         String prefix,
                                         int plen,
                                         String nextHop,
                                         int ethtag,
                                         String esi,
                                         String macaddress,
                                         int label,
                                         String routermac) throws InterruptedException, ExecutionException, TimeoutException {
        Map<String, Map<String, String>> stale_fib_rd_map = BgpConfigurationManager.getStaledFibEntriesMap();
        boolean addroute = false;
        long l3vni = 0L;
        VrfEntry.EncapType encapType = VrfEntry.EncapType.Mplsgre;
        if (protocolType.equals(protocol_type.PROTOCOL_EVPN)) {
            encapType = VrfEntry.EncapType.Vxlan;
            VpnInstanceOpDataEntry vpnInstanceOpDataEntry = BgpUtil.getVpnInstanceOpData(dataBroker, rd);
            if (vpnInstanceOpDataEntry != null) {
                l3vni = vpnInstanceOpDataEntry.getL3vni();
            } else {
                LOG.error("No corresponding vpn instance found for rd {}. Aborting.", rd);
                return;
            }
        }
        if (!stale_fib_rd_map.isEmpty()) {
            // restart Scenario, as MAP is not empty.
            Map<String, String> map = stale_fib_rd_map.get(rd);
            if (map != null) {
                String nexthoplabel = map.get(prefix + "/" + plen);
                if (null == nexthoplabel) {
                    // New Entry, which happened to be added during restart.
                    addroute = true;
                } else {
                    map.remove(prefix + "/" + plen);
                    if (isRouteModified(nextHop, label, nexthoplabel)) {
                        LOG.debug("Route add ** {} ** {}/{} ** {} ** {} ", rd, prefix, plen, nextHop, label);
                        // Existing entry, where in Nexthop/Label got modified during restart
                        addroute = true;
                    }
                }
            }
        } else {
            LOG.debug("Route add ** {} ** {}/{} ** {} ** {} ", rd, prefix, plen, nextHop, label);
            addroute = true;
        }
        if (addroute) {
            LOG.info("ADD: Adding Fib entry rd {} prefix {} nexthop {} label {}", rd, prefix, nextHop, label);
            // TODO: modify addFibEntryToDS signature
            fibDSWriter.addFibEntryToDS(rd, macaddress, prefix + "/" + plen, Arrays.asList(nextHop),
                    encapType, label, l3vni, routermac, RouteOrigin.BGP);
            LOG.info("ADD: Added Fib entry rd {} prefix {} nexthop {} label {}", rd, prefix, nextHop, label);
        }
    }

    private static boolean isRouteModified(String nexthop, int label, String nexthoplabel) {
        return !nexthoplabel.isEmpty() && !nexthoplabel.equals(nexthop + "/" + label);
    }

    static private void replayNbrConfig(List<Neighbors> n, BgpRouter br) {
        for (Neighbors nbr : n) {
            try {
                br.addNeighbor(nbr.getAddress().getValue(),
                        nbr.getRemoteAs().longValue());
                //itmProvider.buildTunnelsToDCGW(new IpAddress(nbr.getAddress().getValue().toCharArray()));
            } catch (Exception e) {
                LOG.error("Replay:addNbr() received exception: \"" + e + "\"");
                continue;
            }
            EbgpMultihop en = nbr.getEbgpMultihop();
            if (en != null) {
                try {
                    br.addEbgpMultihop(en.getPeerIp().getValue(),
                            en.getNhops().intValue());
                } catch (Exception e) {
                    LOG.error("Replay:addEBgp() received exception: \"" + e + "\"");
                }
            }
            UpdateSource us = nbr.getUpdateSource();
            if (us != null) {
                try {
                    br.addUpdateSource(us.getPeerIp().getValue(),
                            us.getSourceIp().getValue());
                } catch (Exception e) {
                    LOG.error("Replay:addUS() received exception: \"" + e + "\"");
                }
            }
            List<AddressFamilies> afs = nbr.getAddressFamilies();
            if (afs != null) {
                for (AddressFamilies af : afs) {
                    af_afi afi = af_afi.findByValue(af.getAfi().intValue());
                    af_safi safi = af_safi.findByValue(af.getSafi().intValue());
                    try {
                        br.addAddressFamily(af.getPeerIp().getValue(), afi, safi);
                    } catch (Exception e) {
                        LOG.error("Replay:addAf() received exception: \"" + e + "\"");
                    }
                }
            }
        }
    }

    public static String getConfigHost() {
        if (config == null) {
            return cHostStartup;
        }
        ConfigServer ts = config.getConfigServer();
        return (ts == null ? cHostStartup : ts.getHost().getValue());
    }

    public static int getConfigPort() {
        if (config == null) {
            return Integer.parseInt(cPortStartup);
        }
        ConfigServer ts = config.getConfigServer();
        return (ts == null ? Integer.parseInt(cPortStartup) :
                ts.getPort().intValue());
    }

    public static Bgp getConfig() {
        AtomicInteger bgpDSretryCount = new AtomicInteger(dsRetryCoount);
        while (0  != bgpDSretryCount.decrementAndGet()) {
            try {
                Optional<Bgp> optional = BgpUtil.read(dataBroker,
                                         LogicalDatastoreType.CONFIGURATION, InstanceIdentifier.create(Bgp.class));
                if (optional.isPresent()) {
                    return optional.get();
                } else {
                    return null;
                }
            } catch (Exception e) {
                //Config DS may not be up, so sleep for 1 second and retry
                LOG.debug("failed to get bgp config, may be DS is yet in consistent state(?)", e);
                try {
                    Thread.sleep(waitTimeBetweenEachTryMillis);
                }catch (Exception timerEx){
                    LOG.debug("waitTimeBetweenEachTryMillis, Timer got interrupted while waiting for" +
                            "config DS availability", timerEx);
                }
            }
         }
         LOG.error("failed to get bgp config");
         return null;
     }

    public synchronized void replay() throws InterruptedException, ExecutionException, TimeoutException {
        synchronized (bgpConfigurationManager) {
            String host = getConfigHost();
            int port = getConfigPort();
            LOG.error("connecting  to bgp host {} ", host);

            boolean res = bgpRouter.connect(host, port);
            if (!res) {
                String msg = "Cannot connect to BGP config server at " + host + ":" + port;
                if (config != null) {
                    msg += "; Configuration Replay aborted";
                }
                LOG.error(msg);
                return;
            }
            config = getConfig();
            if (config == null) {
                LOG.error("bgp config is empty nothing to push to bgp");
                return;
            }
            BgpRouter br = bgpRouter;
            AsId a = config.getAsId();
            if (a == null) {
                return;
            }
            long asNum = a.getLocalAs().longValue();
            Ipv4Address routerId = a.getRouterId();
            Long spt = a.getStalepathTime();
            Boolean afb = a.isAnnounceFbit();
            String rid = (routerId == null) ? "" : routerId.getValue();
            int stalepathTime = (int) getStalePathtime(0, config.getAsId());
            boolean announceFbit = true;
            try {
                br.startBgp(asNum, rid, stalepathTime, announceFbit);
            } catch (BgpRouterException bre) {
                if (bre.getErrorCode() == BgpRouterException.BGP_ERR_ACTIVE) {
                    doRouteSync();
                } else {
                    LOG.error("Replay: startBgp() received exception: \""
                            + bre + "\"; " + addWarn);
                }
            } catch (Exception e) {
                //not unusual. We may have restarted & BGP is already on
                LOG.error("Replay:startBgp() received exception: \"" + e + "\"");
            }

            if (getBgpCounters() == null) {
                startBgpCountersTask();
            }

            if (getBgpAlarms() == null) {
                startBgpAlarmsTask();
            }

            Logging l = config.getLogging();
            if (l != null) {
                try {
                    br.setLogging(l.getFile(), l.getLevel());
                } catch (Exception e) {
                    LOG.error("Replay:setLogging() received exception: \"" + e + "\"");
                }
            }

            GracefulRestart g = config.getGracefulRestart();
            if (g != null) {
                try {
                    br.addGracefulRestart(g.getStalepathTime().intValue());
                } catch (Exception e) {
                    LOG.error("Replay:addGr() received exception: \"" + e + "\"");
                }
            }

            List<Vrfs> v = config.getVrfs();
            if (v != null) {
                for (Vrfs vrf : v) {
                    try {
                        br.addVrf(vrf.getLayerType(), vrf.getRd(), vrf.getImportRts(),
                                vrf.getExportRts());
                    } catch (Exception e) {
                        LOG.error("Replay:addVrf() received exception: \"" + e + "\"");
                    }
                }
            }

            List<Networks> ln = config.getNetworks();
            if (ln != null) {
                for (Networks net : ln) {
                    String rd = net.getRd();
                    String pfxlen = net.getPrefixLen();
                    String nh = net.getNexthop().getValue();
                    Long label = net.getLabel();
                    int lbl = (label == null) ? 0 : label.intValue();
                    int l3vni = (net.getL3vni() == null) ? 0 : net.getL3vni().intValue();
                    if (rd == null && lbl > 0) {
                        //LU prefix is being deleted.
                        rd = Integer.toString(lbl);
                    }

                    ProtocolType protocolType = net.getProtocolType();
                    int ethernetTag = net.getEthtag().intValue();
                    String esi = net.getEsi();
                    String macaddress = net.getMacaddress();
                    EncapType encapType = net.getEncapType();
                    String routerMac = net.getRoutermac();

                    try {
                        br.addPrefix(rd, pfxlen, nh, lbl, l3vni, BgpUtil.convertToThriftProtocolType(protocolType), ethernetTag, esi, macaddress, BgpUtil.convertToThriftEncapType(encapType), routerMac);
                    } catch (Exception e) {
                        LOG.error("Replay:addPfx() received exception: \"" + e + "\"");
                    }
                }
            }
            List<Neighbors> n = config.getNeighbors();
            if (n != null) {
                LOG.error("configuring existing Neighbors present for replay total neighbors {}", n.size());
                replayNbrConfig(n, br);
            } else {
                LOG.error("no Neighbors present for replay config ");
            }
        }
    }

    private <T extends DataObject> void update(InstanceIdentifier<T> iid, T dto) {
        BgpUtil.update(dataBroker, LogicalDatastoreType.CONFIGURATION, iid, dto);
    }

    private <T extends DataObject> void asyncWrite(InstanceIdentifier<T> iid, T dto) {
        BgpUtil.write(dataBroker, LogicalDatastoreType.CONFIGURATION, iid, dto);
    }

    private <T extends DataObject> void delete(InstanceIdentifier<T> iid) {
        BgpUtil.delete(dataBroker, LogicalDatastoreType.CONFIGURATION, iid);
    }

    public synchronized void
    startConfig(String bgpHost, int thriftPort) {
        InstanceIdentifier.InstanceIdentifierBuilder<ConfigServer> iib =
                InstanceIdentifier.builder(Bgp.class).child(ConfigServer.class);
        InstanceIdentifier<ConfigServer> iid = iib.build();
        Ipv4Address ipAddr = new Ipv4Address(bgpHost);
        ConfigServer dto = new ConfigServerBuilder().setHost(ipAddr)
                .setPort((long) thriftPort).build();
        update(iid, dto);
    }

    public synchronized void
    startBgp(long as, String routerId, int spt, boolean fbit) {
        Ipv4Address rid = (routerId == null) ?
                null : new Ipv4Address(routerId);
        Long staleTime = (long) spt;
        InstanceIdentifier.InstanceIdentifierBuilder<AsId> iib =
                InstanceIdentifier.builder(Bgp.class).child(AsId.class);
        InstanceIdentifier<AsId> iid = iib.build();
        AsId dto = new AsIdBuilder().setLocalAs(as)
                .setRouterId(rid)
                .setStalepathTime(staleTime)
                .setAnnounceFbit(fbit).build();
        update(iid, dto);
    }

    public synchronized void
    addLogging(String fileName, String logLevel) {
        InstanceIdentifier.InstanceIdentifierBuilder<Logging> iib =
                InstanceIdentifier.builder(Bgp.class).child(Logging.class);
        InstanceIdentifier<Logging> iid = iib.build();
        Logging dto = new LoggingBuilder().setFile(fileName)
                .setLevel(logLevel).build();
        update(iid, dto);
    }

    public synchronized void
    addGracefulRestart(int staleTime) {
        InstanceIdentifier.InstanceIdentifierBuilder<GracefulRestart> iib =
                InstanceIdentifier.builder(Bgp.class).child(GracefulRestart.class);
        InstanceIdentifier<GracefulRestart> iid = iib.build();
        GracefulRestart dto = new GracefulRestartBuilder()
                .setStalepathTime((long) staleTime).build();
        update(iid, dto);
    }

    public synchronized void
    addNeighbor(String nbrIp, long remoteAs) {
        Ipv4Address nbrAddr = new Ipv4Address(nbrIp);
        InstanceIdentifier.InstanceIdentifierBuilder<Neighbors> iib =
                InstanceIdentifier.builder(Bgp.class)
                        .child(Neighbors.class, new NeighborsKey(nbrAddr));
        InstanceIdentifier<Neighbors> iid = iib.build();
        Neighbors dto = new NeighborsBuilder().setAddress(nbrAddr)
                .setRemoteAs(remoteAs).build();
        update(iid, dto);
    }

    public synchronized void
    addUpdateSource(String nbrIp, String srcIp) {
        Ipv4Address nbrAddr = new Ipv4Address(nbrIp);
        Ipv4Address srcAddr = new Ipv4Address(srcIp);
        InstanceIdentifier.InstanceIdentifierBuilder<UpdateSource> iib =
                InstanceIdentifier.builder(Bgp.class)
                        .child(Neighbors.class, new NeighborsKey(nbrAddr))
                        .child(UpdateSource.class);
        InstanceIdentifier<UpdateSource> iid = iib.build();
        UpdateSource dto = new UpdateSourceBuilder().setPeerIp(nbrAddr)
                .setSourceIp(srcAddr).build();
        update(iid, dto);
    }

    public synchronized void
    addEbgpMultihop(String nbrIp, int nHops) {
        Ipv4Address nbrAddr = new Ipv4Address(nbrIp);
        InstanceIdentifier.InstanceIdentifierBuilder<EbgpMultihop> iib =
                InstanceIdentifier.builder(Bgp.class)
                        .child(Neighbors.class, new NeighborsKey(nbrAddr))
                        .child(EbgpMultihop.class);
        InstanceIdentifier<EbgpMultihop> iid = iib.build();
        EbgpMultihop dto = new EbgpMultihopBuilder().setPeerIp(nbrAddr)
                .setNhops((long) nHops).build();
        update(iid, dto);
    }

    public synchronized void
    addAddressFamily(String nbrIp, int afi, int safi) {
        Ipv4Address nbrAddr = new Ipv4Address(nbrIp);
        Long a = (long) afi;
        Long sa = (long) safi;
        InstanceIdentifier.InstanceIdentifierBuilder<AddressFamilies> iib =
                InstanceIdentifier.builder(Bgp.class)
                        .child(Neighbors.class, new NeighborsKey(nbrAddr))
                        .child(AddressFamilies.class, new AddressFamiliesKey(a, sa));
        InstanceIdentifier<AddressFamilies> iid = iib.build();
        AddressFamilies dto = new AddressFamiliesBuilder().setPeerIp(nbrAddr)
                .setAfi(a).setSafi(sa).build();
        update(iid, dto);
    }

    public synchronized void
    addPrefix(String rd, String macAddress, String pfx, List<String> nhList,
              VrfEntry.EncapType encapType, int lbl, long l3vni, String gatewayMac) {
        for (String nh : nhList) {
            Ipv4Address nexthop = new Ipv4Address(nh);
            Long label = (long) lbl;
            InstanceIdentifier<Networks> iid = InstanceIdentifier.builder(Bgp.class)
                    .child(Networks.class, new NetworksKey(pfx, rd)).build();
            NetworksBuilder networksBuilder = new NetworksBuilder().setRd(rd).setPrefixLen(pfx).setNexthop(nexthop)
                                                .setLabel(label).setEthtag(BgpConstants.DEFAULT_ETH_TAG);
            buildVpnEncapSpecificInfo(networksBuilder, encapType, label, l3vni, macAddress, gatewayMac);
            update(iid, networksBuilder.build());
        }
    }

    private static void buildVpnEncapSpecificInfo(NetworksBuilder builder, VrfEntry.EncapType encapType, long label,
                                                  long l3vni, String macAddress, String gatewayMac) {
        if (encapType.equals(VrfEntry.EncapType.Mplsgre)) {
            builder.setLabel(label).setProtocolType(ProtocolType.PROTOCOLL3VPN).setEncapType(EncapType.GRE);
        } else {
            builder.setL3vni(l3vni).setMacaddress(macAddress).setRoutermac(gatewayMac)
                    .setProtocolType(ProtocolType.PROTOCOLEVPN).setEncapType(EncapType.VXLAN);
        }
    }

    // TODO: add LayerType as arg - supports command
    public synchronized void
    addVrf(String rd, List<String> irts, List<String> erts) {
        InstanceIdentifier.InstanceIdentifierBuilder<Vrfs> iib =
                InstanceIdentifier.builder(Bgp.class)
                        .child(Vrfs.class, new VrfsKey(rd));
        InstanceIdentifier<Vrfs> iid = iib.build();
        Vrfs dto = new VrfsBuilder().setRd(rd)
                .setImportRts(irts)
                .setExportRts(erts).build();
        BgpUtil.syncWrite(dataBroker, LogicalDatastoreType.CONFIGURATION, iid, dto);
    }

    public synchronized void stopConfig() {
        InstanceIdentifier.InstanceIdentifierBuilder<ConfigServer> iib =
                InstanceIdentifier.builder(Bgp.class).child(ConfigServer.class);
        InstanceIdentifier<ConfigServer> iid = iib.build();
        delete(iid);
    }

    public synchronized void stopBgp() {
        InstanceIdentifier.InstanceIdentifierBuilder<AsId> iib =
                InstanceIdentifier.builder(Bgp.class).child(AsId.class);
        InstanceIdentifier<AsId> iid = iib.build();
        delete(iid);
    }

    public synchronized void delLogging() {
        InstanceIdentifier.InstanceIdentifierBuilder<Logging> iib =
                InstanceIdentifier.builder(Bgp.class).child(Logging.class);
        InstanceIdentifier<Logging> iid = iib.build();
        delete(iid);
    }

    public synchronized void delGracefulRestart() {
        InstanceIdentifier.InstanceIdentifierBuilder<GracefulRestart> iib =
                InstanceIdentifier.builder(Bgp.class)
                        .child(GracefulRestart.class);
        InstanceIdentifier<GracefulRestart> iid = iib.build();
        delete(iid);
    }

    public synchronized void delNeighbor(String nbrIp) {
        Ipv4Address nbrAddr = new Ipv4Address(nbrIp);
        InstanceIdentifier.InstanceIdentifierBuilder<Neighbors> iib =
                InstanceIdentifier.builder(Bgp.class)
                        .child(Neighbors.class, new NeighborsKey(nbrAddr));
        InstanceIdentifier<Neighbors> iid = iib.build();
        delete(iid);
    }

    public synchronized void delUpdateSource(String nbrIp) {
        Ipv4Address nbrAddr = new Ipv4Address(nbrIp);
        InstanceIdentifier.InstanceIdentifierBuilder<UpdateSource> iib =
                InstanceIdentifier.builder(Bgp.class)
                        .child(Neighbors.class, new NeighborsKey(nbrAddr))
                        .child(UpdateSource.class);
        InstanceIdentifier<UpdateSource> iid = iib.build();
        delete(iid);
    }

    public synchronized void delEbgpMultihop(String nbrIp) {
        Ipv4Address nbrAddr = new Ipv4Address(nbrIp);
        InstanceIdentifier.InstanceIdentifierBuilder<EbgpMultihop> iib =
                InstanceIdentifier.builder(Bgp.class)
                        .child(Neighbors.class, new NeighborsKey(nbrAddr))
                        .child(EbgpMultihop.class);
        InstanceIdentifier<EbgpMultihop> iid = iib.build();
        delete(iid);
    }

    public synchronized void
    delAddressFamily(String nbrIp, int afi, int safi) {
        Ipv4Address nbrAddr = new Ipv4Address(nbrIp);
        Long a = (long) afi;
        Long sa = (long) safi;
        InstanceIdentifier.InstanceIdentifierBuilder<AddressFamilies> iib =
                InstanceIdentifier.builder(Bgp.class)
                        .child(Neighbors.class, new NeighborsKey(nbrAddr))
                        .child(AddressFamilies.class, new AddressFamiliesKey(a, sa));
        InstanceIdentifier<AddressFamilies> iid = iib.build();
        delete(iid);
    }

    public synchronized void delPrefix(String rd, String pfx) {
        InstanceIdentifier.InstanceIdentifierBuilder<Networks> iib =
                InstanceIdentifier.builder(Bgp.class)
                        .child(Networks.class, new NetworksKey(pfx, rd));
        InstanceIdentifier<Networks> iid = iib.build();
        delete(iid);
    }

    public synchronized void delVrf(String rd) {
        InstanceIdentifier.InstanceIdentifierBuilder<Vrfs> iib =
                InstanceIdentifier.builder(Bgp.class)
                        .child(Vrfs.class, new VrfsKey(rd));
        InstanceIdentifier<Vrfs> iid = iib.build();
        delete(iid);
    }

    static ScheduledExecutorService executor = Executors.newScheduledThreadPool(1);

    /*
    * Remove Stale Marked Routes after timer expiry.
    */
    class RouteCleanup implements Callable<Integer> {

        @Override
        public Integer call() {
            totalCleared = 0;
            try {
                if (staledFibEntriesMap.isEmpty()) {
                    LOG.info("BGP: RouteCleanup timertask tirggered but STALED FIB MAP is EMPTY");
                } else {
                    for (String rd : staledFibEntriesMap.keySet()) {
                        if (Thread.interrupted()) {
                            return 0;
                        }
                        Map<String, String> map = staledFibEntriesMap.get(rd);
                        if (map != null) {
                            for (String prefix : map.keySet()) {
                                if (Thread.interrupted()) {
                                    return 0;
                                }
                                try {
                                    totalCleared++;
                                    LOG.debug("BGP: RouteCleanup deletePrefix called for : rd:{}, prefix{}" + rd.toString() + prefix);
                                    fibDSWriter.removeFibEntryFromDS(rd, prefix);
                                } catch (Exception e) {
                                    LOG.error("BGP: RouteCleanup deletePrefix failed rd:{}, prefix{}" + rd.toString() + prefix);
                                }
                            }
                        }
                    }
                }
            } catch (Exception e) {
                LOG.error("Cleanup Thread Got interrupted, Failed to cleanup stale routes ", e);
            } finally {
                staledFibEntriesMap.clear();
            }
            LOG.error("cleared {} stale routes after bgp restart", totalCleared);
            return 0;
        }
    }

    /*
     * BGP restart scenario, ODL-BGP manager was/is running.
     * On re-sync notification, Get a copy of FIB database.
     */
    public static void createStaleFibMap() {
        totalStaledCount = 0;
        try {
            /*
            * at the time Stale FIB creation, Wait till all PENDING write transaction
             * to complete (or)wait for max timeout value of STALE_FIB_WAIT Seconds.
             */
            int retry = STALE_FIB_WAIT;
            while ((BgpUtil.getGetPendingWrTransaction() != 0) && (retry > 0)) {
                Thread.sleep(1000);
                retry--;
                if (retry == 0) {
                    LOG.error("TimeOut occured {} seconds, in waiting stale fibDSWriter create", STALE_FIB_WAIT);
                }
            }
            staledFibEntriesMap.clear();
            InstanceIdentifier<FibEntries> id = InstanceIdentifier.create(FibEntries.class);
            DataBroker db = BgpUtil.getBroker();
            if (db == null) {
                LOG.error("Couldn't find BgpUtil dataBroker while creating createStaleFibMap");
                return;
            }

            Optional<FibEntries> fibEntries = BgpUtil.read(BgpUtil.getBroker(),
                    LogicalDatastoreType.CONFIGURATION, id);
            if (fibEntries.isPresent()) {
                List<VrfTables> stale_vrfTables = fibEntries.get().getVrfTables();
                for (VrfTables vrfTable : stale_vrfTables) {
                    Map<String, String> stale_fib_ent_map = new HashMap<>();
                    for (VrfEntry vrfEntry : vrfTable.getVrfEntry()) {
                        if (RouteOrigin.value(vrfEntry.getOrigin()) != RouteOrigin.BGP) {
                            //Stale marking and cleanup is only meant for the routes learned through BGP.
                            continue;
                        }
                        if (Thread.interrupted()) {
                            break;
                        }
                        totalStaledCount++;
                        //Create MAP from stale_vrfTables.
                        for (String nextHop : vrfEntry.getNextHopAddressList()) {
                            stale_fib_ent_map.put(vrfEntry.getDestPrefix(), nextHop + "/" + vrfEntry.getLabel());
                        }
                    }
                    staledFibEntriesMap.put(vrfTable.getRouteDistinguisher(), stale_fib_ent_map);
                }
            } else {
                LOG.error("createStaleFibMap:: FIBentries.class is not present");
            }
        } catch (Exception e) {
            LOG.error("createStaleFibMap:: error ", e);
        }
        LOG.error("created {} staled entries ", totalStaledCount);
    }

    //map<rd, map<prefix/len, nexthop/label>>
    public static Map<String, Map<String, String>> getStaledFibEntriesMap() {
        return staledFibEntriesMap;
    }

    //TODO: below function is for testing purpose with cli
    public static void onUpdateWithdrawRoute(String rd, String prefix, int plen, String nexthop) {
        LOG.debug("Route del ** {} ** {}/{} ", rd, prefix, plen);
        try {
            fibDSWriter.removeFibEntryFromDS(rd, prefix + "/" + plen);
        } catch (Throwable e) {
            LOG.error("failed to handle withdraw route ", e);
        }
    }
    public boolean isBgpConnected(){
        return bgpRouter.isBgpConnected();
    }
    public long getLastConnectedTS() {
        return bgpRouter.getLastConnectedTS();
    }
    public long getConnectTS() {
        return bgpRouter.getConnectTS();
    }
    public long getStartTS() {
        return bgpRouter.getStartTS();
    }
    public static int getTotalStaledCount() {return totalStaledCount;}
    public static int getTotalCleared() { return totalCleared;}

    public Timer getBgpCountersTimer() {
        return bgpCountersTimer;
    }

    public BgpCounters getBgpCounters() {
        return bgpCounters;
    }

    public  void setBgpCountersTimer (Timer t) {
        bgpCountersTimer = t;
    }
    public  void setBgpAlarmsTimer (Timer t) {
        bgpAlarmsTimer = t;
    }

    public void startBgpCountersTask() {
        if (getBgpCounters() == null) {

            try {
                bgpCounters = new BgpCounters(bgpConfigurationManager.getBgpSdncMipIp());
                setBgpCountersTimer(new Timer(true));
                getBgpCountersTimer().scheduleAtFixedRate(bgpCounters, 0, 120 * 1000);


                LOG.info("Bgp Counters task scheduled for every two minutes.");
            } catch (Exception e) {
                System.out.println("Could not start the timertask for Bgp Counters.");
                e.printStackTrace();
            }

            try {
                bgpManager.setQbgpLog(BgpConstants.BGP_DEF_LOG_FILE, BgpConstants.BGP_DEF_LOG_LEVEL);
            } catch (Exception e) {
                System.out.println("Could not set the default options for logging");
            }
        }
    }

    public void stopBgpCountersTask() {
        Timer t = getBgpCountersTimer();
        if (getBgpCounters() != null) {
            t.cancel();
            setBgpCountersTimer(null);
            bgpCounters = null;
        }
    }
    public void startBgpAlarmsTask() {
        if (getBgpAlarms() == null) {
            try {
                bgpAlarms = new BgpAlarms(this);
                setBgpAlarmsTimer(new Timer(true));
                getBgpAlarmsTimer().scheduleAtFixedRate(bgpAlarms, 0, 60 * 1000);
                LOG.info("Bgp Alarms task scheduled for every minute.");
            } catch (Exception e) {
                System.out.println("Could not start the timertask for Bgp Alarms.");
                e.printStackTrace();
            }
        }
    }

    public void stopBgpAlarmsTask() {
        Timer t = getBgpAlarmsTimer();
        if (getBgpAlarms() != null) {
            t.cancel();
            setBgpAlarmsTimer(null);
            bgpAlarms = null;
        }
    }
    public Timer getBgpAlarmsTimer() {
        return bgpAlarmsTimer;
    }

    public BgpAlarms getBgpAlarms() {
        return bgpAlarms;
    }

}

