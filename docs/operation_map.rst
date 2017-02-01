
Translation from test actions to MD-SAL operations (intended Carbon behavior).

Implicit actions:

CSIT starts:
Configuration files are created, they include car, people and car-people shards
(aside the usual topology, inventory and of course default).
Features to test are added to featuresBoot.
ODL is started.
Script waits for each member to start responding to Restconf requests (plus fixed sleep).

odl-restconf is installed (via featuresBoot):
MD-SAL is initialized.
Restconf is initialized using the default AAA configuration.
Usually, all three members do this around the same time,
so no timeouts happen while cluster is forming.

odl-dsbenchmark is installed (optional, via odl-mdsal-benchmark in featuresBoot):
Default ConfigSubsystem config file for dsbenchmark is applied, resulting in:
cleanup-store and start-test global RPCs are registered (per member with the feature).

odl-clustering-test-app is installed (optional, via featuresBoot):
Blueprint creates basicRpcTestProvider, which registers as a Singleton service.
Owner (possibly elected before other members register) registers basic-global RPC.
Blueprint creates purchaseCarProvider (no registration yet).
Blueprint creates peopleProvider and registers it as add-person implementation
(global RPC per member), this implementation has purchaseCarProvider injected.
Blueprint creates carProvider and registers its RPC implementations.
Blueprint creates peopleCarListener which subscribes to listen for car-bought Yang notifications.

TODO: Describe car RPCs: stress-test, stop-stress-test, register-ownership, unregister-ownership,
register-logging-dcl, unregister-logging-dcls, register-logging-dtcl, unregister-logging-dtcls.

Explicit actions:

Restconf POST to start-test on member A (odl-benchmark installed):
Member A searches RPC registration, member A is found.
If test is running (according to internal status stored in member A), member A returns http response.
Otherwise, status is set to executing, cleanup removes previous data, listeners are created
(for both datastores) and many transactions of specified type are submitted.
On exception, status is set to idle, http response sent (and listeners kept alive).
Otherwise events are counted, listeners destroyed, time computetd, and success returned.

Restconf POST to cleanup-store on member A (odl-benchmark installed):
Member A searches RPC registration, member A is found.
Member A replaces test data with empty list data (irrespective of test possibly running)
in both confing and operational datastores
(separate transactions, respective Leaders commit the write).
Member A waits for commit future to finish, return success.

Restconf GET or PUT or DELETE on member A config datastore (car/people modules):
Member A searches for shard Leader, member B (perhaps the same as A) is found.
Member A forwards the request. Member B process the requests (assuming enough Followers).
Member B reports the result, member A returns HTTP rersponse.

Restconf POST to basic-global on member A:
Member A searches for a member where basic-global is registered.
If member B is registered (may be the same as A), call is forwrded there.
Member B reports success, member A returns response.

Restconf POST to add-person on member A:
Member A searches for a member where add-person is registered. (Member A is found.)
Member A writes new person list item into config datastore as a standalone transaction.
Member A constructs a person identifier and uses the injected purchaseCarProvider
to register that buy-car (routed RPC) implementation using that identifier.
Member A reports success, member A returns response.

Restconf POST to buy-car on member A:
Member A searches for a member where buy-car (with corresponding identifier) is registered.
Member B is found. Member A forwards the call to member B.
Member B publishes car-bought Yang notification.
Member B reports success, member A returns response.
Member B (FIXME: are we sure no other?) peopleCarListener receives the notification,
and writes new car-people list item to config satastore as a standalone transaction.

TODOs:
Which http status is returned if on call of RPC with no registered implementation? (501?)
Or if a datastore write fails, for example due to OptimisticLockException (or not enough followers)?
In each case, What is written to karaf.log?

Member A Java process is killed:
Linux closes TCP connections. Other members are notified A is unreachable.
If A was a Leader of any shard, remaining followers elect new Leader.
TODO: Restconf responses until election is done?
RPC and notification registrations from member A are removed on other nodes.
If enough followers, Leader can make progress when handling data.

Down message about unreachable member B is sent to Leader A jolokia:
Member A removes B from list of nodes needed to be available
in order to make progress when adding new (probably just returning) members.
This affects "other unreachable nodes" below.

Member A Karaf is started again (whether persisted data was deleted or not):
Member A joins akka cluster. Local shard replica is restored from persistence.
Leader detects A is a replica. If there are other unreachable nodes, no further progress for member A.
Leader sends data member A has missed.
Local replica us up-to-date, member A is qualified candidate for future elections.
TODO: What if persisted data has been corrupted?

Follower A is isolated from others (packet DROP) a brief time (less than a timeout):
If there is enough followers, data updates make progress.
RPC calls "work" but futures remain blocked.

Follower A isolation ends after brief time:
RPC calls unblock, everything works.

Follower A is isolated from others (packet DROP) long time:
The same consequences as if A is killed.

Follower A isolation ends after long time:
RPC responses are lost, no way to tell whether notifications arrived from A to B or from B to A.
Process continues from "Leader detects A is a replica" of "Karaf is started again".

TODOs: Karaf shutdown, VM poweroff, REJECT isolation, partial isolation, ...
