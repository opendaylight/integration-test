/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.vpnmanager;

import com.google.common.base.Optional;
import com.google.common.util.concurrent.SettableFuture;
import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.netvirt.bgpmanager.api.IBgpManager;
import org.opendaylight.netvirt.fibmanager.api.IFibManager;
import org.opendaylight.netvirt.fibmanager.api.RouteOrigin;
import org.opendaylight.netvirt.vpnmanager.api.intervpnlink.InterVpnLinkCache;
import org.opendaylight.netvirt.vpnmanager.api.intervpnlink.InterVpnLinkDataComposite;
import org.opendaylight.netvirt.vpnmanager.intervpnlink.InterVpnLinkUtil;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.idmanager.rev160406.IdManagerService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.vpn.rpc.rev160201.AddStaticRouteInput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.vpn.rpc.rev160201.AddStaticRouteOutputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.vpn.rpc.rev160201.AddStaticRouteOutput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.vpn.rpc.rev160201.GenerateVpnLabelInput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.vpn.rpc.rev160201.GenerateVpnLabelOutput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.vpn.rpc.rev160201.GenerateVpnLabelOutputBuilder;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.vpn.rpc.rev160201.RemoveStaticRouteInput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.vpn.rpc.rev160201.RemoveVpnLabelInput;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.vpn.rpc.rev160201.VpnRpcService;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.netvirt.inter.vpn.link.rev160311.inter.vpn.links.InterVpnLink;
import org.opendaylight.yangtools.yang.common.RpcError;
import org.opendaylight.yangtools.yang.common.RpcError.ErrorType;
import org.opendaylight.yangtools.yang.common.RpcResult;
import org.opendaylight.yangtools.yang.common.RpcResultBuilder;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.Collection;
import java.util.concurrent.Future;

public class VpnRpcServiceImpl implements VpnRpcService {
    private static final Logger LOG = LoggerFactory.getLogger(VpnRpcServiceImpl.class);
    private final DataBroker dataBroker;
    private final IdManagerService idManager;
    private final VpnInterfaceManager vpnInterfaceMgr;
    private IFibManager fibManager;
    private IBgpManager bgpManager;

    public VpnRpcServiceImpl(final DataBroker dataBroker, final IdManagerService idManager,
                             final VpnInterfaceManager vpnIfaceMgr, final IFibManager fibManager, IBgpManager bgpManager) {
        this.dataBroker = dataBroker;
        this.idManager = idManager;
        this.vpnInterfaceMgr = vpnIfaceMgr;
        this.fibManager = fibManager;
        this.bgpManager = bgpManager;
    }

    public void setFibManager(IFibManager fibMgr) {
        this.fibManager = fibMgr;
    }


    /**
     * to generate label for the given ip prefix from the associated VPN
     *
     */
    @Override
    public Future<RpcResult<GenerateVpnLabelOutput>> generateVpnLabel(GenerateVpnLabelInput input) {
        String vpnName = input.getVpnName();
        String ipPrefix = input.getIpPrefix();
        SettableFuture<RpcResult<GenerateVpnLabelOutput>> futureResult = SettableFuture.create();
        String rd = VpnUtil.getVpnRd(dataBroker, vpnName);
        long label = VpnUtil.getUniqueId(idManager, VpnConstants.VPN_IDPOOL_NAME,
                        VpnUtil.getNextHopLabelKey((rd != null) ? rd : vpnName, ipPrefix));
        if (label == 0) {
            String msg = String.format("Could not retrieve the label for prefix {} in VPN {}", ipPrefix, vpnName);
            LOG.error(msg);
            futureResult.set(RpcResultBuilder.<GenerateVpnLabelOutput>failed().withError(ErrorType.APPLICATION, msg)
                                                                              .build());
        } else {
            GenerateVpnLabelOutput output = new GenerateVpnLabelOutputBuilder().setLabel(label).build();
            futureResult.set(RpcResultBuilder.success(output).build());
        }
        return futureResult;
    }

