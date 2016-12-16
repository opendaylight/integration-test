/*
 * Copyright (c) 2015 Ericsson India Global Services Pvt Ltd. and others.  All rights reserved.
 *
 * This program and the accompanying materials are made available under the
 * terms of the Eclipse Public License v1.0 which accompanies this distribution,
 * and is available at http://www.eclipse.org/legal/epl-v10.html
 */
package org.opendaylight.netvirt.vpnmanager.test;

import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import org.opendaylight.controller.md.sal.common.api.data.AsyncDataChangeEvent;
import org.opendaylight.yangtools.yang.binding.DataObject;
import org.opendaylight.yangtools.yang.binding.InstanceIdentifier;

class MockDataChangedEvent implements AsyncDataChangeEvent<InstanceIdentifier<?>, DataObject> {
  Map<InstanceIdentifier<?>,DataObject> created = new HashMap<>();
  Map<InstanceIdentifier<?>,DataObject> updated = new HashMap<>();
  Map<InstanceIdentifier<?>,DataObject> original = new HashMap<>();
  Set<InstanceIdentifier<?>> removed = new HashSet<>();

  @Override
  public Map<InstanceIdentifier<?>, DataObject> getCreatedData() {
      return created;
  }

  @Override
  public Map<InstanceIdentifier<?>, DataObject> getUpdatedData() {
      return updated;
  }

  @Override
  public Set<InstanceIdentifier<?>> getRemovedPaths() {
      return removed;
  }

  @Override
  public Map<InstanceIdentifier<?>, DataObject> getOriginalData() {
      return original;
  }

  @Override
  public DataObject getOriginalSubtree() {
      throw new UnsupportedOperationException("Not implemented by mock");
  }

  @Override
  public DataObject getUpdatedSubtree() {
      throw new UnsupportedOperationException("Not implemented by mock");
  }
}
