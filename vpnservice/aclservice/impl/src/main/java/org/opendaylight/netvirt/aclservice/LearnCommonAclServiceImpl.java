/*
 * Copyright (c) 2016 HPE, Inc. and others. All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.aclservice;

import java.util.List;

import org.opendaylight.genius.mdsalutil.ActionInfo;
import org.opendaylight.genius.mdsalutil.NwConstants;
import org.opendaylight.netvirt.aclservice.utils.AclConstants;

public class LearnCommonAclServiceImpl {

    protected static String[][] getOtherProtocolsLearnActionMatches(List<ActionInfo> actionsInfos) {
        String[][] flowMod = new String[5][];

        flowMod[0] = new String[] { NwConstants.LearnFlowModsType.MATCH_FROM_VALUE.name(),
                Integer.toString(NwConstants.ETHTYPE_IPV4),
                NwConstants.NxmOfFieldType.NXM_OF_ETH_TYPE.getHexType(),
                NwConstants.NxmOfFieldType.NXM_OF_ETH_TYPE.getFlowModHeaderLen() };
        flowMod[1] = new String[] { NwConstants.LearnFlowModsType.MATCH_FROM_FIELD.name(),
                NwConstants.NxmOfFieldType.NXM_OF_IP_DST.getHexType(),
                NwConstants.NxmOfFieldType.NXM_OF_IP_SRC.getHexType(),
                NwConstants.NxmOfFieldType.NXM_OF_IP_SRC.getFlowModHeaderLen() };
        flowMod[2] = new String[] { NwConstants.LearnFlowModsType.MATCH_FROM_FIELD.name(),
                NwConstants.NxmOfFieldType.NXM_OF_IP_SRC.getHexType(),
                NwConstants.NxmOfFieldType.NXM_OF_IP_DST.getHexType(),
                NwConstants.NxmOfFieldType.NXM_OF_IP_DST.getFlowModHeaderLen() };
        flowMod[3] = new String[] { NwConstants.LearnFlowModsType.MATCH_FROM_FIELD.name(),
                NwConstants.NxmOfFieldType.NXM_OF_IP_PROTO.getHexType(),
                NwConstants.NxmOfFieldType.NXM_OF_IP_PROTO.getHexType(),
                NwConstants.NxmOfFieldType.NXM_OF_IP_PROTO.getFlowModHeaderLen() };
        flowMod[4] = new String[] {
                NwConstants.LearnFlowModsType.COPY_FROM_VALUE.name(), AclConstants.LEARN_MATCH_REG_VALUE,
                NwConstants.NxmOfFieldType.NXM_NX_REG5.getHexType(), "8" };

        return flowMod;
    }

    protected static String[][] getTcpLearnActionMatches() {
        String[][] learnActionMatches = new String[7][];

        learnActionMatches[0] = new String[] { NwConstants.LearnFlowModsType.MATCH_FROM_VALUE.name(),
                Integer.toString(NwConstants.ETHTYPE_IPV4),
                NwConstants.NxmOfFieldType.NXM_OF_ETH_TYPE.getHexType(),
                NwConstants.NxmOfFieldType.NXM_OF_ETH_TYPE.getFlowModHeaderLen() };
        learnActionMatches[1] = new String[] { NwConstants.LearnFlowModsType.MATCH_FROM_VALUE.name(),
                Integer.toString(NwConstants.IP_PROT_TCP),
                NwConstants.NxmOfFieldType.NXM_OF_IP_PROTO.getHexType(),
                NwConstants.NxmOfFieldType.NXM_OF_IP_PROTO.getFlowModHeaderLen() };
        learnActionMatches[2] = new String[] { NwConstants.LearnFlowModsType.MATCH_FROM_FIELD.name(),
                NwConstants.NxmOfFieldType.NXM_OF_IP_SRC.getHexType(),
                NwConstants.NxmOfFieldType.NXM_OF_IP_DST.getHexType(),
                NwConstants.NxmOfFieldType.NXM_OF_IP_DST.getFlowModHeaderLen() };
        learnActionMatches[3] = new String[] { NwConstants.LearnFlowModsType.MATCH_FROM_FIELD.name(),
                NwConstants.NxmOfFieldType.NXM_OF_TCP_SRC.getHexType(),
                NwConstants.NxmOfFieldType.NXM_OF_TCP_DST.getHexType(),
                NwConstants.NxmOfFieldType.NXM_OF_TCP_DST.getFlowModHeaderLen() };
        learnActionMatches[4] = new String[] { NwConstants.LearnFlowModsType.MATCH_FROM_FIELD.name(),
                NwConstants.NxmOfFieldType.NXM_OF_IP_DST.getHexType(),
                NwConstants.NxmOfFieldType.NXM_OF_IP_SRC.getHexType(),
                NwConstants.NxmOfFieldType.NXM_OF_IP_SRC.getFlowModHeaderLen() };
        learnActionMatches[5] = new String[] { NwConstants.LearnFlowModsType.MATCH_FROM_FIELD.name(),
                NwConstants.NxmOfFieldType.NXM_OF_TCP_DST.getHexType(),
                NwConstants.NxmOfFieldType.NXM_OF_TCP_SRC.getHexType(),
                NwConstants.NxmOfFieldType.NXM_OF_TCP_SRC.getFlowModHeaderLen() };
        learnActionMatches[6] = new String[] {
                NwConstants.LearnFlowModsType.COPY_FROM_VALUE.name(), AclConstants.LEARN_MATCH_REG_VALUE,
                NwConstants.NxmOfFieldType.NXM_NX_REG5.getHexType(), "8" };

        return learnActionMatches;
    }

    protected static String[][] getUdpLearnActionMatches() {
        String[][] learnActionMatches = new String[7][];

        learnActionMatches[0] = new String[] { NwConstants.LearnFlowModsType.MATCH_FROM_VALUE.name(),
                Integer.toString(NwConstants.ETHTYPE_IPV4),
                NwConstants.NxmOfFieldType.NXM_OF_ETH_TYPE.getHexType(),
                NwConstants.NxmOfFieldType.NXM_OF_ETH_TYPE.getFlowModHeaderLen() };
        learnActionMatches[1] = new String[] { NwConstants.LearnFlowModsType.MATCH_FROM_VALUE.name(),
                Integer.toString(NwConstants.IP_PROT_UDP),
                NwConstants.NxmOfFieldType.NXM_OF_IP_PROTO.getHexType(),
                NwConstants.NxmOfFieldType.NXM_OF_IP_PROTO.getFlowModHeaderLen() };
        learnActionMatches[2] = new String[] { NwConstants.LearnFlowModsType.MATCH_FROM_FIELD.name(),
                NwConstants.NxmOfFieldType.NXM_OF_IP_SRC.getHexType(),
                NwConstants.NxmOfFieldType.NXM_OF_IP_DST.getHexType(),
                NwConstants.NxmOfFieldType.NXM_OF_IP_SRC.getFlowModHeaderLen() };
        learnActionMatches[3] = new String[] { NwConstants.LearnFlowModsType.MATCH_FROM_FIELD.name(),
                NwConstants.NxmOfFieldType.NXM_OF_UDP_SRC.getHexType(),
                NwConstants.NxmOfFieldType.NXM_OF_UDP_DST.getHexType(),
                NwConstants.NxmOfFieldType.NXM_OF_UDP_SRC.getFlowModHeaderLen() };
        learnActionMatches[4] = new String[] { NwConstants.LearnFlowModsType.MATCH_FROM_FIELD.name(),
                NwConstants.NxmOfFieldType.NXM_OF_IP_DST.getHexType(),
                NwConstants.NxmOfFieldType.NXM_OF_IP_SRC.getHexType(),
                NwConstants.NxmOfFieldType.NXM_OF_IP_SRC.getFlowModHeaderLen() };
        learnActionMatches[5] = new String[] { NwConstants.LearnFlowModsType.MATCH_FROM_FIELD.name(),
                NwConstants.NxmOfFieldType.NXM_OF_UDP_DST.getHexType(),
                NwConstants.NxmOfFieldType.NXM_OF_UDP_SRC.getHexType(),
                NwConstants.NxmOfFieldType.NXM_OF_UDP_SRC.getFlowModHeaderLen() };
        learnActionMatches[6] = new String[] {
                NwConstants.LearnFlowModsType.COPY_FROM_VALUE.name(), AclConstants.LEARN_MATCH_REG_VALUE,
                NwConstants.NxmOfFieldType.NXM_NX_REG5.getHexType(), "8" };

        return learnActionMatches;
    }

}