    /**
     * to remove label for the given ip prefix from the associated VPN
     *
     */
    @Override
    public Future<RpcResult<Void>> removeVpnLabel(RemoveVpnLabelInput input) {
        String vpnName = input.getVpnName();
        String ipPrefix = input.getIpPrefix();
        String rd = VpnUtil.getVpnRd(dataBroker, vpnName);
        SettableFuture<RpcResult<Void>> futureResult = SettableFuture.create();
        VpnUtil.releaseId(idManager, VpnConstants.VPN_IDPOOL_NAME,
                VpnUtil.getNextHopLabelKey((rd != null) ? rd : vpnName, ipPrefix));
        futureResult.set(RpcResultBuilder.<Void>success().build());
        return futureResult;
    }

    private Collection<RpcError> validateAddStaticRouteInput(AddStaticRouteInput input) {
        Collection<RpcError> rpcErrors = new ArrayList<RpcError>();
        String destination = input.getDestination();
        String vpnInstanceName = input.getVpnInstanceName();
        String nexthop = input.getNexthop();
        if ( destination == null || destination.isEmpty() ) {
            String message = "destination parameter is mandatory";
            rpcErrors.add(RpcResultBuilder.newError(RpcError.ErrorType.PROTOCOL, "addStaticRoute", message));
        }
        if ( vpnInstanceName == null || vpnInstanceName.isEmpty() ) {
            String message = "vpnInstanceName parameter is mandatory";
            rpcErrors.add(RpcResultBuilder.newError(RpcError.ErrorType.PROTOCOL, "addStaticRoute", message));
        }
        if ( nexthop == null || nexthop.isEmpty() ) {
            String message = "nexthop parameter is mandatory";
            rpcErrors.add(RpcResultBuilder.newError(RpcError.ErrorType.PROTOCOL, "addStaticRoute", message));
        }
        return rpcErrors;
    }

    @Override
    public Future<RpcResult<AddStaticRouteOutput>> addStaticRoute(AddStaticRouteInput input) {

        SettableFuture<RpcResult<AddStaticRouteOutput>> result = SettableFuture.create();
        String destination = input.getDestination();
        String vpnInstanceName = input.getVpnInstanceName();
        String nexthop = input.getNexthop();
        Long label = input.getLabel();
        LOG.info("Adding static route for Vpn {} with destination {}, nexthop {} and label {}",
                 vpnInstanceName, destination, nexthop, label);

        Collection<RpcError> rpcErrors = validateAddStaticRouteInput(input);
        if ( !rpcErrors.isEmpty() ) {
            result.set(RpcResultBuilder.<AddStaticRouteOutput>failed().withRpcErrors(rpcErrors).build());
            return result;
        }

        if ( label == null || label == 0 ) {
            label = (long) VpnUtil.getUniqueId(idManager, VpnConstants.VPN_IDPOOL_NAME,
                                               VpnUtil.getNextHopLabelKey(vpnInstanceName, destination));
            if ( label == 0 ) {
                String message = "Unable to retrieve a new Label for the new Route";
                result.set(RpcResultBuilder.<AddStaticRouteOutput>failed().withError(RpcError.ErrorType.APPLICATION,
                                                                                     message).build());
                return result;
            }
        }

        String vpnRd = VpnUtil.getVpnRd(dataBroker, input.getVpnInstanceName());
        if ( vpnRd == null ) {
            String message = "Could not find Route-Distinguisher for VpnName " + vpnInstanceName;
            result.set(RpcResultBuilder.<AddStaticRouteOutput>failed().withError(RpcError.ErrorType.APPLICATION,
                                                                                 message).build());
            return result;
        }

        Optional<InterVpnLinkDataComposite> optIVpnLink = InterVpnLinkCache.getInterVpnLinkByEndpoint(nexthop);
        if ( optIVpnLink.isPresent() ) {


            try {
                InterVpnLinkUtil.handleStaticRoute(optIVpnLink.get(), vpnInstanceName, destination, nexthop,
                                                   label.intValue(),
                                                   dataBroker, fibManager, bgpManager);
            } catch (Exception e) {
                String errMsg = "Could not advertise route [vpn=" + vpnRd + ", prefix=" + destination + ", label="
                        + label + ", nexthop=" + nexthop + ", ] to BGP. Reason: " + e.getMessage();
                LOG.warn(errMsg, e);
                result.set(RpcResultBuilder.<AddStaticRouteOutput>failed().withError(ErrorType.APPLICATION, errMsg)
                      .build());
                return result;
            }
        } else {
            vpnInterfaceMgr.addExtraRoute(destination, nexthop, vpnRd, null /*routerId */, label.intValue(),
                                          RouteOrigin.STATIC, null /* intfName */, null, null);
        }

        AddStaticRouteOutput labelOutput = new AddStaticRouteOutputBuilder().setLabel(label).build();
        result.set(RpcResultBuilder.success(labelOutput).build());
        return result;
    }

