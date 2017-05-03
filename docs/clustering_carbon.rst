
Isolation mechanics.

* DOMDataBroker: Producers make 1000 transactions per second, except BGP which works full speed.
** Leader stability: BGP inject benchmark (thus module shards only), 1 Python peer.
*** Single member:
**** Ask-based protocol: PASS: https://logs.opendaylight.org/releng/jenkins092/bgpcep-csit-1node-periodic-bgp-ingest-only-carbon/248/archives/log.html.gz#s1-s2
**** Tell-based protocol: PASS: https://logs.opendaylight.org/releng/jenkins092/bgpcep-csit-1node-periodic-bgp-ingest-only-carbon/248/archives/log.html.gz#s1-s9
*** Three members:
**** Leader local:
***** Original scale 1M perfixes:
****** Ask-based protocol: FAIL on read timeout from Jolokia: https://logs.opendaylight.org/releng/jenkins092/bgpcep-csit-3node-periodic-bgpclustering-only-carbon/245/archives/log.html.gz#s1-s2
****** Tell-based protocol: FAIL on read timeout from Jolokia: https://logs.opendaylight.org/releng/jenkins092/bgpcep-csit-3node-periodic-bgpclustering-only-carbon/245/archives/log.html.gz#s1-s5
***** Updated scale 300k prefixes:
****** Ask-based protocol: FAIL: https://logs.opendaylight.org/releng/jenkins092/bgpcep-csit-3node-periodic-bgpclustering-only-carbon/245/archives/log.html.gz#s1-s1
****** Tell-based protocol: PASS: https://logs.opendaylight.org/releng/jenkins092/bgpcep-csit-3node-periodic-bgpclustering-only-carbon/245/archives/log.html.gz#s1-s4
****** Longevity tell-based protocol: FAIL data loss on ipv4 topology: https://logs.opendaylight.org/releng/jenkins092/bgpcep-csit-3node-bgpclustering-longevity-only-carbon/1/archives/log.html.gz
**** Leader remote: Not implemented.
** Clean leader shutdown:
*** Module-based shards:
**** Ask-based protocol:
***** Shard leader local to producer: FAIL shard has no leader: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/649/archives/log.html.gz#s1-s9-t1
***** Shard leader remote to producer: PASS: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/649/archives/log.html.gz#s1-s9-t2
**** Tell-based protocol:
***** Shard leader local to producer: FAIL 401 to be examined: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/649/archives/log.html.gz#s1-s19-t1
***** Shard leader remote to producer: FAIL 401 to be examined: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/649/archives/log.html.gz#s1-s19-t2
*** Prefix-based shards:
**** Ask-based protocol:
***** Shard leader local to producer: Not implemented yet.
***** Shard leader remote to producer: Not implemented yet.
**** Tell-based protocol:
***** Shard leader local to producer: Not implemented yet.
***** Shard leader remote to producer: Not implemented yet.
** Explicit leader movement:
*** Module-based shards:
**** Ask-based protocol:
***** Local leader to remote: PASS: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/649/archives/log.html.gz#s1-s10-t1
***** Remote leader to other remote: PASS: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/649/archives/log.html.gz#s1-s10-t2
***** Remote leader to local: PASS: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/649/archives/log.html.gz#s1-s10-t3
**** Tell-based protocol:
***** Local leader to remote: FAIL 401 to be examined: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/649/archives/log.html.gz#s1-s20-t1
***** Remote leader to other remote: FAIL 401 to be examined: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/649/archives/log.html.gz#s1-s20-t2
***** Remote leader to local: FAIL 401 to be examined: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/649/archives/log.html.gz#s1-s20-t3
*** Prefix-based shards:
**** Ask-based protocol:
***** Local leader to remote: Not implemented yet.
***** Remote leader to other remote: Not implemented yet.
***** Remote leader to local: Not implemented yet.
**** Tell-based protocol:
***** Local leader to remote: Not implemented yet.
***** Remote leader to other remote: Not implemented yet.
***** Remote leader to local: Not implemented yet.
***** Longevity tell-based (currently ask-based and failing on "no leader found" https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-ddb-expl-lead-movement-longevity-only-carbon/1/archives/log.html.gz )
** Leader isolation: 

** Client isolation: TBA
** Listener stablity: TBA

* DOMRpcBroker:
** RPC Provider Precedence: PASS: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/649/archives/log.html.gz#s1-s5
** RPC Provider Partition and Heal: PASS except 401 from isolated members: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/649/archives/log.html.gz#s1-s6
** Action Provider Precedence: PASS: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/649/archives/log.html.gz#s1-s7
** Action Provider Partition and Heal: PASS except 401 from isolated members: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/649/archives/log.html.gz#s1-s8
** Longevity:
*** Provider precedence: FAIL on 501, possibly suite too quick: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-drb-precedence-longevity-only-carbon/4/archives/
*** Partition and Heal: FAIL due to 401: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-drb-partnheal-longevity-only-carbon/4/archives/log.html.gz
* DOMNotificationBroker: Only for 1 member.
** No-loss rate: Publisher-subscriber pairs, 5k nps per pair.
*** Functional: 5 minute tests for 1, 4 and 12 pairs: PASS: https://logs.opendaylight.org/releng/jenkins092/controller-csit-1node-rest-cars-perf-only-carbon/564/archives/log.html.gz#s1-s2
*** Longevity: 12 pairs: PASS: https://logs.opendaylight.org/releng/jenkins092/controller-csit-1node-notifications-longevity-only-carbon/9/archives/
* Cluster Singleton:
** Master Stability: PASS: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/649/archives/log.html.gz#s1-s2
** Partition and Heal: FAIL suite needs to wait longer: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/649/archives/log.html.gz#s1-s3
** Chasing the Leader: PASS with reduced performance: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/649/archives/log.html.gz#s1-s4
** Longevity:
*** Chasing the Leader: PASS with reduced performance: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-cs-chasing-leader-longevity-only-carbon/2/archives/log.html.gz
*** Partition and Heal: FAIL: AskTimeoutException: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-cs-partnheal-longevity-only-carbon/2/archives/log.html.gz
