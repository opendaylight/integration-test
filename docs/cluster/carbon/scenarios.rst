Description of test scenarios
:::::::::::::::::::::::::::::

This is a test plan written around M1 of Carbon cycle.

During the cycle several limitations were found,
which resulted in tests which implement the scenarios
is ways different from what is described here.

For list of limitations and differences, see `caveats page <caveats.html>`_.
For more detailed descriptions of test cases as implemented, see `test description page <tests.html>`_.

Controller Cluster Service Functional Tests
===========================================
The purpose of functional tests is to establish a known baseline behavior
for basic services exposed to application plugins when the cluster member nodes encounter problems.

Isolation Mechanics
 Three-node scenarios executed in tests below need to be repeated for three distinct modes of isolation:

 1) JVM freeze, initiated by 'kill -STOP <pid>' on the JVM process,
    followed by a 'kill -CONT <pid>' after three minutes. This simulates
    a long-running garbage collection cycle, VM suspension or similar,
    after which the JVM recovers without losing state and scheduled timers going off simultaneously.
 2) Network-level isolation via firewalling. Simulates a connectivity issue between member nodes,
    while all nodes continue to work as usual. This should be done
    by firewalling all traffic to and from the target node.
 3) JVM restart. This simulates a hard error, such as JVM error, VM reboot, and similar.
    The JVM loses its state and the scenario tests whether the failed node
    is able to result its operations as a member of the cluster.

Leader Shutdown
 The Shard implementation allows a leader to be shut down at run time,
 which is expected to perform a clean hand over to a new leader, elected from the remaining shard members.

DOMDataBroker
^^^^^^^^^^^^^
Also known as 'the datastore', provides MVCC transaction and data change notifications.

Leader Stability
----------------
The goal is to ensure that a single-established shard does not flap,
i.e. does not trigger leader movement by causing crashes or timeouts.
This is performed by having the BGP load generator
run injection of 1 million prefixes, followed by their removal.

This test is executed in three scenarios:

+ Single node
+ Three-node, with shard leader being local
+ Three-node, with shard leader being remote

Success criteria are:

+ Both injection and removal succeed
+ No transaction errors reported to the generator
+ No leader movement on the backend

Clean Leader Shutdown
---------------------
The goal is to ensure that applications do not observe disruption
when a shard leader is shut down cleanly. This is performed by having
a steady-stream producer execute operations against the shard
and then initiate leader shard shutdown, then the producer is shut down cleanly.

This test is executed in two scenarios:

+ Three-node, with shard leader being local
+ Three-node, with shard leader being remote

Success criteria are:

+ No transaction errors occur
+ Producer shuts down cleanly (i.e. all transactions complete successfully)

Test tool: *test-transaction-producer*, running at 1K tps

+ Steady, configurable producer started with:

 + A transaction chain
 + Single transactions (note: these cannot overlap)

+ Configurable transaction rate (i.e. transactions-per-second)
+ Single-operation transactions
+ Random mix across 1M entries

Explicit Leader Movement
------------------------
The goal is to ensure that applications do not observe disruption
when a shard leader is moved as the result of explicit application request.
This is performed by having a steady-stream producer execute operations
against the shard and then initiate shard leader shutdown,
then the producer is shut down cleanly.

This test is executed in three scenarios:

+ Three-node, with shard leader being local and becoming remote
+ Three-node, with shard leader being remote and remaining remote
+ Three-node, with shard leader being remote and becoming local

Success criteria are:

+ No transaction errors occur
+ Producer shuts down cleanly (i.e. all transactions complete successfully)

Test tool: test-transaction-producer, running at 1K tps
Test tool: *test-leader-mover*

+ Uses cds-dom-api to request shard movement

Leader Isolation
----------------
The goal is to ensure the datastore succeeds in basic isolation/rejoin scenario,
simulating either a network partition, or a prolonged GC pause.

This test is executed in the following two scenarios:

+ Three-node, partition heals within TRANSACTION_TIMEOUT
+ Three-node, partition heals after 2*TRANSACTION_TIMEOUT

Using following steps:

1) Start test-transaction producer, running at 1K tps, non-overlapping, from all nodes to a single shard
2) Isolate leader
3) Wait for followers to initiate election
4) Un-isolate leader
5) Wait for partition to heal
6) Restart failed producer

Success criteria:

+ Followers win election in 3
+ No transaction failures occur if the partition is healed within TRANSACTION_TIMEOUT
+ Producer on old leader works normally after step 6)

Test tool: test-transaction-producer