    private Collection<RpcError> validateRemoveStaticRouteInput(RemoveStaticRouteInput input) {
        Collection<RpcError> rpcErrors = new ArrayList<>();
        String destination = input.getDestination();
        String vpnInstanceName = input.getVpnInstanceName();
        String nexthop = input.getNexthop();
        if ( destination == null || destination.isEmpty() ) {
            String message = "destination parameter is mandatory";
            rpcErrors.add(RpcResultBuilder.newError(RpcError.ErrorType.PROTOCOL, "removeStaticRoute", message));
        }
        if ( vpnInstanceName == null || vpnInstanceName.isEmpty() ) {
            String message = "vpnInstanceName parameter is mandatory";
            rpcErrors.add(RpcResultBuilder.newError(RpcError.ErrorType.PROTOCOL, "removeStaticRoute", message));
        }
        if ( nexthop == null || nexthop.isEmpty() ) {
            String message = "nexthop parameter is mandatory";
            rpcErrors.add(RpcResultBuilder.newError(RpcError.ErrorType.PROTOCOL, "removeStaticRoute", message));
        }
        return rpcErrors;
    }

    @Override
    public Future<RpcResult<Void>> removeStaticRoute(RemoveStaticRouteInput input) {

        SettableFuture<RpcResult<Void>> result = SettableFuture.create();

        String destination = input.getDestination();
        String vpnInstanceName = input.getVpnInstanceName();
        String nexthop = input.getNexthop();
        LOG.info("Removing static route with destination={}, nexthop={} in VPN={}",
                 destination, nexthop, vpnInstanceName);
        Collection<RpcError> rpcErrors = validateRemoveStaticRouteInput(input);
        if ( !rpcErrors.isEmpty() ) {
            result.set(RpcResultBuilder.<Void>failed().withRpcErrors(rpcErrors).build());
            return result;
        }

        String vpnRd = VpnUtil.getVpnRd(dataBroker, input.getVpnInstanceName());
        if ( vpnRd == null ) {
            String message = "Could not find Route-Distinguisher for VpnName " + vpnInstanceName;
            result.set(RpcResultBuilder.<Void>failed().withError(RpcError.ErrorType.APPLICATION, message).build());
            return result;
        }

        Optional<InterVpnLink> optVpnLink = InterVpnLinkUtil.getInterVpnLinkByEndpointIp(dataBroker, nexthop);
        if ( optVpnLink.isPresent() ) {
            fibManager.removeOrUpdateFibEntry(dataBroker,  vpnRd, destination, nexthop, null);
            try {
                bgpManager.withdrawPrefix(vpnRd, destination);
            } catch (Exception e) {
                LOG.warn("Could not withdraw route [vpn={}  prefix={}] to BGP. Reason:", vpnRd, destination, e);
            }
        } else {
            vpnInterfaceMgr.delExtraRoute(destination, nexthop, vpnRd, null /*routerId*/, null /*intfName*/, null);
        }
        result.set(RpcResultBuilder.<Void>success().build());

        return result;
    }

}
