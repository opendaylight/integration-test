
Carbon clustering test report.
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

TODOs:
Isolation mechanics.
Producer options.
Update results and links to latest suite and code merges.

Note: Numbering may change while the document is being edited.

- DOMDataBroker: Producers make 1000 transactions per second, except BGP which works full speed.

 - Leader stability: BGP inject benchmark (thus module shards only), 1 Python peer.

  - Single member, 1M prefixes:

   - Ask-based protocol: PASS: https://logs.opendaylight.org/releng/jenkins092/bgpcep-csit-1node-periodic-bgp-ingest-only-carbon/250/archives/log.html.gz#s1-s2
   - Tell-based protocol: PASS: https://logs.opendaylight.org/releng/jenkins092/bgpcep-csit-1node-periodic-bgp-ingest-only-carbon/250/archives/log.html.gz#s1-s9

  - Three members:

   - Leader local:

    - Original scale 1M perfixes:

     - Ask-based protocol: FAIL conflict leading to broken chain: https://logs.opendaylight.org/releng/jenkins092/bgpcep-csit-3node-periodic-bgpclustering-only-carbon/246/archives/log.html.gz#s1-s2
     - Tell-based protocol: FAIL Bug 8214: https://logs.opendaylight.org/releng/jenkins092/bgpcep-csit-3node-periodic-bgpclustering-only-carbon/245/archives/log.html.gz-s1-s5

    - Updated scale 300k prefixes:

     - Ask-based protocol: FAIL rib owner moved in runtime: https://logs.opendaylight.org/releng/jenkins092/bgpcep-csit-3node-periodic-bgpclustering-only-carbon/246/archives/log.html.gz#s1-s1
     - Tell-based protocol: FAIL Bug 8214: https://logs.opendaylight.org/releng/jenkins092/bgpcep-csit-3node-periodic-bgpclustering-only-carbon/246/archives/log.html.gz#s1-s4
     - Longevity tell-based protocol: FAIL data loss on ipv4 topology: https://logs.opendaylight.org/releng/jenkins092/bgpcep-csit-3node-bgpclustering-longevity-only-carbon/1/archives/log.html.gz

   - Leader remote: Not implemented.

 - Clean leader shutdown:

  - Module-based shards:

   - Ask-based protocol:

    - Shard leader local to producer: FAIL shard has no leader: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/649/archives/log.html.gz-s1-s9-t1
    - Shard leader remote to producer: PASS: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/649/archives/log.html.gz-s1-s9-t2

   - Tell-based protocol:

    - Shard leader local to producer: FAIL 401 to be examined: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/649/archives/log.html.gz-s1-s19-t1
    - Shard leader remote to producer: FAIL 401 to be examined: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/649/archives/log.html.gz-s1-s19-t2

  - Prefix-based shards:

   - Ask-based protocol:

    - Shard leader local to producer: Not implemented yet.
    - Shard leader remote to producer: Not implemented yet.

   - Tell-based protocol:

    - Shard leader local to producer: Not implemented yet.
    - Shard leader remote to producer: Not implemented yet.

 - Explicit leader movement:

  - Module-based shards:

   - Ask-based protocol:

    - Local leader to remote: PASS: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/649/archives/log.html.gz-s1-s10-t1
    - Remote leader to other remote: PASS: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/649/archives/log.html.gz-s1-s10-t2
    - Remote leader to local: PASS: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/649/archives/log.html.gz-s1-s10-t3

   - Tell-based protocol:

    - Local leader to remote: FAIL 401 to be examined: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/649/archives/log.html.gz-s1-s20-t1
    - Remote leader to other remote: FAIL 401 to be examined: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/649/archives/log.html.gz-s1-s20-t2
    - Remote leader to local: FAIL 401 to be examined: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/649/archives/log.html.gz-s1-s20-t3

  - Prefix-based shards:

   - Ask-based protocol:

    - Local leader to remote: Not implemented yet.
    - Remote leader to other remote: Not implemented yet.
    - Remote leader to local: Not implemented yet.

   - Tell-based protocol:

    - Local leader to remote: Not implemented yet.
    - Remote leader to other remote: Not implemented yet.
    - Remote leader to local: Not implemented yet.
    - Longevity tell-based (currently ask-based and failing on "no leader found" https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-ddb-expl-lead-movement-longevity-only-carbon/1/archives/log.html.gz )

 - Leader isolation (network partition only):

  - Module-based shards:

   - Ask-based protocol:

    - Heal within transaction timeout: FAIL leader not found from previous suite: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/652/archives/log.html.gz-s1-s11-t1
    - Heal after transaction timeout: FAIL leader not found from previous suite: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/652/archives/log.html.gz-s1-s11-t2

   - Tell-based protocol:

    - Heal within transaction timeout: FAIL Bug 8214: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/652/archives/log.html.gz-s1-s23-t1
    - Heal after transaction timeout: FAIL Bug 8214: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/652/archives/log.html.gz-s1-s23-t2

  - Prefix-based shards:

   - Ask-based protocol:

    - Heal within transaction timeout: Not implemented yet.
    - Heal after transaction timeout: Not implemented yet.

   - Tell-based protocol:

    - Heal within transaction timeout: FAIL faulty suite: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/652/archives/log.html.gz-s1-s26-t1
    - Heal after transaction timeout: FAIL faulty suite: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/652/archives/log.html.gz-s1-s26-t2

 - Client isolation:

  - Module-based shards:

   - Ask-based protocol:

    - Leader local:

     - Simple transactions: FAIL leader not found from previous suite: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/652/archives/log.html.gz-s1-s12-t2
     - Transaction chain: FAIL leader not found from previous suite: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/652/archives/log.html.gz-s1-s12-t1

    - Leader remote:

     - Simple transactions: FAIL leader not found from previous suite: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/652/archives/log.html.gz-s1-s12-t4
     - Transaction chain: FAIL leader not found from previous suite: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/652/archives/log.html.gz-s1-s12-t3

   - Tell-based protocol:

    - Leader local:

     - Simple transactions: FAIL Bug 8214: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/652/archives/log.html.gz-s1-s24-t2
     - Transaction chain: FAIL Bug 8214: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/652/archives/log.html.gz-s1-s24-t1

    - Leader remote:

     - Simple transactions: FAIL Bug 8214: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/652/archives/log.html.gz-s1-s24-t4
     - Transaction chain: FAIL Bug 8214: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/652/archives/log.html.gz-s1-s24-t3

  - Prefix-based shards:

   - Ask-based protocol:

    - Leader local:

     - Simple transactions: Not implemented yet.
     - Transaction chain: Not implemented yet.

    - Leader remote:

     - Simple transactions: Not implemented yet.
     - Transaction chain: Not implemented yet.

   - Tell-based protocol:

    - Leader local:

     - Simple transactions: FAIL faulty suite: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/652/archives/log.html.gz-s1-s29-t2
     - Transaction chain: FAIL faulty suite: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/652/archives/log.html.gz-s1-s29-t1

    - Leader remote:

     - Simple transactions: FAIL faulty suite: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/652/archives/log.html.gz-s1-s29-t4
     - Transaction chain: FAIL faulty suite: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/652/archives/log.html.gz-s1-s29-t3

 - Listener stablity:

  - Module-based shards:

   - Ask-based protocol:

    - Leader local: FAIL leader not found from previous suite: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/652/archives/log.html.gz-s1-s13-t1
    - Leader remote: FAIL leader not found from previous suite: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/652/archives/log.html.gz-s1-s13-t2

   - Tell-based protocol:

    - Leader local: FAIL Bug 8214: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/652/archives/log.html.gz-s1-s25-t1
    - Leader remote: FAIL Bug 8214: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/652/archives/log.html.gz-s1-s25-t2

  - Prefix-based shards:

   - Ask-based protocol:

    - Leader local: Not implemented yet.
    - Leader remote: Not implemented yet.

   - Tell-based protocol:

    - Leader local: FAIL faulty suite: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/652/archives/log.html.gz-s1-s28-t1
    - Leader remote: FAIL faulty suite: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/652/archives/log.html.gz-s1-s28-t2