Client Isolation
----------------
The purpose of this test is to ascertain that the failure modes of cds-access-client work as expected.
This is performed by having a steady stream of transactions flowing from the frontend
and isolating the node hosting the frontend from the rest of the cluster.

This test is executed in one scenario:

+ Three node,  test-transaction-producer running on a non-leader
+ Three node,  test-transaction-producer running on the leader

Success criteria:

+ After TRANSACTION_TIMEOUT failures occur
+ After HARD_TIMEOUT client aborts

Test tool: test-transaction-producer

Listener Isolation
------------------
The goal is to ensure listeners do no observe disruption when the leader moves.
This is performed by having a steady stream of transactions
being observed by the listeners and having the leader move.

This test is executed in two scenarios:

+ Three node,  test-transaction-listener running on the leader
+ Three node,  test-transaction-listener running on a non-leader

Using these steps:

+ Start the listener on target node
+ Start test-transaction-producer on each node, with 1K tps, non-overlapping data
+ Trigger shard movement by shutting down shard leader
+ Stop producers without erasing data
+ Stop listener

Success criteria:

+ Listener-internal data tree has to match data stored in the data tree

Test tool: *test-transaction-listener*

+ Subscribes a DTCL to multiple subtrees (as specified)
+ DTCL applies reported changes to an internal DataTree

DOMRpcBroker
^^^^^^^^^^^^
Responsible for routing RPC requests to their implementations and routing responses back to the caller.

RPC Provider Precedence
-----------------------
The aim is to establish that remote RPC implementations have lower priority
than local ones, which is to say that any movement of RPCs on remote nodes
does not affect routing as long as a local implementation is available.

Test is executed only in a three-node scenario, using the following steps:

1) Register an RPC implementation on each node
2) Invoke RPC on each node
3) Unregister implementation on one node
4) Invoke RPC on that node
5) Re-register implementation on than node
6) Invoke RPC on that node

Success criteria:

+ Invocation in steps 2) and 6) results in a response from local node
+ Invocation in step 4) results in a response from one of the other two nodes

RPC Provider Partition and Heal
-------------------------------
This tests establishes that the RPC service operates correctly when faced with node failures.

Test is executed only in a three-node scenario, using the following steps:

1) Register an RPC implementation on two nodes
2) Invoke RPC on each node
3) Isolate one of the nodes where RPC is registered
4) Invoke RPC on each node
5) Un-isolate the node
6) Invoke RPC on all nodes

Success criteria:

+ Step 2) routes the RPC the node nearest node (local or remote)
+ Step 4) works, routing the RPC request to the implementation in the same partition
+ Step 6) routes the RPC the node nearest node (local or remote)

Action Provider Precedence
--------------------------
The aim is to establish that remote action implementations have lower priority than local ones,
which is to say that any movement of actions on remote nodes does not affect routing
as long as a local implementation is available.

Test is executed only in a three-node scenario, using the following steps:

1) Register an action implementation on each node
2) Invoke action on each node
3) Unregister implementation on one node
4) Invoke action on that node
5) Re-register implementation on than node
6) Invoke action on that node

Success criteria:

+ Invocation in steps 2) and 6) results in a response from local node
+ Invocation in step 4) results in a response from one of the other two nodes

Action Provider Partition and Heal
----------------------------------
This tests establishes that the RPC service for actions operates correctly when faced with node failures.

Test is executed only in a three-node scenario, using the following steps:

1) Register an action implementation on two nodes
2) Invoke action on each node
3) Isolate one of the nodes where RPC is registered
4) Invoke action on each node
5) Un-isolate the node
6) Invoke action on all nodes

Success criteria:

+ Step 2) routes the action request the node nearest node (local or remote)
+ Step 4) works, routing the action request to the implementation in the same partition
+ Step 6) routes the RPC the node nearest node (local or remote)

DOMNotificationBroker
^^^^^^^^^^^^^^^^^^^^^
Provides routing of YANG notifications from publishers to subscribers.

No-loss rate
------------
The purpose of this test is to determine the broker can forward messages without loss.
We do this on a single-node setup by incrementally adding publishers and subscribers.

This test is executed in one scenario:

+ Single-node

Steps:

+ Start test-notification-subscriber
+ Start test-notification-publisher at 5K notifications/sec
+ Run for 5 minutes, verify no notifications lost
+ Add another pair of publisher/subscriber, repeat for rate of 60K notifications/sec

Success criteria:

+ No notifications lost at rate of 60K notifications/sec

Test tool: *test-notification-publisher*

+ Publishes notifications containing instance id and sequence number
+ Configurable rate (i.e. notifications-per-second)

