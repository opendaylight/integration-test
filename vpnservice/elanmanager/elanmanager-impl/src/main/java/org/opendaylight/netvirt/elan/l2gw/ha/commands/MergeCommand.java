/*
 * Copyright (c) 2016 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.elan.l2gw.ha.commands;

import static org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType.CONFIGURATION;
import static org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType.OPERATIONAL;
import static org.opendaylight.netvirt.elan.l2gw.ha.HwvtepHAUtil.isEmptyList;

import com.google.common.collect.Lists;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Objects;

import org.opendaylight.controller.md.sal.binding.api.ReadWriteTransaction;
import org.opendaylight.controller.md.sal.common.api.data.LogicalDatastoreType;
import org.opendaylight.netvirt.elan.l2gw.ha.HwvtepHAUtil;
import org.opendaylight.yang.gen.v1.urn.opendaylight.params.xml.ns.yang.ovsdb.hwvtep.rev150901.hwvtep.physical.locator.set.attributes.LocatorSet;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.TpId;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.Node;
import org.opendaylight.yang.gen.v1.urn.tbd.params.xml.ns.yang.network.topology.rev131021.network.topology.topology.node.TerminationPoint;
import org.opendaylight.yangtools.concepts.Builder;
import org.opendaylight.yangtools.yang.binding.DataObject;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;




public abstract class MergeCommand<T extends DataObject, Y extends Builder, Z extends DataObject>
        extends BaseCommand<T> implements IMergeCommand<T, Y, Z> {

    static Logger LOG = LoggerFactory.getLogger(MergeCommand.class);

    public List<T> transformOpData(List<T> existingData, List<T> src, InstanceIdentifier<Node> nodePath) {
        if (isEmptyList(src)) {
            return Lists.newArrayList();
        }
        List<T> added = diffOf(src, existingData);//do not add existing data again
        List<T> transformed = transform(nodePath, added);
        return transformed;
    }

    public List<T> transformConfigData(List<T> updatedSrc, InstanceIdentifier<Node> nodePath) {
        if (isEmptyList(updatedSrc)) {
            return Lists.newArrayList();//what difference returning null makes ?
        }
        List<T> transformed = transform(nodePath, updatedSrc);//set the whole data
        return transformed;
    }

    public List<T> diffByKey(List<T> updated, final List<T> original) {
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
                if (Objects.equals(getKey(ele), getKey(orig))) {
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

    //TODO validate the perf of the following against direct setting of the data in dst node
    public void transformUpdate(List<T> existing,
                                List<T> updated,
                                List<T> orig,
                                InstanceIdentifier<Node> nodePath,
                                LogicalDatastoreType datastoreType,
                                ReadWriteTransaction tx) {

        if (updated == null) {
            updated = new ArrayList<>();
        }
        if (orig == null) {
            orig = new ArrayList<>();
        }
        List<T> added   = new ArrayList<>(updated);

        added.removeAll(orig);
        added = diffOf(added, existing);//do not add the existing data again
        if (added != null && added.size() > 0) {
            for (T addedItem : added) {
                InstanceIdentifier<T> transformedId = generateId(nodePath, addedItem);
                T transformedItem = transform(nodePath, addedItem);
                String nodeId = transformedId.firstKeyOf(Node.class).getNodeId().getValue();
                LOG.trace("adding {} {} {}", getDescription(), nodeId, getKey(transformedItem));
                tx.put(datastoreType, transformedId, transformedItem, true);
            }
        }
        List<T> removed = new ArrayList<>(orig);
        removed = diffByKey(removed, updated);

        List<T> removedTransformed  = new ArrayList<>();
        for (T ele : removed) {
            removedTransformed.add(transform(nodePath, ele));
        }

        List<T> skip = diffByKey(removedTransformed, existing);//skip the ones which are not present in cfg ds
        removedTransformed = diffByKey(removedTransformed, skip);
        if (removedTransformed != null && removedTransformed.size() > 0) {
            for (T removedItem : removedTransformed) {
                InstanceIdentifier<T> transformedId = generateId(nodePath, removedItem);
                String nodeId = transformedId.firstKeyOf(Node.class).getNodeId().getValue();
                LOG.trace("removing {} {} {}",getDescription(), nodeId, getKey(removedItem));
                tx.delete(datastoreType, transformedId);
            }
        }
    }

    public List<T> transform(InstanceIdentifier<Node> nodePath, List<T> list) {
        List<T> result = Lists.newArrayList();
        for (T t : list) {
            result.add(transform(nodePath, t));
        }
        return result;
    }

    public abstract T transform(InstanceIdentifier<Node> nodePath, T objT);

    @Override
    public void mergeOperationalData(Y dst,
                                     Z existingData,
                                     Z src,
                                     InstanceIdentifier<Node> nodePath) {
        List<T> origDstData = getData(existingData);
        List<T> srcData = getData(src);
        List<T> data = transformOpData(origDstData, srcData, nodePath);
        setData(dst, data);
        if (!isEmptyList(data)) {
            String nodeId = nodePath.firstKeyOf(Node.class).getNodeId().getValue();
            LOG.trace("merging op {} to {} size {}",getDescription(), nodeId, data.size());
        }
    }

    @Override
    public void mergeConfigData(Y dst,
                                Z src,
                                InstanceIdentifier<Node> nodePath) {
        List<T> data        = getData(src);
        List<T> transformed = transformConfigData(data, nodePath);
        setData(dst, transformed);
        if (!isEmptyList(data)) {
            String nodeId = nodePath.firstKeyOf(Node.class).getNodeId().getValue();
            LOG.trace("copying config {} to {} size {}",getDescription(), nodeId, data.size());
        }
    }

    @Override
    public void mergeConfigUpdate(Z existing,
                                  Z updated,
                                  Z orig,
                                  InstanceIdentifier<Node> nodePath,
                                  ReadWriteTransaction tx) {
        List<T> updatedData     = getData(updated);
        List<T> origData        = getData(orig);
        List<T> existingData    = getData(existing);
        transformUpdate(existingData, updatedData, origData, nodePath, CONFIGURATION, tx);
    }

    @Override
    public void mergeOpUpdate(Z origDst,
                              Z updatedSrc,
                              Z origSrc,
                              InstanceIdentifier<Node> nodePath,
                              ReadWriteTransaction tx) {
        List<T> updatedData     = getData(updatedSrc);
        List<T> origData        = getData(origSrc);
        List<T> existingData    = getData(origDst);
        transformUpdate(existingData, updatedData, origData, nodePath, OPERATIONAL, tx);
    }

    boolean areSameSize(List objA, List objB) {
        if (HwvtepHAUtil.isEmptyList(objA) && HwvtepHAUtil.isEmptyList(objB)) {
            return true;
        }
        if (!HwvtepHAUtil.isEmptyList(objA) && !HwvtepHAUtil.isEmptyList(objB)) {
            return objA.size() == objB.size();
        }
        return false;
    }


    static LocatorSetComparator locatorSetComparator = new LocatorSetComparator();

    static class LocatorSetComparator implements Comparator<LocatorSet> {
        @Override
        public int compare(final LocatorSet updatedLocatorSet, final LocatorSet origLocatorSet) {
            InstanceIdentifier<?> updatedLocatorRefIndentifier = updatedLocatorSet.getLocatorRef().getValue();
            TpId updatedLocatorSetTpId = updatedLocatorRefIndentifier.firstKeyOf(TerminationPoint.class).getTpId();

            InstanceIdentifier<?> origLocatorRefIndentifier = origLocatorSet.getLocatorRef().getValue();
            TpId origLocatorSetTpId = origLocatorRefIndentifier.firstKeyOf(TerminationPoint.class).getTpId();

            if (updatedLocatorSetTpId.equals(origLocatorSetTpId)) {
                return 0;
            }
            return 1;
        }
    }

    public abstract List<T> getData(Z node);

    public abstract void setData(Y builder, List<T> data);

    protected abstract InstanceIdentifier<T> generateId(InstanceIdentifier<Node> id, T node);

    public abstract String getKey(T data);

    public abstract String getDescription();
}
