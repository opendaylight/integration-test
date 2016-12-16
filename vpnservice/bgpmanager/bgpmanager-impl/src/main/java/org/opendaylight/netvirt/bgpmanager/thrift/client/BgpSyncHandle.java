/*
 * Copyright (c) 2015 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */

package org.opendaylight.netvirt.bgpmanager.thrift.client;

import java.io.IOException;
import java.net.Socket;
import java.net.SocketException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class BgpSyncHandle {
    private static BgpSyncHandle handle = null;
    private static final Logger LOGGER = LoggerFactory.getLogger(BgpSyncHandle.class);
    private int more;
    private int state;

    public static final int INITED = 1;
    public static final int ITERATING = 2;
    public static final int DONE = 3;
    public static final int ABORTED = 4;
    public static final int NEVER_DONE = 5;

    public static final int DEFAULT_TCP_SOCK_SZ = 87380;    //default receive buffer size on linux > 2.4

    private BgpSyncHandle() {
        more = 1; 
        state = NEVER_DONE;
    }

    public static synchronized BgpSyncHandle getInstance() {
       if (handle == null) {
           handle = new BgpSyncHandle();
       }
       return handle;
    }

    public synchronized int getState() {
       return state;
    }

    public int getMaxCount() {
        //compute the max count of routes we would like to send
        Socket skt = new Socket();
        int sockBufSz = DEFAULT_TCP_SOCK_SZ;
        try {
            sockBufSz = skt.getReceiveBufferSize();
        } catch (SocketException s) {
            LOGGER.warn("Socket Exception while retrieving default socket buffer size");
        }
        try {
            skt.close();
        } catch (IOException e) {
            LOGGER.warn("IO Exception while closing socket for retrieving default socket buffer size");
        }
        return sockBufSz/getRouteSize();
    }

    public int getRouteSize() {
       //size of one update structure on the wire. ideally
       //this should be computed; or thrift sure has a nice
       //way to tell this to the applciation, but for the
       //moment, we just use 8 bytes more than the size of 
       //the C struct. 

       return 96;
    }

    public int setState(int state) {
       int retval = this.state;
       this.state = state;
       return retval;
    }

    public int setMore(int more) {
       int retval = this.more;
       this.more = more;
       return retval;
    }
}

        
  