Test tool: *test-notification-subscriber*

+ Subscribes to specified notifications from publisher
+ Verifies notification sequence numbers
+ Records total number of notifications received and number of sequence errors

Cluster Singleton
^^^^^^^^^^^^^^^^^
Cluster Singleton service is designed to ensure that
only one instance of an application is registered globally in the cluster.

Master Stability
----------------
The goal is to establish the service operates correctly in face of application registration changing
without moving the active instance.

The test is performed in a three-node cluster using following steps:

1) Register candidate on each node
2) Wait for master activation
3) Remove non-master candidate,
4) Wait one minute
5) Restore the removed candidate

Success criteria:

+ After step 2) there is exactly one master in the cluster
+ The master does not move to a different node for the duration of the test

Partition and Heal
------------------
The goal is to establish the service operates correctly in face of node failures.

The test is performed in a three-node cluster using following steps:

1) Register candidate on each node
2) Wait for master activation
3) Isolate master node
4) Wait two minutes
5) Un-isolate (former) master node
6) Wait one minute

Success criteria:

+ After step 3), master instance is brought down on isolated node
+ During step 4) majority partition elects a new master
+ Until 5) occurs, old master remains deactivated
+ After 6) old master remains deactivated

Chasing the Leader
------------------
This test aims to establish the service operates correctly
when faced with rapid application transitions without having a stabilized application.

This test is performed in a three-node setup using the following steps:

1) Register a candidate on each node
2) Wait for master activation
3) Newly activated master unregisters itself
4) Repeat 2

Success criteria:

+ No failures occur for 5 minutes
+ Transition speed is at least 100 movements per second

Controller Cluster Services Longevity Tests
===========================================
DOMNotificationBroker
^^^^^^^^^^^^^^^^^^^^^

1) Run No-Loss Rate test for 24 hours. No message loss, instability or memory leaks may occur.

DOMDataBroker
^^^^^^^^^^^^^

2) Repeat Leader Stability test for 24 hours. No transaction failures, instability, leader movement or memory leaks may occur.
3) Repeat Explicit Leader Movement test for 24 hours. No transaction failures, instability, leader movement or memory leaks may occur.

DOMRpcBroker
^^^^^^^^^^^^

4) Repeat RPC Provider Precedence test for 24 hours. No failures or memory leaks may occur.
5) Repeat RPC partition and Heal test for 24 hours. No failures or memory leaks may occur.

Cluster Singleton
^^^^^^^^^^^^^^^^^

6) Repeat Chasing the Leader test for 24 hours. No memory leaks or failures may occur.
7) Repeat Partition and Heal test for 24 hours. No memory leaks or failures may occur.

NETCONF System Tests
====================
Netconf is an MD-SAL application, which listens to config datastore changes,
registers a singleton for every configured device, instantiated singleton is updating device connection data
in operational datastore, maintaining a mount point and handling access to the mounted device.

Basic configuration and mount point access
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
No disruptions, ordinary netconf operation with restconf calls to different cluster members.

Test is executed in a three-node scenario, using the following steps:

1) Configure connection to test device on member-1.
2) Create, update and delete data on the device using calls to member-2.
3) Each state change confirmed by reading device data on member-3.
4) De-configure the device connection.

Success criteria:

+ All reads confirm data operations are applied correctly.

Device owner killed
^^^^^^^^^^^^^^^^^^^
Killing current device owner leads to electing new owner. Operations are still applied.

The test is performed in a three-node cluster using following steps:

1) Configure connection to test device on member-1.
2) Create data on the device using a call to member-2.
3) Locate and kill the device owner member.
4) Wait for a new owner to get elected.
5) Update data on the device using a call to one of the surviving members.
6) Restart the killed member.
7) Update the data again using a call to the restarted member.

Success criteria:

+ Each operation (including restart) is confirmed by reads on all members currently up.

Rolling restarts
^^^^^^^^^^^^^^^^
Each member is restarted (start is waiting for cluster sync) in succession,
this is to guarantee each Leader is affected.

The test is performed in a three-node cluster using following steps:

1)  Configure connection to test device on member-1.
2)  Kill member-1.
3)  Create data on the device using a call to member-2.
4)  Start member-1.
5)  Kill member-2.
6)  Update data on the device using a call to member-3.
7)  Start member-2.
8)  Kill member-3.
9)  Delete data on the device using a call to member-1.
10) Start member-3.

Success criteria:

+ After every operation, reads on both living members confirm it was applied.
+ After every start, a read on the started node confirms it sees the device data from the previous operation.
