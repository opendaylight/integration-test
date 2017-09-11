=======
Caveats
=======

This sub-page describes ways the test implementation (or results) differs
from the `original specification <scenarios.html>`_ and which information motivates the difference.

Jenkins job structure
~~~~~~~~~~~~~~~~~~~~~

+ Information

At the start of test implementation, all the Controller 3node test cases were added into an existing Jenkins job.

During test development it was become clear, that adding all possible tests would make the job to run too long.

Dividing the job into several smaller ones is possible, but most likely the history would be lost,
unless Linux Foundation admins figure out a way to create multiple job clones with history copied.

+ Testing consequence

Even with number of test cases reduced (see below), the job duration is around three and half hours.

+ How to fix

After Carbon SR2 release, the jobs can be split, as there will be enough time
to generate new history till Carbon SR3.

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
is explicitly checked by the test, as the scenario dictates it should not happen).
This does not affect other data broker tests, 1000 transactions per second do not generate critical throughput.

+ Testing consequence

Three test cases are failing due to `Bug 8318 <https://bugs.opendaylight.org/show_bug.cgi?id=8318>`__.

+ How to fix

Possibly, a different akka configuration could be applied to separate akka cluster status messages
into a different TCP stream than ordinary data stream.

Otherwise, a contribution to Akka project would be needed.

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

This affects "partition and heal" scenarios in singleton testing.
In functional tests, the failures are infrequent enough to consider the test mostly stable overall,
but the corresponding longevity jobs are failing consistently.

The tests for "partition and heal" scenarios in RPC testing have been changed
to tolerate wrong RPC results for 10 seconds to work around this Akka bug.

+ How to fix

This does not seem fixable on ODL level, contribution to Akka project is needed.

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

+ How to fix

After the funtionality is added, it will be straightforward to add 3node tests.

Reduced Singleton performance
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

+ Information

Carbon is missing `an improvement <https://bugs.opendaylight.org/show_bug.cgi?id=7855>`__
which limits java test implementation.

+ Testing consequence

Suite accepts 5 de-registrations per second (as opposed to required 100).

+ How to fix

When the performance is inproved, it will take two one-line changes to make test assert the new performance target.

+ Update

As a consequence of fixing `Bug 8858 <https://bugs.opendaylight.org/show_bug.cgi?id=8858>`__,
Singleton service implementation has been changed, so now the rate
is (slightly) above 100 de-registrations per second.
Though, the change has not been cherry-picked to Nitrogen yet.

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

+ How to fix

It is planned for tell-based protocol to become the default setting after Carbon SR2.
After that, tests for ask-based protocol can be converted or removed.

Prefix-based shards
-------------------

+ Information

Tell-based shards are an alternative to module-based shards from Boron.
Tell-based shards can be only created dynamically (as opposed to being read from a configuration file at startup).
It is possible to use both types of shards, but data writes and reads use different API,
so any Mdsal application needs to know which API to use.

The implementation of prefix-based shards is hardwired to tell-based protocol
(even if ask-based protocol is configured as the default).

+ Testing consequence

This doubles the number of configurations to be tested, for tests related to data droker (RPCs are unaffected).

+ How to fix

ODL contains great many applications which use APIs for module-based shards.
It is expected that multiple releases would still need both types of tests cases.
Module-based shards will be deprecated and removed eventually.

Producer options
----------------

+ Information

Data producers for module-based shards can produce either chained transactions or standalone transactions.
Data producers for prefix-based shards can produce either non-isolated transactions (change notifications
can combine several transactions together) or isolated transactions.

+ Testing consequence

In principle, this results in multiple Robot test cases for the same documented scenario case, but see below.

+ How to fix

All test cases will be needed in forseeable future.
Instead, more negative test cases may need be added to verify different options lead to different behavior.

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

+ How to fix

Even more placements can be tested when job duration stops being the limiting factor.

Reduced BGP scaling
~~~~~~~~~~~~~~~~~~~

+ Information

Rib owner maintains de-duplicated data structures.
Other members get serialized copies and they do not de-duplicate.

Even single node strugless to fit into 6GB heap with tell-based protocol,
see `Bug 8649 <https://bugs.opendaylight.org/show_bug.cgi?id=8649>`__.

+ Testing consequence

Scale from reported tests reduced from 1 million prefixes to 300 thousand prefixes.

+ How to fix

Other members should be able to perform de-duplication, but developing that takes effort.

In the meantime, Linux Foundation could be convinced to allow for bigger VMs,
currently limited by infrastructure available.

Increased timeouts
~~~~~~~~~~~~~~~~~~

RequestTimeoutException
-----------------------

+ Information

With tell-based protocol, restconf requests might stay open up to 120 seconds before returning an error.
Even shard state reads using Jolokia can take long time if the shard actor is busy processing other messages.

+ Testing consequence

This increases duration for tests which need to verify transaction errors do happen
after sufficiently long isolation. Also, duration is increased if a test fails on a read which is otherwise quick.

