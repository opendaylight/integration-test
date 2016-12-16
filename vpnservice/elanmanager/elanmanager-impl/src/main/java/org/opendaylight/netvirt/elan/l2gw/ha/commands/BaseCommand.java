/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.elan.l2gw.ha.commands;

import com.google.common.collect.Lists;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

public abstract class BaseCommand<T> {

    /**
     * Abstract method give diff between two List passed based on comparator.
     * @param updated Updated List
     * @param original Origina list to be compared with
     * @param comparator based on which diff will be returned
     * @return List of diff based on comparator
     */
    public <T> List<T> diffOf(List<T> updated, final List<T> original, final Comparator comparator) {
        if (updated == null) {
            return Lists.newArrayList();
        }
        if (original == null) {
            return new ArrayList<>(updated);
        }

        List<T> result = new ArrayList<>();
        for (T ele : updated) {
            boolean present = false;
            for (T orig : original) {
                if (0 == comparator.compare(ele, orig)) {
                    present = true;
                    break;
                }
            }
            if (!present) {
                result.add(ele);
            }
        }
        return result;
    }

    /**
     * Abstract method give diff between two List passed.
     * @param updated Updated List
     * @param original Origina list to be compared with
     * @return List of diff based
     */
    public List<T> diffOf(List<T> updated, final List<T> original) {
        if (updated == null) {
            return Lists.newArrayList();
        }
        if (original == null) {
            return new ArrayList<>(updated);
        }
        List<T> result = new ArrayList<>();
        for (T ele : updated) {
            boolean present = false;
            for (T orig : original) {
                if (areEqual(ele, orig)) {
                    present = true;
                    break;
                }
            }
            if (!present) {
                result.add(ele);
            }
        }
        return result;
    }

    public abstract boolean areEqual(T objA, T objB);

}
