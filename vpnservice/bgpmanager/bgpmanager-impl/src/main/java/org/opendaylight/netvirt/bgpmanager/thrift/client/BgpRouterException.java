/*
 * Copyright (c) 2015 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.bgpmanager.thrift.client;

import org.opendaylight.netvirt.bgpmanager.thrift.gen.qbgpConstants;

public class BgpRouterException extends Exception {
    public final static int BGP_ERR_INITED = 101;
    public final static int BGP_ERR_NOT_INITED = 102;
    public final static int BGP_ERR_IN_ITER =  103;

    // the following consts are server-dictated. do not modify
    public final static int BGP_ERR_FAILED = qbgpConstants. BGP_ERR_FAILED;
    public final static int BGP_ERR_ACTIVE = qbgpConstants.BGP_ERR_ACTIVE;
    public final static int BGP_ERR_INACTIVE = qbgpConstants.BGP_ERR_INACTIVE; 
    public final static int BGP_ERR_NOT_ITER =  qbgpConstants.BGP_ERR_NOT_ITER;
    public final static int BGP_ERR_PARAM = qbgpConstants.BGP_ERR_PARAM;

    private int errcode;

    public BgpRouterException(int cause) {
        errcode = cause;
    }

    public int getErrorCode() {
        return errcode;
    }

    public String toString() {
      String s = "("+errcode+") ";

      switch (errcode) {
        case BGP_ERR_INITED :
            s += "Attempt to reinitialize BgpRouter thrift client";
            break;
        case BGP_ERR_NOT_INITED :
            s += "BgpRouter thrift client was not initialized";
            break;
        case BGP_ERR_FAILED :
            s += "Error reported by BGP, check qbgp.log";
            break;
        case BGP_ERR_ACTIVE : 
            s += "Attempt to start router instance when already active";
            break;
        case BGP_ERR_INACTIVE : 
            s += "Router instance is not active";
            break;
        case BGP_ERR_IN_ITER :
            s += "Attempt to start route iteration when already "+
                 "in the middle of one";
            break;
        case BGP_ERR_NOT_ITER :
            s += "Route iteration not initialized";
            break;
        case BGP_ERR_PARAM :
            s += "Parameter validation or Unknown error";
            break;
        default : 
            s += "Unknown error";
            break;
     }
     return s;
   }
}
