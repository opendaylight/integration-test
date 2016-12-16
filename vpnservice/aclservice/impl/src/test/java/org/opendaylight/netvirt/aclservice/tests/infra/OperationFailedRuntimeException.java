/*
 * Copyright (c) 2016 Red Hat, Inc. and others. All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.aclservice.tests.infra;

import org.opendaylight.yangtools.yang.common.OperationFailedException;

/**
 * RuntimeException wrapper around OperationFailedException.
 *
 * @author Michael Vorburger
 */
public class OperationFailedRuntimeException extends RuntimeException {

    private static final long serialVersionUID = 1L;

    public OperationFailedRuntimeException(OperationFailedException cause) {
        super(cause);
    }

}
