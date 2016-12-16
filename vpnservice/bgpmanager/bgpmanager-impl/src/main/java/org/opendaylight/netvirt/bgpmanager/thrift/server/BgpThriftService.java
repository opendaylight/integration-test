/*
 * Copyright (c) 2015 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.bgpmanager.thrift.server;

import java.util.List;
import org.apache.thrift.protocol.TBinaryProtocol;
import org.apache.thrift.protocol.TProtocol;
import org.apache.thrift.server.ServerContext;
import org.apache.thrift.server.TServer;
import org.apache.thrift.server.TServerEventHandler;
import org.apache.thrift.server.TThreadedSelectorServer;
import org.apache.thrift.transport.TFramedTransport;
import org.apache.thrift.transport.TNonblockingServerSocket;
import org.apache.thrift.transport.TNonblockingServerTransport;
import org.apache.thrift.transport.TTransport;
import org.opendaylight.netvirt.bgpmanager.BgpConfigurationManager;
import org.opendaylight.netvirt.bgpmanager.FibDSWriter;
import org.opendaylight.netvirt.bgpmanager.api.IBgpManager;
import org.opendaylight.netvirt.bgpmanager.thrift.gen.BgpUpdater;
import org.opendaylight.netvirt.bgpmanager.thrift.gen.protocol_type;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.fibmanager.rev150330.fibentries.VrfTables;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class BgpThriftService {
    int ourPort;
    IBgpManager bgpManager;
    FibDSWriter fibDSWriter;
    TServer server;

    // to store copy fo FIB-VRF tables on QBGP restart.
    public List<VrfTables> stale_vrfTables;

    private static final Logger LOGGER = LoggerFactory.getLogger(BgpThriftService.class);

    public BgpThriftService(int ourPort, IBgpManager bm, FibDSWriter fibDSWriter) {
        this.ourPort = ourPort;
        bgpManager = bm;
        this.fibDSWriter = fibDSWriter;
    }

    public static class ThriftClientContext implements  ServerContext {
        TProtocol in;
        public ThriftClientContext(TProtocol in) {
            this.in = in;
        }
        public TProtocol getIn() {
            return in;
        }
    }
    public class BgpUpdateServer implements Runnable, BgpUpdater.Iface {

        ThriftClientContext oldThriftClientContext;

        public void BgpUpdateServer() {
        }

        public void run() {
            try {
                BgpUpdater.Processor processor = new BgpUpdater.Processor(this);

                TNonblockingServerTransport trans = new TNonblockingServerSocket(ourPort);
                TThreadedSelectorServer.Args args = new TThreadedSelectorServer.Args(trans);
                args.transportFactory(new TFramedTransport.Factory());
                args.protocolFactory(new TBinaryProtocol.Factory());
                args.processor(processor);
                args.selectorThreads(1);
                args.workerThreads(1);
                server = new TThreadedSelectorServer(args);
                server.setServerEventHandler(new TServerEventHandler() {
                    @Override
                    public void preServe() {
                        LOGGER.info("Bgp thrift server pre serve event");
                    }

                    @Override
                    public ServerContext createContext(TProtocol input, TProtocol output) {
                        LOGGER.info("Bgp thrift server create context event");
                        synchronized (this) {
                            try {
                                if (oldThriftClientContext != null) {
                                    LOGGER.info("Bgp thrift server closing old context");
                                    oldThriftClientContext.getIn().getTransport().close();
                                } else {
                                    LOGGER.info("Bgp thrift server old context is null nothing to close");
                                }
                                oldThriftClientContext = null;
                            } catch (Throwable ignore) {
                            }
                            oldThriftClientContext = new ThriftClientContext(input);
                            return oldThriftClientContext;
                        }
                    }

                    @Override
                    public void deleteContext(ServerContext serverContext, TProtocol input, TProtocol output) {
                        LOGGER.info("Bgp thrift server delete context event");
                        if (oldThriftClientContext == serverContext) {
                            LOGGER.info("Bgp thrift server cleanup old context");
                            oldThriftClientContext = null;
                        } else {
                            LOGGER.info("Bgp thrift server cleanup context");
                        }
                    }

                    @Override
                    public void processContext(ServerContext serverContext, TTransport inputTransport, TTransport outputTransport) {
                        LOGGER.trace("Bgp thrift server process context event");
                    }
                });
                server.serve();
            } catch (Exception e) {
                LOGGER.error("Exception in BGP Updater server" + e);
            }
        }

        public void onUpdatePushRoute(protocol_type protocolType,
                                      String rd,
                                      String prefix,
                                      int plen,
                                      String nexthop,
                                      int ethtag,
                                      String esi,
                                      String macaddress,
                                      int l2label,
                                      int l3label,
                                      String routermac)
        {
            try {
                LOGGER.debug("Update on push route : rd {} prefix {} plen {}",rd,prefix,plen);

                // l2label is ignored even in case of RT5. only l3label considered
                BgpConfigurationManager.onUpdatePushRoute(
                        protocolType,
                        rd,
                        prefix,
                        plen,
                        nexthop,
                        ethtag,
                        esi,
                        macaddress,
                        l3label,
                        routermac);

            } catch (Throwable e) {
                LOGGER.error("failed to handle update route ", e);
            }
        }

        public void onUpdateWithdrawRoute(protocol_type protocolType,
                                          String rd,
                                          String prefix,
                                          int plen,
                                          String nexthop,
                                          int ethtag,
                                          String esi,
                                          String macaddress,
                                          int l2label,
                                          int l3label)
        {
            LOGGER.debug("Route del ** {} ** {}/{} ", rd, prefix, plen);
            try {
                LOGGER.info("REMOVE: Removing Fib entry rd {} prefix {}", rd, prefix);
                fibDSWriter.removeFibEntryFromDS(rd, prefix + "/" + plen);
                LOGGER.info("REMOVE: Removed Fib entry rd {} prefix {}", rd, prefix);
            } catch (Throwable e) {
                LOGGER.error("failed to handle withdraw route " ,e);
            }
        }

        public void onStartConfigResyncNotification() {
            LOGGER.info("BGP (re)started");
            bgpManager.setqBGPrestartTS(System.currentTimeMillis());
            try {
                bgpManager.bgpRestarted();
            } catch (Throwable e) {
                LOGGER.error("failed to handle onStartConfigResyncNotification " ,e);
            }
        }

        public void onNotificationSendEvent(String prefix, byte errCode,
                                                           byte errSubcode) {
            int code = errCode;
            int subCode = errSubcode;
            bgpManager.sendNotificationEvent(prefix, code, subCode);
        }
    }

    Thread thread;

    public void start() {
        thread = new Thread(new BgpUpdateServer());
        thread.start();
    }

    public void stop() {
        server.stop();
        thread.stop();
    }
} 
 

