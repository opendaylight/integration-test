=======
Caveats
=======

This sub-page describes ways the test implementation (or results) differs
from the `original specification <scenarios.html>`_ and which information motivates the difference.

Akka bugs
~~~~~~~~~

These are bugs which need either a fix in Akka codebase,
or a workaround which would be too time-consuming to implement in ODL.

Both bugs manifest as UnreachableMember event (without intentional isolation).

Slow heartbeats
---------------

+ Information

Akka sends periodic heartbeats in order to detect when the other member is being unresponsive.

The heartbeats are being serialized into the same TCP channel as ordinary data,
which means if ODL is processing big amount of data, the heartbeats can spend a long time
in TCP (or other) buffers before being processed. When this time exceeds a specific value
(currently 6 seconds), the peer memeber is declared unreachable, generally leading to leader movement.

This affects BGP test results on 3node setup, as ODL is processing BGP data as quickly as possible,
but the current BGP implementation does not handle rib owner movement gracefully (and leader movement
is explicitly checked by the test as scenario dictates it should not happen).
This does not affect other data broker tests, 1000 transactions per second do not generate critical throughput.

+ Testing consequence

Three test cases are failing due to `Bug 8318 <https://bugs.opendaylight.org/show_bug.cgi?id=8318>`__.

Reachability gossip
-------------------

+ Information

Akka uses a gossip protocol to advertize one member's reachability to other members.
There is a logic which allows for faster detection of unreachable members,
when a member can declare its peer unreachable if it got information from another peer
which is considered more up-to-date.

Ocassionally, this logic results in undesired behavior. This is when the supposedly up-to-date peer
has been isolated and now it is rejoining. Depending on timing, this can introduce additional leader movement,
or a very brief moment when a member "forgets" RPC registrations from other member.

This is causing bugs `8420 <https://bugs.opendaylight.org/show_bug.cgi?id=8420>`__
and `8430 <https://bugs.opendaylight.org/show_bug.cgi?id=8430>`__.

+ Testing consequence

This affects "partition and heal" scenarios for RPC and singleton testing.
In functional tests, the failures are infrequent enough to consider the test mostly stable overall,
but the corresponding longevity jobs are failing consistently.

Missing features
~~~~~~~~~~~~~~~~

Cluster yang notifications
--------------------------

+ Information

Yang notifications are not delivered to peer members.
`Bug 2139 <https://bugs.opendaylight.org/show_bug.cgi?id=2139>`__
is only fixed for data change notifications, not Yang notifications.

TODO: Add a link to the Bug which tracks adding this missing functionality.

+ Testing consequence

Notification suites are running on 1-node setup only.

Reduced Singleton performance
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

+ Information

Carbon is missing `an improvement <https://bugs.opendaylight.org/show_bug.cgi?id=7855>`__
which limits java test implementation.

+ Testing consequence

Suite accepts 5 de-registrations per second (as opposed to required 100).

New features
~~~~~~~~~~~~

Tell-based protocol
-------------------

+ Information

Tell-based protocol is an alternative to ask-based protocol from Boron.
Which protocol to use is decided by a line in a configuration file
(org.opendaylight.controller.cluster.datastore.cfg).

Some scenarios are expected to fail due to known limitations of ask-based protocol.
More specifically, if a shard leader moves while a transaction is open in ask-based protocol,
the transaction will fail (AskTimeoutException).

This affects only data broker tests, not RPC calls.

+ Testing consequence

In principle, this doubles the number of configurations to be tested, but see below.

Prefix-based shards
-------------------

+ Information

Tell-based shards are an alternative to module-based shards from Boron.
Tell-based shards can be only created dynamically (as opposed to being read from a configuration file at startup).
It is possible to use both types of shards, but data writes and reads use different API,
so any Mdsal application needs to know which API to use.

The implementation of prefix-based shards is hardwired to tell-based protocol
(even if ask-based protocol is configured as default).

+ Testing consequence

This doubles the number of configurations to be tested, for tests related to data droker (RPCs are unaffected).

Producer options
----------------

+ Information

