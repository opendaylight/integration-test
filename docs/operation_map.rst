
Translation from test actions to MD-SAL operations (intended Carbon behavior).

Text in brackets in Name field is an assumption to be verified in context, not part of the Name.

Implicit actions:

Name: CSIT starts.
Operations: Configuration files are created, they include car, people and car-people shards
(aside the usual topology, inventory and of course default).
Features to test are added to featuresBoot.
ODL is started.
Script waits for each member to start responding to Restconf requests (plus fixed sleep).

Name: odl-restconf is installed (via featuresBoot).
Operations: MD-SAL is initialized.
Restconf is initialized using the default AAA configuration.
Usually, all three members do this around the same time,
so no timeouts happen while cluster is forming.

Name: odl-dsbenchmark is installed (optional, via odl-mdsal-benchmark in featuresBoot).
Operations: Default ConfigSubsystem config file for dsbenchmark is applied.
cleanup-store and start-test global RPCs are registered (per member with the feature).

Name: odl-clustering-test-app is installed (optional, via featuresBoot).
Operations: Blueprint creates basicRpcTestProvider, which registers as a Singleton service.
Owner (possibly elected before other members register) registers basic-global RPC.
Blueprint creates purchaseCarProvider (no registration yet).
Blueprint creates peopleProvider and registers it as add-person implementation
(global RPC per member), this implementation has purchaseCarProvider injected.
Blueprint creates peopleCarListener which subscribes to listen for car-bought Yang notifications.
Blueprint creates carProvider and registers its RPC implementations.
TODO: Describe car RPCs: stress-test, stop-stress-test, register-ownership, unregister-ownership,
register-logging-dcl, unregister-logging-dcls, register-logging-dtcl, unregister-logging-dtcls.

Explicit actions:

Name: Call start-test on member A (odl-benchmark installed).
Action: Restconf POST to start-test RPC on member A (odl-benchmark installed).
Operations: Member A searches RPC registration, member A is found.
If test is running (according to internal status stored in member A), member A returns http response.
Otherwise, status is set to executing, cleanup removes previous data, listeners are created
(for both datastores) and many transactions of specified type are submitted.
On exception, status is set to idle, http response sent (and listeners kept alive).
Otherwise events are counted, listeners destroyed, time computetd, and success returned.

Name: Call cleanup-store on member A (odl-benchmark installed).
Action: Restconf POST to cleanup-store RPC on member A.
Operations: Member A searches RPC registration, member A is found.
Member A replaces test data with empty list data (irrespective of test possibly running)
in both confing and operational datastores
(separate transactions, respective Leaders commit the write).
Member A waits for commit future to finish, return success.

Names: read/write/delete car/people data on member A.
Action: Restconf GET or PUT or DELETE on member A config datastore (car/people modules).
Operations: Member A searches for shard Leader, member B (perhaps the same as A) is found.
Member A forwards the request. Member B process the requests (assuming enough Followers).
Member B reports the result, member A returns HTTP rersponse.

Name: Call basic-global on member A.
Action: Restconf POST to basic-global on member A.
Operations: Member A searches for a member where basic-global is registered.
If member B is registered (may be the same as A), call is forwrded there.
Member B reports success, member A returns response.

Name: Call add-person on member A.
Action: Restconf POST to add-person on member A.
Operations: Member A searches for a member where add-person is registered. (Member A is found.)
Member A writes new person list item into config datastore as a standalone transaction.
Member A constructs a person identifier and uses the injected purchaseCarProvider
to register that buy-car (routed RPC) implementation using that identifier.
Member A reports success, member A returns response.

Name: Call buy-car on member A.
Action: Restconf POST to buy-car on member A.
Operations: Member A searches for a member where buy-car (with corresponding identifier) is registered.
Member B is found. Member A forwards the call to member B.
Member B publishes car-bought Yang notification.
Member B reports success, member A returns response.
Member B (FIXME: are we sure no other?) peopleCarListener receives the notification,
and writes new car-people list item to config satastore as a standalone transaction.

TODOs:
Which http status is returned if on call of RPC with no registered implementation? (501?)
Or if a datastore write fails, for example due to OptimisticLockException (or not enough followers)?
In each case, What is written to karaf.log?

Name: Kill member A.
Action: In bash over SSH, kill member A Java process.
Operation: Linux closes TCP connections. Other members are notified A is unreachable.
Unresolved data access requests for shards where member A was Leader fail.
If member A was a follower for a shard, no effect on other members.
Inflight notifications or RPC requests and responses related to member A are lost.
RPC and notification registrations from member A are removed on other nodes.
If A was a Leader of any shard, remaining followers start electing a new Leader.
TODO: Restconf responses until election is done?
If enough followers, any Leader can make progress when handling data.

Name: Down member B.
Action: Down message about unreachable member B is sent to Leader A jolokia.
Operations: Member A removes B from list of nodes needed to be available
in order to make progress when adding new (probably just returning) members.
This affects "other unreachable nodes" below.

Name: Start member A (immediate).
Action: In bash over SSH, bin/start member A Karaf (whether persisted data was deleted or not).
TODO: What if persisted data has been corrupted?
Operations: Member A MD-SAL and Restconf starts.
Local shard replica is restored from persistence. (Usually finishes after the next step.)
Member A joins akka cluster.
Leader detects A is a replica. If there are other unreachable nodes, no further progress for member A.
Leader sends data member A has missed.
Local replica us up-to-date, member A is qualified to become a candidate for future elections.

Name: Start member A (verified, this is the default).
Definition: Start immediate and wait uintil "Cluster is in sync" check passes.

Name: Restart member A.
Definition: The same as "Kill member A" immediatelly followed by "Start member A".

Name: Isolate member A (brief).
Action: In bash over SSH to member A, iptables rule (packet DROP) breaks all traffic
between A and others (creates Boundary), for a brief time (less than a timeout).
TODO: Which timeout?
General operations: Notifications crossing Boundary are delayed all this period.
RPC crossing Boundary calls "work" but futures remain blocked.
Notifications and RPCs not crossing Boundary work without any issues.
Other members do not mark member A unreachable yet. TODO: Sure?
Operations for shards where member A is Follower:
Data access on A is delayed all this period.
Data access on other members works withut issues (assuming enough responsive members remain).
Operations for shards where member A is Leader:
Data access on all nodes is delayed all this period.

Name: Rejoin member A (after brief isolation).
Action: In bash over SSH to member A, all iptable rules are removed.
Operations: Notifications are delivered, RPC calls unblock, data access delays stop, everything works.

Name: Isolate member A (long).
Action: The same as brief isolation, but lasts more than the timeout.
General operations: Other members mark A as unreachable.
Notifications crossing Boundary are lost. RPC requests and responses crossing Boundary are lost,
no way to tell whether the desired side-effect was applied.
Notifications and RPCs not crossing Boundary still work without any issues.
Operations for shards where member A is Follower:
Data access on A is failing. TODO: What is the member A shard replica status? Candidate?
Data access on other members still works without issues (assuming enough responsive members remain).
Operations for shards where member A was Leader:
Member a shard replica status becomes IsolatedLeader. Other members start electing new leader.
New data access on all nodes is delayed all until new Leader is elected, then works without issues.
Old data access requests fail.
TODO: Are we sure new data access requests are only delayed (as opposed to failed)?

Name: Rejoin member A (after long isolation).
Action: The same as brief rejoin (only after longer time).
Operations: Member A joins cluster, other members mark it as reachable.
Process continues from "Member A joins akka cluster" of "Start member A".

TODOs: Karaf shutdown, VM poweroff, REJECT isolation, partial isolation, ...
