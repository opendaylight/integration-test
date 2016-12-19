/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
/**
 * Created by ECHIAPT on 7/21/2016.
 */

package org.opendaylight.netvirt.bgpmanager.oam;

import static org.opendaylight.netvirt.bgpmanager.oam.BgpCounters.parse_ip_bgp_vpnv4_all_summary;
import static org.opendaylight.netvirt.bgpmanager.oam.BgpCounters.resetFile;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.TimerTask;
import org.opendaylight.netvirt.bgpmanager.BgpConfigurationManager;
import org.opendaylight.netvirt.bgpmanager.BgpManager;
import org.opendaylight.yang.gen.v1.urn.ericsson.params.xml.ns.yang.ebgp.rev150901.bgp.Neighbors;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class BgpAlarms extends TimerTask {
    private static final Logger logger = LoggerFactory.getLogger(BgpAlarms.class);
    private static final Logger LOG = LoggerFactory.getLogger(BgpManager.class);
    public static final BgpJMXAlarmAgent alarmAgent = new BgpJMXAlarmAgent();
    private static Map<String , String> neighborStatusMap = new HashMap<>();
    private BgpConfigurationManager bgpMgr;

    private static Map<String , BgpAlarmStatus> neighborsRaisedAlarmStatusMap = new HashMap<>();
    private final String alarmText = "Bgp Neighbor TCP connection is down";

    @Override
    public void run () {
        List<Neighbors> nbrList = null;
        try {
            logger.debug("Fetching neighbor status' from BGP");
            resetFile("cmd_ip_bgp_vpnv4_all_summary.txt");
            neighborStatusMap.clear();

            if ((bgpMgr != null) &&
                    (bgpMgr.getBgpCounters() != null)) {
                bgpMgr.getBgpCounters().fetchCmdOutputs("cmd_ip_bgp_vpnv4_all_summary.txt",
                        "show ip bgp vpnv4 all summary");
                if (bgpMgr.getConfig() != null) {
                    nbrList= bgpMgr.getConfig().getNeighbors();
                }
                parse_ip_bgp_vpnv4_all_summary(neighborStatusMap);
                processNeighborStatusMap(neighborStatusMap, nbrList, neighborsRaisedAlarmStatusMap);
            }

            logger.debug("Finished getting the status of BGP neighbors");
        } catch (Exception e) {
            logger.error("Failed to publish bgp counters ", e);
        }
    }

    public BgpAlarms(BgpConfigurationManager bgpManager) {
        bgpMgr = bgpManager;
        alarmAgent.registerMbean();
        if (bgpMgr != null &&
                bgpMgr.getConfig() != null) {
            List<Neighbors> nbrs = bgpMgr.getConfig().getNeighbors();
            if (nbrs != null) {
                for (Neighbors nbr: nbrs) {
                    logger.trace("Clearing Neighbor DOWN alarm at the startup for Neighbor {}",
                            nbr.getAddress().getValue());
                    clearBgpNbrDownAlarm(nbr.getAddress().getValue());
                    neighborsRaisedAlarmStatusMap.put(  nbr.getAddress().getValue(),
                            BgpAlarmStatus.CLEARED);
                }
            }
        }
    }

    public void processNeighborStatusMap(Map<String, String> nbrStatusMap,
                                         List<Neighbors> nbrs, Map<String, BgpAlarmStatus>
                                                 nbrsRaisedAlarmStatusMap) {
        boolean alarmToRaise;
        String alarmDescr = "";
        String nbrshipStatus;
        if ( (nbrs == null) || (nbrs.size() == 0)) {
            logger.trace("No BGP neighbors configured.");
            return;
        }
        try {
            for (Neighbors nbr : nbrs) {
                alarmToRaise = true;
                if ((nbrStatusMap != null) && nbrStatusMap.containsKey(nbr.getAddress().getValue())) {
                    nbrshipStatus = nbrStatusMap.get(nbr.getAddress().getValue());
                    logger.trace("nbr {} status {}",
                            nbr.getAddress().getValue(),
                            nbrshipStatus);
                    try {
                        Integer.parseInt(nbrshipStatus);
                        alarmToRaise = false;
                    } catch (Exception e) {
                        logger.trace("Exception thrown in parsing the integers. {}", e);
                    }
                    if (alarmToRaise) {
                        if ((!nbrsRaisedAlarmStatusMap.containsKey(nbr.getAddress().getValue())) ||
                                (nbrsRaisedAlarmStatusMap.get(nbr.getAddress().getValue()) != BgpAlarmStatus.RAISED)) {
                            logger.trace("alarm raised for {}.", nbr.getAddress().getValue());
                            raiseBgpNbrDownAlarm(nbr.getAddress().getValue());
                            nbrsRaisedAlarmStatusMap.put(nbr.getAddress().getValue(), BgpAlarmStatus.RAISED);
                        } else {
                            logger.trace("alarm raised already for {}", nbr.getAddress().getValue());
                        }
                    } else {
                        if ((!nbrsRaisedAlarmStatusMap.containsKey(nbr.getAddress().getValue())) ||
                                (nbrsRaisedAlarmStatusMap.get(nbr.getAddress().getValue()) != BgpAlarmStatus.CLEARED)) {
                            clearBgpNbrDownAlarm(nbr.getAddress().getValue());
                            logger.trace("alarm cleared for {}", nbr.getAddress().getValue());
                            nbrsRaisedAlarmStatusMap.put(nbr.getAddress().getValue(), BgpAlarmStatus.CLEARED);
                        } else {
                            logger.trace("alarm cleared already for {}", nbr.getAddress().getValue());
                        }
                    }
                }
            }
        } catch ( Exception e1) {
            logger.trace("Exception thrown in the processNeighborStatusMap method. {}", e1);
        }
    }

    public void raiseBgpNbrDownAlarm(String nbrIp) {

        StringBuilder source = new StringBuilder();
        source.append("BGP_Neighbor=").append(nbrIp);
        if ((nbrIp == null) || (nbrIp.isEmpty())) {
            return;
        }
        logger.trace("Raising BgpControlPathFailure alarm. {} alarmtext {} ", source, alarmText);
        //Invokes JMX raiseAlarm method
        alarmAgent.invokeFMraisemethod( "BgpControlPathFailure", alarmText, source.toString());
    }

    public void clearBgpNbrDownAlarm(String nbrIp) {
        StringBuilder source = new StringBuilder();
        source.append("BGP_Neighbor=").append(nbrIp);
        if ((nbrIp == null) || (nbrIp.isEmpty())) {
            return;
        }
        logger.trace("Clearing BgpControlPathFailure alarm of source {} alarmtext {} ", source, alarmText);
        //Invokes JMX clearAlarm method
        alarmAgent.invokeFMclearmethod( "BgpControlPathFailure", alarmText, source.toString());
    }
}