Data producers for module-based shards can produce either chained transactions or standalone transactions.
Data producers for prefix-based shards can produce either non-isolated transactions (change notifications
can composeseverat transactions together) or isolated transactions.

+ Testing consequence

In principle, this results in multiple Robot test cases for the same documented scenario case, but see below.

Initial leader placement
~~~~~~~~~~~~~~~~~~~~~~~~

+ Information

Some scenarios do not specify initial locations of relevant shard leaders.
Test results can depend on it in presence of bugs.

This is mostly relevant to BGP test, which has three relevant members:
Rib owner, default operation shard leader and topology operational shard leader.

+ Testing consequence

Two test cases are tested. The two shard leaders are always together, rib owner is either co-located or not.
This is done by suite moving shard leaders after detecting rib owner location.

Reduced BGP scaling
~~~~~~~~~~~~~~~~~~~

+ Information

Rib owner maintains de-duplicated data structures.
Other members get serialized copies and they do not de-duplicate.

Even single node strugless to fit into 6GB heap with tell-based protocol,
see `Bug 8649 <https://bugs.opendaylight.org/show_bug.cgi?id=8649>`__.

+ Testing consequence

Scale from reported tests reduced from 1 million prefixes to 300 thousand prefixes.

Increased timeouts
~~~~~~~~~~~~~~~~~~

RequestTimeoutException
-----------------------

+ Information

With tell-based protocol, restconf requests might stay open up to 120 seconds before returning an error.
Even shard state reads using Jolokia can take long if the shard actor is busy processing other messages.

+ Testing consequence

This increases duration for tests which need to verify transaction errors do happen
after sufficiently long isolation. Also, duration is increased if a test fails on a read which is otherwise quick.

This motivates leaving out some test cases to allow faster change verification.

Client abort timeout
--------------------

+ Information

Client abort timeout is currently set to 15 minutes. The operational consequence is
just in inability to start another data producer on a member isolated for that long.
This has too long duration compared to usefulness.

+ Testing consequence

This test case has never been implemented.

Instead a test with isolation shorter than 120 seconds is implemented,
the test verifies the data producer continues its operation without RequestTimeoutException.

Hard reboots between test cases
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

+ Information

Timing errors in Robot code lead to Robot being unable to restore original state without restarts.

During development, we started without any hard reboots, and that was finding bugs in teardown steps of scenarios.
But test independence was more important at that time, so current tests are less sensitive to teardown failures.

+ Testing consequence

Almost 80 second per ODL reboot, this time is added to every test case running time.
Together with increased timeouts, this motivates leaving out some test cases to allow faster change verification.

Isolation mechanics
~~~~~~~~~~~~~~~~~~~

+ Information

During development, it was found that freeze and kill mechanics affect the co-located java test drive
without exposing any new bugs.

Turns out AAA functionality attempts to read from datastore, so isolated member returns http status code 401.

+ Testing consequence

Only iptables filtering is used in order to reduce test job duration.

Isolated members are never queried directly. A leader member is considered isolated
when other members elect a lew leader. A member is considered rejoined
when it responds reporting itself as a follower.

Reduced number of combinations
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

+ Information

Prefix-based shards always use tell-based protocol, so suites which test them
with ask-based protocol configuration can be skipped.

Ask-based protocol is known to fail on AskTimeoutException on leader movement,
so suites which produce transactions constantly can be skipped.

Most test cases are not sensitive to data producer options.

BGP tests and singleton tests use module-based shards only, both protocols.
Other suites related to data broker are testing only tell-based protocol, both shard types.
Netconf tests and RPC tests use module-based shards with ask-based protocol only.
Only client isolaton suite tests different producer options.

Missing logs
~~~~~~~~~~~~

+ Information

Robot VM has only 2GB of RAM and longevity jobs tend to produce large output.xml files.

Ocasionally, a job can create karaf.log files so large they fail to download,
in extreme cases filling ODL VM disk and causing failures.

This affects mostly longevity jobs (and runs with verbose logging) if they pass.

+ Testing consequence

Robot data stored is reduced to avoid this issue, sometimes leading to less details available.
This issue is still not fully resolved, so ocassionally Robot log or karaf log is still missing
if the job in question fails in an unexpected way.
