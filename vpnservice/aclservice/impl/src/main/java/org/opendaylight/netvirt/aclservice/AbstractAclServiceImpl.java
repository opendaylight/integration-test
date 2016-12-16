/*
 * Copyright (c) 2016 Red Hat, Inc. and others. All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.aclservice;

import java.math.BigInteger;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Set;

import org.opendaylight.controller.md.sal.binding.api.DataBroker;
import org.opendaylight.genius.mdsalutil.ActionInfo;
import org.opendaylight.genius.mdsalutil.ActionType;
import org.opendaylight.genius.mdsalutil.FlowEntity;
import org.opendaylight.genius.mdsalutil.InstructionInfo;
import org.opendaylight.genius.mdsalutil.InstructionType;
import org.opendaylight.genius.mdsalutil.MDSALUtil;
import org.opendaylight.genius.mdsalutil.MatchInfoBase;
import org.opendaylight.genius.mdsalutil.NwConstants;
import org.opendaylight.genius.mdsalutil.interfaces.IMdsalApiManager;
import org.opendaylight.netvirt.aclservice.api.AclServiceListener;
import org.opendaylight.netvirt.aclservice.api.AclServiceManager.Action;
import org.opendaylight.netvirt.aclservice.api.utils.AclInterface;
import org.opendaylight.netvirt.aclservice.utils.AclDataUtil;
import org.opendaylight.netvirt.aclservice.utils.AclServiceUtils;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.access.control.list.rev160218.access.lists.acl.access.list.entries.Ace;
import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.servicebinding.rev160406.ServiceModeBase;
import org.opendaylight.yang.gen.v1.urn.opendaylight.genius.interfacemanager.servicebinding.rev160406.ServiceModeEgress;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.aclservice.rev160608.interfaces._interface.AllowedAddressPairs;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public abstract class AbstractAclServiceImpl implements AclServiceListener {

    private static final Logger LOG = LoggerFactory.getLogger(AbstractAclServiceImpl.class);

    protected final IMdsalApiManager mdsalManager;
    protected final DataBroker dataBroker;
    protected final Class<? extends ServiceModeBase> serviceMode;
    protected final AclDataUtil aclDataUtil;
    protected final AclServiceUtils aclServiceUtils;

    /**
     * Initialize the member variables.
     *
     * @param serviceMode
     *            the service mode
     * @param dataBroker
     *            the data broker instance.
     * @param mdsalManager
     *            the mdsal manager instance.
     * @param aclDataUtil
     *            the acl data util.
     * @param aclServiceUtils
     *            the acl service util.
     */
    public AbstractAclServiceImpl(Class<? extends ServiceModeBase> serviceMode, DataBroker dataBroker,
            IMdsalApiManager mdsalManager, AclDataUtil aclDataUtil, AclServiceUtils aclServiceUtils) {
        this.dataBroker = dataBroker;
        this.mdsalManager = mdsalManager;
        this.serviceMode = serviceMode;
        this.aclDataUtil = aclDataUtil;
        this.aclServiceUtils = aclServiceUtils;
    }

    @Override
    public boolean applyAcl(AclInterface port) {
        if (port == null) {
            LOG.error("port cannot be null");
            return false;
        }
        if (port.getSecurityGroups() == null) {
            LOG.error("port security groups cannot be null");
            return false;
        }
        BigInteger dpId = port.getDpId();
        if (dpId == null || port.getLPortTag() == null) {
            LOG.error("Unable to find DP Id from ACL interface with id {}", port.getInterfaceId());
            return false;
        }
        programAclWithAllowedAddress(dpId, port.getAllowedAddressPairs(), port.getLPortTag(), port.getSecurityGroups(),
                Action.ADD, NwConstants.ADD_FLOW, port.getInterfaceId());

        bindService(port.getInterfaceId());
        return true;
    }

    @Override
    public boolean updateAcl(AclInterface portBefore, AclInterface portAfter) {
        boolean result = true;
        boolean isPortSecurityEnable = portAfter.getPortSecurityEnabled();
        boolean isPortSecurityEnableBefore = portBefore.getPortSecurityEnabled();
        // if port security is changed, apply/remove Acls
        if (isPortSecurityEnableBefore != isPortSecurityEnable) {
            if (isPortSecurityEnable) {
                result = applyAcl(portAfter);
            } else {
                result = removeAcl(portAfter);
            }
        } else if (isPortSecurityEnable) {
            // Acls has been updated, find added/removed Acls and act accordingly.
            processInterfaceUpdate(portBefore, portAfter);
        }

        return result;
    }

    private void processInterfaceUpdate(AclInterface portBefore, AclInterface portAfter) {
        BigInteger dpId = portAfter.getDpId();
        List<AllowedAddressPairs> addedAllowedAddressPairs =
                AclServiceUtils.getUpdatedAllowedAddressPairs(portAfter.getAllowedAddressPairs(),
                        portBefore.getAllowedAddressPairs());
        List<AllowedAddressPairs> deletedAllowedAddressPairs =
                AclServiceUtils.getUpdatedAllowedAddressPairs(portBefore.getAllowedAddressPairs(),
                        portAfter.getAllowedAddressPairs());
        if (addedAllowedAddressPairs != null && !addedAllowedAddressPairs.isEmpty()) {
            programAclWithAllowedAddress(dpId, addedAllowedAddressPairs, portAfter.getLPortTag(),
                    portAfter.getSecurityGroups(), Action.UPDATE, NwConstants.ADD_FLOW, portAfter.getInterfaceId());
        }
        if (deletedAllowedAddressPairs != null && !deletedAllowedAddressPairs.isEmpty()) {
            programAclWithAllowedAddress(dpId, deletedAllowedAddressPairs, portAfter.getLPortTag(),
                    portAfter.getSecurityGroups(), Action.UPDATE, NwConstants.DEL_FLOW, portAfter.getInterfaceId());
        }

        List<Uuid> addedAcls = AclServiceUtils.getUpdatedAclList(portAfter.getSecurityGroups(),
                portBefore.getSecurityGroups());
        List<Uuid> deletedAcls = AclServiceUtils.getUpdatedAclList(portBefore.getSecurityGroups(),
                portAfter.getSecurityGroups());
        if (deletedAcls != null && !deletedAcls.isEmpty()) {
            updateCustomRules(dpId, portAfter.getLPortTag(), deletedAcls, NwConstants.DEL_FLOW,
                    portAfter.getInterfaceId(), portAfter.getAllowedAddressPairs());
        }
        if (addedAcls != null && !addedAcls.isEmpty()) {
            updateCustomRules(dpId, portAfter.getLPortTag(), addedAcls, NwConstants.ADD_FLOW,
                    portAfter.getInterfaceId(), portAfter.getAllowedAddressPairs());
        }
    }

    private void updateCustomRules(BigInteger dpId, int lportTag, List<Uuid> aclUuidList, int action,
                                   String portId, List<AllowedAddressPairs> syncAllowedAddresses) {
        programAclRules(aclUuidList, dpId, lportTag, action, portId);
        syncRemoteAclRules(aclUuidList, action, portId, syncAllowedAddresses);
    }

    private void syncRemoteAclRules(List<Uuid> aclUuidList, int action, String currentPortId,
                                    List<AllowedAddressPairs> syncAllowedAddresses) {
        if (aclUuidList == null) {
            LOG.warn("security groups are null");
            return;
        }
        for (Uuid remoteAclId : aclUuidList) {
            Map<String, Set<AclInterface>> mapAclWithPortSet = aclDataUtil.getRemoteAclInterfaces(remoteAclId);
            if (mapAclWithPortSet == null) {
                continue;
            }
            for (Entry<String, Set<AclInterface>> entry : mapAclWithPortSet.entrySet()) {
                String aclName = entry.getKey();
                for (AclInterface port : entry.getValue()) {
                    if (currentPortId.equals(port.getInterfaceId())) {
                        continue;
                    }
                    List<Ace> remoteAceList = AclServiceUtils.getAceWithRemoteAclId(dataBroker, port, remoteAclId);
                    for (Ace ace : remoteAceList) {
                        programAceRule(port.getDpId(), port.getLPortTag(), action, aclName, ace, port.getInterfaceId(),
                                syncAllowedAddresses);
                    }
                }
            }
        }
    }

    private void programAclWithAllowedAddress(BigInteger dpId, List<AllowedAddressPairs> allowedAddresses,
                                              int lportTag, List<Uuid> aclUuidList, Action action, int addOrRemove,
                                              String portId) {
        programGeneralFixedRules(dpId, "", allowedAddresses, lportTag, action, addOrRemove);
        programSpecificFixedRules(dpId, "", allowedAddresses, lportTag, portId, action, addOrRemove);
        if (action == Action.ADD || action == Action.REMOVE) {
            programAclRules(aclUuidList, dpId, lportTag, addOrRemove, portId);
        }
        syncRemoteAclRules(aclUuidList, addOrRemove, portId, allowedAddresses);
    }


    @Override
    public boolean removeAcl(AclInterface port) {
        BigInteger dpId = port.getDpId();
        if (dpId == null) {
            LOG.error("Unable to find DP Id from ACL interface with id {}", port.getInterfaceId());
            return false;
        }
        programAclWithAllowedAddress(dpId, port.getAllowedAddressPairs(), port.getLPortTag(), port.getSecurityGroups(),
                Action.REMOVE, NwConstants.DEL_FLOW, port.getInterfaceId());

        unbindService(port.getInterfaceId());
        return true;
    }

    @Override
    public boolean applyAce(AclInterface port, String aclName, Ace ace) {
        if (!port.isPortSecurityEnabled()) {
            return false;
        }
        programAceRule(port.getDpId(), port.getLPortTag(), NwConstants.ADD_FLOW, aclName, ace, port.getInterfaceId(),
                null);
        return true;
    }

    @Override
    public boolean removeAce(AclInterface port, String aclName, Ace ace) {
        if (!port.isPortSecurityEnabled()) {
            return false;
        }
        programAceRule(port.getDpId(), port.getLPortTag(), NwConstants.DEL_FLOW, aclName, ace, port.getInterfaceId(),
                null);
        return true;
    }

    /**
     * Bind service.
     *
     * @param interfaceName
     *            the interface name
     */
    protected abstract void bindService(String interfaceName);

    /**
     * Unbind service.
     *
     * @param interfaceName
     *            the interface name
     */
    protected abstract void unbindService(String interfaceName);

    /**
     * Program the default anti-spoofing rules.
     *
     * @param dpid the dpid
     * @param dhcpMacAddress the dhcp mac address.
     * @param allowedAddresses the allowed addresses
     * @param lportTag the lport tag
     * @param action add/modify/remove action
     * @param addOrRemove addorRemove
     */
    protected abstract void programGeneralFixedRules(BigInteger dpid, String dhcpMacAddress,
            List<AllowedAddressPairs> allowedAddresses, int lportTag, Action action, int addOrRemove);

    /**
     * Program the default specific rules.
     *
     * @param dpid the dpid
     * @param dhcpMacAddress the dhcp mac address.
     * @param allowedAddresses the allowed addresses
     * @param lportTag the lport tag
     * @param portId the port id
     * @param action add/modify/remove action
     * @param addOrRemove addorRemove
     */
    protected abstract void programSpecificFixedRules(BigInteger dpid, String dhcpMacAddress,
            List<AllowedAddressPairs> allowedAddresses, int lportTag, String portId, Action action, int addOrRemove);

    /**
     * Programs the acl custom rules.
     *
     * @param aclUuidList the list of acl uuid to be applied
     * @param dpId the dpId
     * @param lportTag the lport tag
     * @param addOrRemove whether to delete or add flow
     * @param portId the port id
     * @return program succeeded
     */
    protected abstract boolean programAclRules(List<Uuid> aclUuidList, BigInteger dpId, int lportTag, int addOrRemove,
                                            String portId);

    /**
     * Programs the ace custom rule.
     *
     * @param dpId the dpId
     * @param lportTag the lport tag
     * @param addOrRemove whether to delete or add flow
     * @param aclName the acl name
     * @param ace rule to be program
     * @param portId the port id
     * @param syncAllowedAddresses the allowed addresses
     */
    protected abstract void programAceRule(BigInteger dpId, int lportTag, int addOrRemove, String aclName, Ace ace,
            String portId, List<AllowedAddressPairs> syncAllowedAddresses);

    /**
     * Writes/remove the flow to/from the datastore.
     *
     * @param dpId
     *            the dpId
     * @param tableId
     *            the tableId
     * @param flowId
     *            the flowId
     * @param priority
     *            the priority
     * @param flowName
     *            the flow name
     * @param idleTimeOut
     *            the idle timeout
     * @param hardTimeOut
     *            the hard timeout
     * @param cookie
     *            the cookie
     * @param matches
     *            the list of matches to be writted
     * @param instructions
     *            the list of instruction to be written.
     * @param addOrRemove
     *            add or remove the entries.
     */
    protected void syncFlow(BigInteger dpId, short tableId, String flowId, int priority, String flowName,
            int idleTimeOut, int hardTimeOut, BigInteger cookie, List<? extends MatchInfoBase> matches,
            List<InstructionInfo> instructions, int addOrRemove) {
        if (addOrRemove == NwConstants.DEL_FLOW) {
            FlowEntity flowEntity = MDSALUtil.buildFlowEntity(dpId, tableId, flowId, priority, flowName, idleTimeOut,
                    hardTimeOut, cookie, matches, null);
            LOG.trace("Removing Acl Flow DpnId {}, flowId {}", dpId, flowId);
            mdsalManager.removeFlow(flowEntity);
        } else {
            FlowEntity flowEntity = MDSALUtil.buildFlowEntity(dpId, tableId, flowId, priority, flowName, idleTimeOut,
                    hardTimeOut, cookie, matches, instructions);
            LOG.trace("Installing DpnId {}, flowId {}", dpId, flowId);
            mdsalManager.installFlow(flowEntity);
        }
    }

    /**
     * Gets the dispatcher table resubmit instructions based on ingress/egress
     * service mode w.r.t switch.
     *
     * @param actionsInfos the actions infos
     * @return the instructions for dispatcher table resubmit
     */
    protected List<InstructionInfo> getDispatcherTableResubmitInstructions(List<ActionInfo> actionsInfos) {
        short dispatcherTableId = NwConstants.LPORT_DISPATCHER_TABLE;
        if (ServiceModeEgress.class.equals(this.serviceMode)) {
            dispatcherTableId = NwConstants.EGRESS_LPORT_DISPATCHER_TABLE;
        }

        List<InstructionInfo> instructions = new ArrayList<>();
        actionsInfos.add(new ActionInfo(ActionType.nx_resubmit, new String[] {Short.toString(dispatcherTableId)}));
        instructions.add(new InstructionInfo(InstructionType.apply_actions, actionsInfos));
        return instructions;
    }

    protected String getOperAsString(int flowOper) {
        String oper;
        switch (flowOper) {
            case NwConstants.ADD_FLOW:
                oper = "Add";
                break;
            case NwConstants.DEL_FLOW:
                oper = "Del";
                break;
            case NwConstants.MOD_FLOW:
                oper = "Mod";
                break;
            default:
                oper = "UNKNOWN";
        }
        return oper;
    }

}