- DOMRpcBroker:

 - RPC Provider Precedence: PASS: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/649/archives/log.html.gz-s1-s5
 - RPC Provider Partition and Heal: PASS except 401 from isolated members: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/649/archives/log.html.gz-s1-s6
 - Action Provider Precedence: PASS: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/649/archives/log.html.gz-s1-s7
 - Action Provider Partition and Heal: PASS except 401 from isolated members: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/649/archives/log.html.gz-s1-s8
 - Longevity:

  - Provider precedence: FAIL on 501, possibly suite too quick: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-drb-precedence-longevity-only-carbon/4/archives/
  - Partition and Heal: FAIL due to 401: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-drb-partnheal-longevity-only-carbon/4/archives/log.html.gz

- DOMNotificationBroker: Only for 1 member.

 - No-loss rate: Publisher-subscriber pairs, 5k nps per pair.

  - Functional: 5 minute tests for 1, 4 and 12 pairs: PASS: https://logs.opendaylight.org/releng/jenkins092/controller-csit-1node-rest-cars-perf-only-carbon/564/archives/log.html.gz-s1-s2
  - Longevity: 12 pairs: PASS: https://logs.opendaylight.org/releng/jenkins092/controller-csit-1node-notifications-longevity-only-carbon/9/archives/

- Cluster Singleton:

 - Master Stability: PASS: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/649/archives/log.html.gz-s1-s2
 - Partition and Heal: FAIL suite needs to wait longer: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/649/archives/log.html.gz-s1-s3
 - Chasing the Leader: PASS with reduced performance: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/649/archives/log.html.gz-s1-s4
 - Longevity:

  - Chasing the Leader: PASS with reduced performance: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-cs-chasing-leader-longevity-only-carbon/2/archives/log.html.gz
  - Partition and Heal: FAIL: AskTimeoutException: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-cs-partnheal-longevity-only-carbon/2/archives/log.html.gz