+ How to fix

This involves a trade-off between stability and responsiveness.
As MD-SAL applications rarely tolerate transaction failures, users would prefer stability.
That means relatively longer timeouts are there to stay, which means test case duration
will stay high in negative (or failing positive) tests.

Client abort timeout
--------------------

+ Information

Client abort timeout is currently set to 15 minutes. The operational consequence is
just an inability to start another data producer on a member isolated for that long.
This test has too long duration compared to its usefulness.

+ Testing consequence

This test case has never been implemented.

Instead a test with isolation shorter than 120 seconds is implemented,
the test verifies the data producer continues its operation without RequestTimeoutException.

+ How to fix

It is straighforward to add the missing test cases when job duration stops being a limiting factor.

No shard shutdown
~~~~~~~~~~~~~~~~~

+ Common information.

There are multiple RPCs offering different "severity" of shard shutdown.
For technical details see comments on `change 58580 <https://git.opendaylight.org/gerrit/58580>`__.

If tests perform rigorous teardown, the shard replica should be re-activated,
which is an operation not every RPC supports.

Listener stability suite
------------------------

+ Information

Current implementation of data listeners relies on a shard replica to be active on a member
which is to receive the notification. Until that is imroved,
`Bug 8629 <https://bugs.opendaylight.org/show_bug.cgi?id=8629>`__ prevents this scenario
from being tested as described.

+ Testing consequence

The suite uses become-leader RPC instead. This has an added benefit of test case being able to pick which member
is to become the new leader (adding one more test case when the old leader was not co-located with the listener).

Also, no teardown step is needed, the final cluster state is not missing any shard replica.

+ How to fix

The original test can be implemented when listener implementation changes.
But the test which uses become-leader might be better overall.

Clean leader shutdown suite
---------------------------

+ Information

Some implementations of shutdown RPCs have a side effect of also shutting down shard state notifier.
For details see `Bug 8794 <https://bugs.opendaylight.org/show_bug.cgi?id=8794>`__.

The remove-shard-replica RPC does not have this downside, but it changes shard configuration,
which was not intended by the original scenario definition.

+ Testing consequence

Test cases for this scenario were switched to use remove-shard-replica.

+ How to fix

There is an open debate on whether "shard shutdown" RPC with less operations (compared to remove-shard-replica)
is something user wants and should be given access to.

If yes, tests can be switched to such an RPC, assuming the shard notifier issue is also fixed.

Hard reboots between test cases
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

+ Information

Timing errors in Robot code lead to Robot being unable to restore original state without restarts.

During development, we started without any hard reboots, and that was finding bugs in teardown steps of scenarios.
But test independence was more important at that time, so current tests are less sensitive to teardown failures.

+ Testing consequence

Around 115 second per ODL reboot, this time is added to every test case running time.
Together with increased timeouts, this motivates leaving out some test cases to allow faster change verification.

+ How to fix

Ideally, we would want both jobs with hard resets and jobs without them.
The jobs without resets can be added gradually after splitting the current single job.

Isolation mechanics
~~~~~~~~~~~~~~~~~~~

+ Information

During development, it was found that freeze and kill mechanics affect the co-located java test driver
without exposing any new bugs.

Turns out AAA functionality attempts to read from datastore, so isolated member returns http status code 401.

+ Testing consequence

Only iptables filtering is used in order to reduce test job duration.

Isolated members are never queried directly. A leader member is considered isolated
when other members elect a lew leader. A member is considered rejoined
when it responds reporting itself as a follower.

+ How to fix

It is straightforward to add test cases for kill and freeze where appropriate,
but once again this can be done gradually when job duration is not a limiting factor.

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

+ How to fix

More ests can be added gradually (see above).

Possibly, not every combination is worth the duration it takes,
but that could be alleviated if Linux Foundation infrastructure grows in size significantly.

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

+ How to fix

It is possible for Robot test to put additional data into separate files.
Unnecessarily verbose logs could be fixed where needed.

As this limitation only hurts in newly occuring bugs, it is not really possible to entirely avoid this.

Weekend outages
~~~~~~~~~~~~~~~

+ Information

Linux foundation ifrastructure teem occasionally needs to perform changes which affect running jobs.
To reduce this impact, such changes are usually done over weekend.

Cluster testing currently contains seve longevity jobs which block resources for 23 hours.
As that is a significant portion of available resources, the longevity jobs are only run on weekend
where the impact on frequency of other job is less critical.

+ Testing consequence

Sometimes, the longevity jobs are affected by infrastructure team activities,
leading to lost results or spurious failures.
One such symptom is tracked as `Bug 8959 <https://bugs.opendaylight.org/show_bug.cgi?id=8959>`__.

+ How to fix

It might be possible to spread longevity jobs over work days. As distributing jobs manually
is not a scalable option, a considerable work would be needed to create an automatic way.

Infrastructure changes are not very frequent, and having jobs run at the same predictable time
is convenient from reporting point of view, so perhaps it is okay to keep the current setup.
