/*
 * Copyright (c) 2016 Red Hat, Inc. and others. All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.elan;

public class ElanException extends Exception {
    private static final long serialVersionUID = -2491313989449541864L;

    public ElanException(String message, Throwable cause) {
        super(message, cause);
    }

    public ElanException(String message) {
        super(message);
    }

}
