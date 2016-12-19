/*
 * Copyright (c) 2014 Cisco Systems, Inc. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.neutronvpn;

import com.google.common.base.Predicate;
import com.google.common.base.Predicates;
import com.google.common.collect.Maps;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Queue;
import java.util.Set;
import javax.annotation.Nullable;
import org.opendaylight.controller.md.sal.binding.api.DataObjectModification;
import org.opendaylight.controller.md.sal.binding.api.DataTreeModification;
import org.opendaylight.controller.md.sal.common.api.data.AsyncDataChangeEvent;
import org.opendaylight.yangtools.yang.binding.ChildOf;
import org.opendaylight.yangtools.yang.binding.DataObject;
import org.opendaylight.yangtools.yang.binding.Identifiable;
import org.opendaylight.yangtools.yang.binding.Identifier;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;
import org.opendaylight.yangtools.yang.binding.KeyedInstanceIdentifier;

public class ChangeUtils {

    private ChangeUtils() { }

    private static <T extends DataObject> Predicate<DataObjectModification<T>> hasDataBefore() {
        return new Predicate<DataObjectModification<T>>() {
            @Override
            public boolean apply(@Nullable DataObjectModification<T> input) {
                return input != null && input.getDataBefore() != null;
            }
        };
    }

    private static <T extends DataObject> Predicate<DataObjectModification<T>> hasDataBeforeAndDataAfter() {
        return new Predicate<DataObjectModification<T>>() {
            @Override
            public boolean apply(@Nullable DataObjectModification<T> input) {
                return input != null && input.getDataBefore() != null && input.getDataAfter() != null;
            }
        };
    }

    private static <T extends DataObject> Predicate<DataObjectModification<T>> hasNoDataBefore() {
        return new Predicate<DataObjectModification<T>>() {
            @Override
            public boolean apply(@Nullable DataObjectModification<T> input) {
                return input != null && input.getDataBefore() == null;
            }
        };
    }

    private static <T extends DataObject> Predicate<DataObjectModification<T>> hasDataAfterAndMatchesFilter(
            final Predicate<DataObjectModification<T>> filter) {
        return new Predicate<DataObjectModification<T>>() {
            @Override
            public boolean apply(@Nullable DataObjectModification<T> input) {
                return input != null && input.getDataAfter() != null && filter.apply(input);
            }
        };
    }

    private static <T extends DataObject> Predicate<DataObjectModification<T>> matchesEverything() {
        return new Predicate<DataObjectModification<T>>() {
            @Override
            public boolean apply(@Nullable DataObjectModification<T> input) {
                return true;
            }
        };
    }

    private static <T extends DataObject> Predicate<DataObjectModification<T>> modificationIsDeletion() {
        return new Predicate<DataObjectModification<T>>() {
            @Override
            public boolean apply(@Nullable DataObjectModification<T> input) {
                return input != null && input.getModificationType() == DataObjectModification
                        .ModificationType.DELETE;
            }
        };
    }

    private static <T extends DataObject> Predicate<DataObjectModification<T>>
        modificationIsDeletionAndHasDataBefore() {
        return new Predicate<DataObjectModification<T>>() {
            @Override
            public boolean apply(@Nullable DataObjectModification<T> input) {
                return input != null && input.getModificationType() == DataObjectModification
                        .ModificationType.DELETE && input.getDataBefore() != null;
            }
        };
    }

    public static <T extends DataObject> Map<InstanceIdentifier<T>,T> extractCreated(
            AsyncDataChangeEvent<InstanceIdentifier<?>, DataObject> changes,Class<T> klazz) {
        return extract(changes.getCreatedData(),klazz);
    }

    /**
     * Extract all the instances of {@code clazz} which were created in the given set of modifications.
     *
     * @param changes The changes to process.
     * @param clazz The class we're interested in.
     * @param <T> The type of changes we're interested in.
     * @param <U> The type of changes to process.
     * @return The created instances, mapped by instance identifier.
     */
    public static <T extends DataObject, U extends DataObject> Map<InstanceIdentifier<T>, T> extractCreated(
            Collection<DataTreeModification<U>> changes, Class<T> clazz) {
        return extractCreatedOrUpdated(changes, clazz, hasNoDataBefore());
    }

    public static <T extends DataObject> Map<InstanceIdentifier<T>,T> extractUpdated(
            AsyncDataChangeEvent<InstanceIdentifier<?>,DataObject> changes,Class<T> klazz) {
        return extract(changes.getUpdatedData(),klazz);
    }

    /**
     * Extract all the instances of {@code clazz} which were updated in the given set of modifications.
     *
     * @param changes The changes to process.
     * @param clazz The class we're interested in.
     * @param <T> The type of changes we're interested in.
     * @param <U> The type of changes to process.
     * @return The updated instances, mapped by instance identifier.
     */
    public static <T extends DataObject, U extends DataObject> Map<InstanceIdentifier<T>, T> extractUpdated(
            Collection<DataTreeModification<U>> changes, Class<T> clazz) {
        return extractCreatedOrUpdated(changes, clazz, hasDataBeforeAndDataAfter());
    }

    /**
     * Extract all the instance of {@code clazz} which were created or updated in the given set of modifications, and
     * which satisfy the given filter.
     *
     * @param changes The changes to process.
     * @param clazz The class we're interested in.
     * @param filter The filter the changes must satisfy.
     * @param <T> The type of changes we're interested in.
     * @param <U> The type of changes to process.
     * @return The created or updated instances which satisfy the filter, mapped by instance identifier.
     */
    public static <T extends DataObject, U extends DataObject> Map<InstanceIdentifier<T>, T> extractCreatedOrUpdated(
            Collection<DataTreeModification<U>> changes, Class<T> clazz,
            Predicate<DataObjectModification<T>> filter) {
        Map<InstanceIdentifier<T>, T> result = new HashMap<>();
        for (Map.Entry<InstanceIdentifier<T>, DataObjectModification<T>> entry : extractDataObjectModifications(changes,
                clazz, hasDataAfterAndMatchesFilter(filter)).entrySet()) {
            result.put(entry.getKey(), entry.getValue().getDataAfter());
        }
        return result;
    }

    public static <T extends DataObject> Map<InstanceIdentifier<T>,T> extractCreatedOrUpdated(
            AsyncDataChangeEvent<InstanceIdentifier<?>,DataObject> changes,Class<T> klazz) {
        Map<InstanceIdentifier<T>,T> result = extractUpdated(changes,klazz);
        result.putAll(extractCreated(changes,klazz));
        return result;
    }

    /**
     * Extract all the instances of {@code clazz} which were created or updated in the given set of modifications.
     *
     * @param changes The changes to process.
     * @param clazz The class we're interested in.
     * @param <T> The type of changes we're interested in.
     * @param <U> The type of changes to process.
     * @return The created or updated instances, mapped by instance identifier.
     */
    public static <T extends DataObject, U extends DataObject> Map<InstanceIdentifier<T>, T> extractCreatedOrUpdated(
            Collection<DataTreeModification<U>> changes, Class<T> clazz) {
        return extractCreatedOrUpdated(changes, clazz, matchesEverything());
    }

    public static <T extends DataObject> Map<InstanceIdentifier<T>, T> extractCreatedOrUpdatedOrRemoved(
            AsyncDataChangeEvent<InstanceIdentifier<?>, DataObject> changes,
            Class<T> klazz) {
        Map<InstanceIdentifier<T>,T> result = extractCreatedOrUpdated(changes,klazz);
        result.putAll(extractRemovedObjects(changes, klazz));
        return result;
    }

    /**
     * Extract all the instances of {@code clazz} which were created, updated, or removed in the given set of
     * modifications. For instances which were created or updated, the new instances are returned; for instances
     * which were removed, the old instances are returned.
     *
     * @param changes The changes to process.
     * @param clazz The class we're interested in.
     * @param <T> The type of changes we're interested in.
     * @param <U> The type of changes to process.
     * @return The created, updated or removed instances, mapped by instance identifier.
     */
    public static <T extends DataObject, U extends DataObject> Map<InstanceIdentifier<T>, T>
        extractCreatedOrUpdatedOrRemoved(
            Collection<DataTreeModification<U>> changes, Class<T> clazz) {
        Map<InstanceIdentifier<T>, T> result = extractCreatedOrUpdated(changes, clazz);
        result.putAll(extractRemovedObjects(changes, clazz));
        return result;
    }

    public static <T extends DataObject> Map<InstanceIdentifier<T>,T> extractOriginal(
            AsyncDataChangeEvent<InstanceIdentifier<?>,DataObject> changes,Class<T> klazz) {
        return extract(changes.getOriginalData(),klazz);
    }

    /**
     * Extract the original instances of class {@code clazz} in the given set of modifications.
     *
     * @param changes The changes to process.
     * @param clazz The class we're interested in.
     * @param <T> The type of changes we're interested in.
     * @param <U> The type of changes to process.
     * @return The original instances, mapped by instance identifier.
     */
    public static <T extends DataObject, U extends DataObject> Map<InstanceIdentifier<T>, T> extractOriginal(
            Collection<DataTreeModification<U>> changes, Class<T> clazz) {
        Map<InstanceIdentifier<T>, T> result = new HashMap<>();
        for (Map.Entry<InstanceIdentifier<T>, DataObjectModification<T>> entry :
                extractDataObjectModifications(changes, clazz, hasDataBefore()).entrySet()) {
            result.put(entry.getKey(), entry.getValue().getDataBefore());
        }
        return result;
    }

    public static <T extends DataObject> Set<InstanceIdentifier<T>> extractRemoved(
            AsyncDataChangeEvent<InstanceIdentifier<?>,DataObject> changes,Class<T> klazz) {
        Set<InstanceIdentifier<T>> result = new HashSet<>();
        if (changes != null && changes.getRemovedPaths() != null) {
            for (InstanceIdentifier<?> iid : changes.getRemovedPaths()) {
                if (iid.getTargetType().equals(klazz)) {
                    // Actually checked above
                    @SuppressWarnings("unchecked")
                    InstanceIdentifier<T> iidn = (InstanceIdentifier<T>)iid;
                    result.add(iidn);
                }
            }
        }
        return result;
    }

    /**
     * Extract the instance identifier of removed instances of {@code clazz} from the given set of modifications.
     *
     * @param changes The changes to process.
     * @param clazz The class we're interested in.
     * @param <T> The type of changes we're interested in.
     * @param <U> The type of changes to process.
     * @return The instance identifiers of removed instances.
     */
    public static <T extends DataObject, U extends DataObject> Set<InstanceIdentifier<T>> extractRemoved(
            Collection<DataTreeModification<U>> changes, Class<T> clazz) {
        return extractDataObjectModifications(changes, clazz, modificationIsDeletion()).keySet();
    }

    /**
     * Extract all the modifications affecting instances of {@code clazz} which are present in the given set of
     * modifications and satisfy the given filter.
     *
     * @param changes The changes to process.
     * @param clazz The class we're interested in.
     * @param filter The filter the changes must satisfy.
     * @param <T> The type of changes we're interested in.
     * @param <U> The type of changes to process.
     * @return The modifications, mapped by instance identifier.
     */
    private static <T extends DataObject, U extends DataObject> Map<InstanceIdentifier<T>, DataObjectModification<T>>
        extractDataObjectModifications(Collection<DataTreeModification<U>> changes, Class<T> clazz,
                                       Predicate<DataObjectModification<T>> filter) {
        List<DataObjectModification<? extends DataObject>> dataObjectModifications = new ArrayList<>();
        List<InstanceIdentifier<? extends DataObject>> paths = new ArrayList<>();
        if (changes != null) {
            for (DataTreeModification<? extends DataObject> change : changes) {
                dataObjectModifications.add(change.getRootNode());
                paths.add(change.getRootPath().getRootIdentifier());
            }
        }
        return extractDataObjectModifications(dataObjectModifications, paths, clazz, filter);
    }

    /**
     * Extract all the modifications affecting instances of {@code clazz} which are present in the given set of
     * modifications and satisfy the given filter.
     *
     * @param changes The changes to process.
     * @param paths The paths of the changes.
     * @param clazz The class we're interested in.
     * @param filter The filter the changes must satisfy.
     * @param <T> The type of changes we're interested in.
     * @return The modifications, mapped by instance identifier.
     */
    private static <T extends DataObject> Map<InstanceIdentifier<T>, DataObjectModification<T>>
        extractDataObjectModifications(
            Collection<DataObjectModification<? extends DataObject>> changes,
            Collection<InstanceIdentifier<? extends DataObject>> paths, Class<T> clazz,
            Predicate<DataObjectModification<T>> filter) {
        Map<InstanceIdentifier<T>, DataObjectModification<T>> result = new HashMap<>();
        Queue<DataObjectModification<? extends DataObject>> remainingChanges = new LinkedList<>(changes);
        Queue<InstanceIdentifier<? extends DataObject>> remainingPaths = new LinkedList<>(paths);
        while (!remainingChanges.isEmpty()) {
            DataObjectModification<? extends DataObject> change = remainingChanges.remove();
            InstanceIdentifier<? extends DataObject> path = remainingPaths.remove();
            // Is the change relevant?
            if (clazz.isAssignableFrom(change.getDataType()) && filter.apply((DataObjectModification<T>) change)) {
                result.put((InstanceIdentifier<T>) path, (DataObjectModification<T>) change);
            }
            // Add any children to the queue
            for (DataObjectModification<? extends DataObject> child : change.getModifiedChildren()) {
                remainingChanges.add(child);
                remainingPaths.add(extendPath(path, child));
            }
        }
        return result;
    }

    /**
     * Extends the given instance identifier path to include the given child. Augmentations are treated in the same way
     * as children; keyed children are handled correctly.
     *
     * @param path The current path.
     * @param child The child modification to include.
     * @return The extended path.
     */
    private static <N extends Identifiable<K> & ChildOf<? super T>, K extends Identifier<N>, T extends DataObject>
        InstanceIdentifier<? extends DataObject> extendPath(
            InstanceIdentifier path,
            DataObjectModification child) {
        Class<N> item = (Class<N>) child.getDataType();
        if (child.getIdentifier() instanceof InstanceIdentifier.IdentifiableItem) {
            K key = (K) ((InstanceIdentifier.IdentifiableItem) child.getIdentifier()).getKey();
            KeyedInstanceIdentifier<N, K> extendedPath = path.child(item, key);
            return extendedPath;
        } else {
            InstanceIdentifier<N> extendedPath = path.child(item);
            return extendedPath;
        }
    }

    public static <T extends DataObject> Map<InstanceIdentifier<T>, T> extractRemovedObjects(
            AsyncDataChangeEvent<InstanceIdentifier<?>, DataObject> changes,
            Class<T> klazz) {
        Set<InstanceIdentifier<T>> iids = extractRemoved(changes, klazz);
        return Maps.filterKeys(extractOriginal(changes, klazz),Predicates.in(iids));
    }

    /**
     * Extract the removed instances of {@code clazz} from the given set of modifications.
     *
     * @param changes The changes to process.
     * @param clazz The class we're interested in.
     * @param <T> The type of changes we're interested in.
     * @param <U> The type of changes to process.
     * @return The removed instances, keyed by instance identifier.
     */
    public static <T extends DataObject, U extends DataObject> Map<InstanceIdentifier<T>, T> extractRemovedObjects(
            Collection<DataTreeModification<U>> changes, Class<T> clazz) {
        Map<InstanceIdentifier<T>, T> result = new HashMap<>();
        for (Map.Entry<InstanceIdentifier<T>, DataObjectModification<T>> entry :
                extractDataObjectModifications(changes, clazz, modificationIsDeletionAndHasDataBefore()).entrySet()) {
            result.put(entry.getKey(), entry.getValue().getDataBefore());
        }
        return result;
    }

    public static <T extends DataObject> Map<InstanceIdentifier<T>,T> extract(
            Map<InstanceIdentifier<?>, DataObject> changes, Class<T> klazz) {
        Map<InstanceIdentifier<T>,T> result = new HashMap<>();
        if (changes != null) {
            for (Entry<InstanceIdentifier<?>, DataObject> created : changes.entrySet()) {
                if (klazz.isInstance(created.getValue())) {
                    @SuppressWarnings("unchecked")
                    T value = (T) created.getValue();
                    Class<?> type = created.getKey().getTargetType();
                    if (type.equals(klazz)) {
                        // Actually checked above
                        @SuppressWarnings("unchecked")
                        InstanceIdentifier<T> iid = (InstanceIdentifier<T>) created.getKey();
                        result.put(iid, value);
                    }
                }
            }
        }
        return result;
    }
}
