/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.elan.statisitcs;

import com.google.common.util.concurrent.Futures;
import java.math.BigInteger;
import java.util.List;
import java.util.Set;
import java.util.concurrent.Future;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.genius.interfacemanager.globals.InterfaceInfo;
import org.opendaylight.genius.interfacemanager.globals.InterfaceServiceUtil;
import org.opendaylight.genius.interfacemanager.globals.VlanInterfaceInfo;
import org.opendaylight.genius.interfacemanager.interfaces.IInterfaceManager;
import org.opendaylight.genius.mdsalutil.MatchInfo;
import org.opendaylight.genius.mdsalutil.NwConstants;
import org.opendaylight.genius.utils.ServiceIndex;
import org.opendaylight.netvirt.elan.utils.ElanUtils;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius._interface.statistics.rev150824.ResultCode;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.servicebinding.rev160406.service.bindings.ServicesInfo;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.instances.ElanInstance;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.rev150602.elan.interfaces.ElanInterface;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.statistics.rev150824.ElanStatisticsService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.statistics.rev150824.GetElanInterfaceStatisticsInput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.statistics.rev150824.GetElanInterfaceStatisticsOutput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.statistics.rev150824.GetElanInterfaceStatisticsOutputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.elan.statistics.rev150824.get.elan._interface.statistics.output.StatResultBuilder;
import org.opendaylight.yangtools.yang.common.RpcError.ErrorType;
import org.opendaylight.yangtools.yang.common.RpcResult;
import org.opendaylight.yangtools.yang.common.RpcResultBuilder;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class ElanStatisticsImpl implements ElanStatisticsService {
    private static final Logger LOG = LoggerFactory.getLogger(ElanStatisticsImpl.class);

    private final DataBroker dataBroker;
    private final IInterfaceManager interfaceManager;

    public ElanStatisticsImpl(DataBroker dataBroker, IInterfaceManager interfaceManager) {
        this.dataBroker = dataBroker;
        this.interfaceManager = interfaceManager;
    }

    @Override
    public Future<RpcResult<GetElanInterfaceStatisticsOutput>> getElanInterfaceStatistics(
        GetElanInterfaceStatisticsInput input) {
        String interfaceName = input.getInterfaceName();
        LOG.debug("getElanInterfaceStatistics is called for elan interface {}", interfaceName);
        RpcResultBuilder<GetElanInterfaceStatisticsOutput> rpcResultBuilder = null;
        if (interfaceName == null) {
            rpcResultBuilder = RpcResultBuilder.failed();
            return getFutureWithAppErrorMessage(rpcResultBuilder, "Interface name is not provided");
        }
        ElanInterface elanInterface = ElanUtils.getElanInterfaceByElanInterfaceName(dataBroker, interfaceName);
        if (elanInterface == null) {
            rpcResultBuilder = RpcResultBuilder.failed();
            return getFutureWithAppErrorMessage(rpcResultBuilder,
                    String.format("Interface %s is not a ELAN interface", interfaceName));
        }
        String elanInstanceName = elanInterface.getElanInstanceName();
        ElanInstance elanInfo = ElanUtils.getElanInstanceByName(dataBroker, elanInstanceName);
        long elanTag = elanInfo.getElanTag();
        InterfaceInfo interfaceInfo = interfaceManager.getInterfaceInfo(interfaceName);
        ServicesInfo serviceInfo = ElanUtils.getServiceInfo(elanInstanceName, elanTag, interfaceName);
        //FIXME [ELANBE] Get this API Later
        short tableId = 0;
//        try {
//
//            //tableId = interfaceManager.getTableIdForService(interfaceName, serviceInfo);
//        } catch (InterfaceNotFoundException | InterfaceServiceNotFoundException e) {
//            rpcResultBuilder = RpcResultBuilder.failed();
//            return getFutureWithAppErrorMessage(rpcResultBuilder,
//                String.format("Interface %s or Service %s doesn't exist", interfaceName, serviceInfo));
//        }
        if (!interfaceInfo.isOperational()) {
            LOG.debug("interface {} is down and returning with no statistics", interfaceName);
            rpcResultBuilder = RpcResultBuilder.success();
            return Futures
                    .immediateFuture(rpcResultBuilder.withResult(new GetElanInterfaceStatisticsOutputBuilder()
                            .setStatResult(
                                    new StatResultBuilder().setStatResultCode(ResultCode.NotFound).setByteRxCount(0L)
                                            .setByteTxCount(0L).setPacketRxCount(0L).setPacketTxCount(0L).build())
                            .build()).build());
        }
        rpcResultBuilder = RpcResultBuilder.success();
        return Futures.immediateFuture(rpcResultBuilder
                .withResult(queryforElanInterfaceStatistics(tableId, elanInstanceName, interfaceInfo)).build());
    }

    private GetElanInterfaceStatisticsOutput queryforElanInterfaceStatistics(short tableId, String elanInstanceName,
            InterfaceInfo interfaceInfo) {
        BigInteger dpId = interfaceInfo.getDpId();
        List<MatchInfo> matches = null;
        String interfaceName = interfaceInfo.getInterfaceName();
        if (tableId == NwConstants.VLAN_INTERFACE_INGRESS_TABLE) {
            VlanInterfaceInfo vlanInterfaceInfo = (VlanInterfaceInfo)interfaceInfo;
            matches = InterfaceServiceUtil.getMatchInfoForVlanLPort(dpId, interfaceInfo.getPortNo(),
                InterfaceServiceUtil.getVlanId(interfaceName, dataBroker), vlanInterfaceInfo.isVlanTransparent());
        } else {
            matches = InterfaceServiceUtil.getLPortDispatcherMatches(
                    ServiceIndex.getIndex(NwConstants.ELAN_SERVICE_NAME, NwConstants.ELAN_SERVICE_INDEX),
                    interfaceInfo.getInterfaceTag());
        }
        long groupId = interfaceInfo.getGroupId();
        Set<Object> statRequestKeys = InterfaceServiceUtil.getStatRequestKeys(dpId, tableId, matches,
                String.format("%s.%s", elanInstanceName, interfaceName), groupId);
        // StatisticsInfo statsInfo = new StatisticsInfo(statRequestKeys);
//        org.opendaylight.vpnservice.ericsson.mdsalutil.statistics.StatResult statResult
//            = mdsalMgr.queryForStatistics(interfaceName, statsInfo);
//        ResultCode resultCode = ResultCode.Success;
//        if (!statResult.isComplete()) {
//            resultCode = ResultCode.Incomplete;
//        }

        //StatValue ingressFlowStats = statResult.getStatResult(InterfaceServiceUtil
//            .getFlowStatisticsKey(dpId, tableId, matches, elanInstanceName));
        //StatValue groupStats = statResult.getStatResult(InterfaceServiceUtil.getGroupStatisticsKey(dpId, groupId));
//      return new GetElanInterfaceStatisticsOutputBuilder().setStatResult(new
//          StatResultBuilder().setStatResultCode(resultCode)
//                .setByteRxCount(ingressFlowStats.getByteCount()).setPacketRxCount(ingressFlowStats.getPacketCount())
//                .setByteTxCount(groupStats.getByteCount()).setPacketTxCount(groupStats.getPacketCount()).build())
//                .build();
        return null;
    }

    private Future<RpcResult<GetElanInterfaceStatisticsOutput>> getFutureWithAppErrorMessage(
        RpcResultBuilder<GetElanInterfaceStatisticsOutput> rpcResultBuilder, String message) {
        rpcResultBuilder.withError(ErrorType.APPLICATION, message);
        return Futures.immediateFuture(rpcResultBuilder.build());
    }

}
