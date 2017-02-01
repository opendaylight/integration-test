
Clustering tester point of view (intended Carbon testing libraries).

In CSIT, Robot Framework is started on different VM than ODL members.
Remote access includes:
SSH to ODL VM OS and running bash commands.
SSH to ODL Karaf console an running CLI commands.
Sending HTTP requests to ODL members (GET for datastore read,
PUT for datastore write, POST for invoking RPCs).
Receiving notifications over WebSocket.

Robot Framework is single threaded in principle. So when there is a need
for concurrent operations (for example sending requests while causing cluster failure)
separate utilities are needed. Their code is typically in integration/test repository,
usually written in Python, and they are run on Tools VM.
From Robot point of view they look like other bash commands over SSH.

Specific applications may need to interact with other network devices,
which are either present on Tools VM, or at least there are mock programs running.
Those mock programs may be Python utilities from integration/test, third party utilities,
or java executables built in ODL projects which use them.
So installation differs, invocation is still bash over SSH.

As many MD-SAL operations are not available purely via Restconf, a workaround is needed,
typically provided by ODL Karaf features exposing services used for testing.
It is not clear whether such Karaf features are official deliverables,
but (at least for Controller project) they end up included in official .zip bundle.
The features are usually installed by configuring featuresBoot,
but feature:install (Karaf console over SSH) is another option.

Available libraries (usually Robot Resources):
For general manipulation with cluster, there is ClusterManagement.
For general http request building, sending, receiving and checking, there is TemplatedRequests.
Specific queries to jolokia and entity-owners already have nice keywords in ClusterManagement.
Frequently used blocks are already incorporated to the keywords,
for example ClusterManagement.Start_Single_Member waits for shard managers to finish syncing.

Applications of many projects also have Resources ready in csit/libraries/.
See Documentation there.
