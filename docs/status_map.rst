
Translation from test checks to MD-SAL states (intended Carbon behavior).

Name: Retconf is ready on member A.
Check: GET to http://${member_a_address}:8181/restconf/modules
Expected: Repsonse status code is 200.
State: Config Subsystem and Restconf are operational. Most of MD-SAL is operational,
but shard replicas still may be in process of resuming persisted data and electing Leaders.
Akka and shard configuration should be applied already. TODO: Are we sure?

Name: Member A config is in sync.
Check: GET to http://${member_a_address}:8181/jolokia/read/org.opendaylight.controller:Category=ShardManager,name=shard-manager-config,type=DistributedConfigDatastore
Expected: Text JSON contains "SyncStatus":true
State: ShardManagerInfoMBean#getSyncStatus() is true, so all config shards are either Leader
or synchronized with their Leader.

s/config/operational/ is also a check
"Member A is in sync" means both config and operational is in sync.
"Cluster is in sync" means all members are in sync.

Name: Locate Leader and Followers for shard S.
Check: Multiple GETs and parsing. See ClusterManagement.Get_Leader_And_Followers_For_Shard
State: Within set of members, all shard replicas are Follower except exactly one Leader.

Name: Entity has an owner and successors (from member A point of view).
Check: GET http://${member_a_address}:8181/restconf/operational/entity-owners:entity-owners
and parse, see ClusterManagement.Get_Owner_And_Candidates_For_Type_And_Id
State: Member reads entity owners shard and returns its contents, Robot parses for the entity of interest.

Name: Device has an owner and successors (from member A point of view).
Calls Entity*, but we have keywords (per project) ready to detect the right Type and Id,
perhaps in several tries when implementation changed between releases.
If there is Singleton, both ServiceEntityType and AsyncServiceCloseEntityType are checked
and owners and successors have to match.

Name: Data is in datastore (from member A point of view).
Check: Ordinary Restconf GET. TemplatedRequests helps with checking against templates.
State: Restconf locates appropriate shard Leader, Leader responds, member A returns the response.
