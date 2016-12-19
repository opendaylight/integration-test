/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.aclservice.api.utils;

import java.math.BigInteger;
import java.util.List;

import org.opendaylight.yang.gen.v1.urn.ietf.params.xml.ns.yang.ietf.yang.types.rev130715.Uuid;
import org.opendaylight.yang.gen.v1.urn.opendaylight.netvirt.aclservice.rev160608.interfaces._interface.AllowedAddressPairs;

/**
 * The Class AclInterface.
 */
public class AclInterface {

    /** The port security enabled. */
    Boolean portSecurityEnabled;

    /** The interface id. */
    String interfaceId;

    /** The l port tag. */
    Integer lportTag;

    /** The dp id. */
    BigInteger dpId;

    /** The security groups. */
    List<Uuid> securityGroups;

    /** The allowed address pairs. */
    List<AllowedAddressPairs> allowedAddressPairs;

    /** The port is marked for delete. */
    Boolean isMarkedForDelete = false;

    /**
     * Checks if is port security enabled.
     *
     * @return the boolean
     */
    public Boolean isPortSecurityEnabled() {
        return portSecurityEnabled;
    }

    /**
     * Gets the port security enabled.
     *
     * @return the port security enabled
     */
    public Boolean getPortSecurityEnabled() {
        return portSecurityEnabled;
    }

    /**
     * Sets the port security enabled.
     *
     * @param portSecurityEnabled the new port security enabled
     */
    public void setPortSecurityEnabled(Boolean portSecurityEnabled) {
        this.portSecurityEnabled = portSecurityEnabled;
    }

    /**
     * Gets the interface id.
     *
     * @return the interface id
     */
    public String getInterfaceId() {
        return interfaceId;
    }

    /**
     * Sets the interface id.
     *
     * @param interfaceId the new interface id
     */
    public void setInterfaceId(String interfaceId) {
        this.interfaceId = interfaceId;
    }

    /**
     * Gets the l port tag.
     *
     * @return the l port tag
     */
    public Integer getLPortTag() {
        return lportTag;
    }

    /**
     * Sets the l port tag.
     *
     * @param lportTag the new l port tag
     */
    public void setLPortTag(Integer lportTag) {
        this.lportTag = lportTag;
    }

    /**
     * Gets the dp id.
     *
     * @return the dp id
     */
    public BigInteger getDpId() {
        return dpId;
    }

    /**
     * Sets the dp id.
     *
     * @param dpId the new dp id
     */
    public void setDpId(BigInteger dpId) {
        this.dpId = dpId;
    }

    /**
     * Gets the security groups.
     *
     * @return the security groups
     */
    public List<Uuid> getSecurityGroups() {
        return securityGroups;
    }

    /**
     * Sets the security groups.
     *
     * @param securityGroups the new security groups
     */
    public void setSecurityGroups(List<Uuid> securityGroups) {
        this.securityGroups = securityGroups;
    }

    /**
     * Gets the allowed address pairs.
     *
     * @return the allowed address pairs
     */
    public List<AllowedAddressPairs> getAllowedAddressPairs() {
        return allowedAddressPairs;
    }

    /**
     * Sets the allowed address pairs.
     *
     * @param allowedAddressPairs the new allowed address pairs
     */
    public void setAllowedAddressPairs(List<AllowedAddressPairs> allowedAddressPairs) {
        this.allowedAddressPairs = allowedAddressPairs;
    }

    /**
     * Retrieve isMarkedForDelete.
     * @return the whether it is marked for delete
     */
    public Boolean isMarkedForDelete() {
        return isMarkedForDelete;
    }

    /**
     * Sets isMarkedForDelete.
     * @param isMarkedForDelete boolean value
     */
    public void setIsMarkedForDelete(Boolean isMarkedForDelete) {
        this.isMarkedForDelete = isMarkedForDelete;
    }

    /* (non-Javadoc)
     * @see java.lang.Object#hashCode()
     */
    @Override
    public int hashCode() {
        final int prime = 31;
        int result = 1;
        result = prime * result + ((portSecurityEnabled == null) ? 0 : portSecurityEnabled.hashCode());
        result = prime * result + ((dpId == null) ? 0 : dpId.hashCode());
        result = prime * result + ((interfaceId == null) ? 0 : interfaceId.hashCode());
        result = prime * result + ((lportTag == null) ? 0 : lportTag.hashCode());
        result = prime * result + ((securityGroups == null) ? 0 : securityGroups.hashCode());
        result = prime * result + ((allowedAddressPairs == null) ? 0 : allowedAddressPairs.hashCode());
        result = prime * result + ((isMarkedForDelete == null) ? 0 : isMarkedForDelete.hashCode());
        return result;
    }

    /* (non-Javadoc)
     * @see java.lang.Object#equals(java.lang.Object)
     */
    @Override
    public boolean equals(Object obj) {
        if (this == obj) {
            return true;
        }
        if (obj == null) {
            return false;
        }
        if (getClass() != obj.getClass()) {
            return false;
        }
        AclInterface other = (AclInterface) obj;
        if (portSecurityEnabled == null) {
            if (other.portSecurityEnabled != null) {
                return false;
            }
        } else if (!portSecurityEnabled.equals(other.portSecurityEnabled)) {
            return false;
        }
        if (dpId == null) {
            if (other.dpId != null) {
                return false;
            }
        } else if (!dpId.equals(other.dpId)) {
            return false;
        }
        if (interfaceId == null) {
            if (other.interfaceId != null) {
                return false;
            }
        } else if (!interfaceId.equals(other.interfaceId)) {
            return false;
        }
        if (lportTag == null) {
            if (other.lportTag != null) {
                return false;
            }
        } else if (!lportTag.equals(other.lportTag)) {
            return false;
        }
        if (securityGroups == null) {
            if (other.securityGroups != null) {
                return false;
            }
        } else if (!securityGroups.equals(other.securityGroups)) {
            return false;
        }
        if (allowedAddressPairs == null) {
            if (other.allowedAddressPairs != null) {
                return false;
            }
        } else if (!allowedAddressPairs.equals(other.allowedAddressPairs)) {
            return false;
        }
        if (isMarkedForDelete == null) {
            if (other.isMarkedForDelete != null) {
                return false;
            }
        } else if (!isMarkedForDelete.equals(other.isMarkedForDelete)) {
            return false;
        }
        return true;
    }

    /* (non-Javadoc)
     * @see java.lang.Object#toString()
     */
    @Override
    public String toString() {
        return "AclInterface [portSecurityEnabled=" + portSecurityEnabled + ", interfaceId=" + interfaceId
                + ", lportTag=" + lportTag + ", dpId=" + dpId + ", securityGroups=" + securityGroups
                + ", allowedAddressPairs=" + allowedAddressPairs + ", isMarkedForDelete=" + isMarkedForDelete + "]";
    }
}
