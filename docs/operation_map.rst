
Translation from test actions to MD-SAL operations (intended Carbon behavior).

CSIT starts (implicit):
Configuration files are created, they include car, people and car-people shards
(aside the usual topology, inventory and of course default).
Features to test with are added to featuresBoot.
ODL is started.
Script waits for each member to start responding to Restconf requests (plus fixed sleep).

odl-restconf is installed (implicit via featuresBoot):
MD-SAL is initialized.
Restconf is initialized using the default AAA configuration.
Usually, all three members do this around the same time,
so no timeouts happen while cluster is forming.

odl-dsbenchmark is installed (via odl-mdsal-benchmark, implicit via featuresBoot):
Default ConfigSubsystem config file for dsbenchmark is applied, resulting in:
cleanup-store and start-test global RPCs are registered (per member with the feature).

odl-clustering-test-app is installed (implicit via featuresBoot):
Blueprint starts basicRpcTestProvider, which registers for Singleton.
Owner (possibly elected before other members register) registers basic-global RPC.
Blueprint starts peopleProvider and registers it as add-person implementation (global RPC per member).
Blueprint starts carProvider and registers it as add-car implementation (global RPC per member).

