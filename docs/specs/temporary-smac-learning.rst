=============================
Temporary Source MAC Learning
=============================
https://git.opendaylight.org/gerrit/#/q/topic:temp-smac-learning

Temporary source MAC learning introduces two new tables to the ELAN service, for OVS-based source MAC learning using a learn action,
to reduce a large scale of packets punted to the controller for an unlearned source MAC.

Problem description
===================
Currently any packet originating from an unknown source MAC address is punted to the controller from the ELAN service (L2 SMAC table 50). 

This behavior continues for each packet from this source MAC until ODL properly processes this packet and adds an explicit source MAC rule to this table.

During the time that is required to punt a packet, process it by the ODL and create an appropriate flow, it is not necessary to punt any other packet from this source MAC, as it causes an unnecessary load.

Use Cases
---------
Any L2 traffic from unknown source MACs passing through the ELAN service.

Proposed change
===============
A preliminary logic will be added prior to the SMAC learning table,
that will use OpenFlow learn action to add a temporary rule for each
source MAC after the first packet is punted.

Pipeline changes
----------------
Two new tables will be introduced to the ELAN service:

| **Table 48** for resubmitting to tables 49 and 50 (trick required to use the learned flows, similar to the ACL implementation).
| **Table 49** for setting a register value to mark that this SMAC was already punted to the ODL for learning. The flows in this table will be generated automatically by OVS.
| **Table 50** will be modified, with a new flow, which has a lower priority than the existing known SMAC flows but a higher priority than the default flow. This flow passes packets marked with the register directly to the DMAC table 51 without punting to the controller, as it is already being processed. In addition, the default flow that punts packets to the controller, will also have a new learn action, temporarily adding a flow matching this source MAC to table 49.

**Example of flows after change:**

  .. code-block:: bash

     cookie=0x8040000, duration=1575.755s, table=17, n_packets=7865, n_bytes=1451576, priority=6,metadata=0x6000020000000000/0xffffff0000000000 actions=write_metadata:0x7000021389000000/0xfffffffffffffffe,goto_table:48
     cookie=0x8500000, duration=1129.530s, table=48, n_packets=4149, n_bytes=729778, priority=0 actions=resubmit(,49),resubmit(,50)
     cookie=0x8600000, duration=6.875s, table=49, n_packets=0, n_bytes=0, hard_timeout=60, priority=0,dl_src=fa:16:3e:2f:73:61 actions=load:0x1->NXM_NX_REG4[0..7]
     cookie=0x8051389, duration=7.078s, table=50, n_packets=0, n_bytes=0, priority=20,metadata=0x21389000000/0xfffffffff000000,dl_src=fa:16:3e:2f:73:61 actions=goto_table:51
     cookie=0x8050000, duration=440.925s, table=50, n_packets=49, n_bytes=8030, priority=10,reg4=0x1 actions=goto_table:51
     cookie=0x8050000, duration=124.209s, table=50, n_packets=68, n_bytes=15193, priority=0 actions=CONTROLLER:65535,learn(table=49,hard_timeout=60,priority=0,cookie=0x8600000,NXM_OF_ETH_SRC[],load:0x1->NXM_NX_REG4[0..7]),goto_table:51

Yang changes
------------
None.

Configuration impact
---------------------
None.

Clustering considerations
-------------------------
None.

Other Infra considerations
--------------------------
None.

Security considerations
-----------------------
None.

Scale and Performance Impact
----------------------------
This change should substantially reduce the packet in load from SMAC learning, resulting in a reduced load of the ODL in high performance traffic scenarios.

Targeted Release
-----------------
Due to scale and performance criticality, and the low risk of this feature, suggest to target this functionality for Boron.

Alternatives
------------
None.

Usage
=====
N/A.

Features to Install
-------------------
odl-netvirt-openstack

REST API
--------
N/A.

CLI
---
N/A.

Implementation
==============

Assignee(s)
-----------
Who is implementing this feature? In case of multiple authors, designate a primary assigne and other contributors.

Primary assignee:
  Olga Schukin (olga.schukin@hpe.com)
Other contributors:
  Alon Kochba (alonko@hpe.com)

Work Items
----------
N/A.

Dependencies
============
No new dependencies.
Learn action is already in use in netvirt pipeline and has been available in OVS since early versions. However this is a non-standard OpenFlow feature.

Testing
=======
Existing source MAC learning functionality should be verified.

Unit Tests
----------
N/A.

Integration Tests
-----------------
N/A.

CSIT
----
N/A.

Documentation Impact
====================
Pipeline documentation should be updated accordingly to reflect the changes to the ELAN service.
