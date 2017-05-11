
Carbon clustering test report
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Caveats:

- Missing features:

 - Yang notifications are not delivered to peer members. `Bug 2139 <https://bugs.opendaylight.org/show_bug.cgi?id=2139>`__ is only fixed for data change notifications, not Yang notifications.

  - Notification suites are running on with 1-node setup only.

- New features:

 - Tell-based protocol instead of ask-based protocol.

  - Some scenarios are expected to fail due to known limitations of ask-based protocol.

 - Prefix-based shards instead of module-based shards.
 - Producer options:

  - Used mostly chained transactions only. Standalone transactions are prone to OptimisticLockTransactions.

 - This results in multiple suites for the same scenario.

- Hard reboots between suites:

 - Timing errors in Robot code lead to Robot being unable to restore original state without restarts.
 - Almost 90 second per ODL reboot.

- Isolation mechanics:

 - Used mostly iptables filtering. Freeze and kill affect the co-located java test driver.

  - Even then, AAA stops working (results in 401), so most checks on the isolated node are dropped anyway.

- Reduced BGP scaling:

 - Rib owner maintains de-duplicated data structures. Other members get serialized copies and they do not de-duplicate.

- Reduced Singleton performance:

 - Carbon is missing `an improvement <https://bugs.opendaylight.org/show_bug.cgi?id=7855>`__ which limits java test implementation.
 - Suite accepts 5 deregistrations per second.

- Missing log.html:

 - Robot VM has only 2GB of RAM and longevity jobs tend to produce large output.xml files.
 - This affects mostly longevity jobs if they pass.

Results:

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

    - Shard leader local to producer: FAIL shard has no leader (suite fault): https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s9-t1
    - Shard leader remote to producer: FAIL shard has no leader (suite fault): https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s9-t2

   - Tell-based protocol:

    - Shard leader local to producer: FAIL Bug 8214: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s26-t1
    - Shard leader remote to producer: FAIL Bug 8214: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s26-t2

  - Prefix-based shards:

   - Ask-based protocol:

    - Shard leader local to producer: FAIL shard creation failed, previous suite removed a replica: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s18-t1
    - Shard leader remote to producer: FAIL shard creation failed, previous suite removed a replica: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s18-t2

   - Tell-based protocol:

    - Shard leader local to producer: FAIL Bug 8214: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s35-t1
    - Shard leader remote to producer: FAIL Bug 8214: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s35-t2

 - Explicit leader movement:

  - Module-based shards:

   - Ask-based protocol:

    - Local leader to remote: FAIL read timeout, previous suite removed a replica: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/649/archives/log.html.gz-s1-s10-t1
    - Remote leader to other remote: FAIL read timeout, previous suite removed a replica: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/649/archives/log.html.gz-s1-s10-t2
    - Remote leader to local: FAIL read timeout, previous suite removed a replica: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/649/archives/log.html.gz-s1-s10-t1

   - Tell-based protocol:

    - Local leader to remote: FAIL Bug 8214: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s27-t1
    - Remote leader to other remote: FAIL Bug 8214: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s27-t2
    - Remote leader to local: FAIL Bug 8214: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s27-t3

  - Prefix-based shards:

   - Ask-based protocol:

    - Local leader to remote: FAIL shard creation failed, previous suite removed a replica: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s15-t1
    - Remote leader to other remote: FAIL shard creation failed, previous suite removed a replica: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s15-t2
    - Remote leader to local: FAIL shard creation failed, previous suite removed a replica: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s15-t3

   - Tell-based protocol:

    - Local leader to remote: FAIL Bug 8214: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s32-t1
    - Remote leader to other remote: FAIL Bug 8214: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s32-t2
    - Remote leader to local: FAIL Bug 8214: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s32-t3
    - Longevity tell-based (currently ask-based and failing on "no leader found" https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-ddb-expl-lead-movement-longevity-only-carbon/1/archives/log.html.gz )

 - Leader isolation (network partition only):

  - Module-based shards:

   - Ask-based protocol:

    - Heal within transaction timeout: FAIL leader not found, previous suite removed a replica: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s11-t1
    - Heal after transaction timeout: FAIL leader not found, previous suite removed a replica: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s11-t2

   - Tell-based protocol:

    - Heal within transaction timeout: FAIL Bug 8214: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s28-t1
    - Heal after transaction timeout: FAIL Bug 8214: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s28-t2

  - Prefix-based shards:

   - Ask-based protocol:

    - Heal within transaction timeout: FAIL shard creation failed, previous suite removed a replica: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s14-t1
    - Heal after transaction timeout: FAIL shard creation failed, previous suite removed a replica: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s14-t2

   - Tell-based protocol:

    - Heal within transaction timeout: FAIL Bug 8214: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s31-t1
    - Heal after transaction timeout: FAIL Bug 8214: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s31-t2

 - Client isolation:

  - Module-based shards:

   - Ask-based protocol:

    - Leader local:

     - Simple transactions: FAIL leader not found, previous suite removed a replica: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s12-t2
     - Transaction chain: FAIL leader not found, previous suite removed a replica: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s12-t1

    - Leader remote:

     - Simple transactions: FAIL leader not found, previous suite removed a replica: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s12-t4
     - Transaction chain: FAIL leader not found, previous suite removed a replica: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s12-t3

   - Tell-based protocol:

    - Leader local:

     - Simple transactions: FAIL Bug 8214: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s29-t2
     - Transaction chain: FAIL Bug 8214: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s29-t1

    - Leader remote:

     - Simple transactions: FAIL Bug 8214: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s29-t4
     - Transaction chain: FAIL Bug 8214: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s29-t3

  - Prefix-based shards:

   - Ask-based protocol:

    - Leader local:

     - Simple transactions: FAIL shard creation failed, previous suite removed a replica: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s17-t2
     - Transaction chain: FAIL shard creation failed, previous suite removed a replica: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s17-t1

    - Leader remote:

     - Simple transactions: FAIL shard creation failed, previous suite removed a replica: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s17-t4
     - Transaction chain: FAIL shard creation failed, previous suite removed a replica: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s17-t3

   - Tell-based protocol:

    - Leader local:

     - Simple transactions: FAIL Bug 8214: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s34-t2
     - Transaction chain: FAIL Bug 8214: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s34-t1

    - Leader remote:

     - Simple transactions: FAIL Bug 8214: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s34-t4
     - Transaction chain: FAIL Bug 8214: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s34-t3

 - Listener stablity:

  - Module-based shards:

   - Ask-based protocol:

    - Leader local: FAIL leader not found, previous suite removed a replica: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s13-t1
    - Leader remote: FAIL leader not found, previous suite removed a replica: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s13-t2

   - Tell-based protocol:

    - Leader local: FAIL Bug 8214: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s30-t1
    - Leader remote: FAIL Bug 8214: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s30-t2

  - Prefix-based shards:

   - Ask-based protocol:

    - Leader local: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s16-t1
    - Leader remote: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s16-t2

   - Tell-based protocol:

    - Leader local: FAIL Bug 8214: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s33-t1
    - Leader remote: FAIL Bug 8214: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s33-t2

- DOMRpcBroker:

 - RPC Provider Precedence: `PASS <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/669/archives/log.html.gz#s1-s8>`__
 - RPC Provider Partition and Heal: `PASS <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/669/archives/log.html.gz#s1-s10>`__
 - Action Provider Precedence: `PASS <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/669/archives/log.html.gz#s1-s12>`__
 - Action Provider Partition and Heal: `PASS <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/669/archives/log.html.gz#s1-s14>`__
 - Longevity:

  - Provider precedence: `FAIL <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-drb-precedence-longevity-only-carbon/5/archives/log.html.gz#s1-t1>`__
    `501 after 5 minutes (119 iterations), nothing wrong in karaf.log <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-drb-precedence-longevity-only-carbon/5/archives/log.html.gz#s1-t1-k2-k1-k1-k1-k1-k1-k1-k2-k1-k1-k6-k1-k2-k1-k4-k7-k1>`__
  - Partition and Heal: FAIL after passing for 4 hours, VM stopped responding.
    `Console <https://jenkins.opendaylight.org/releng/view/controller/job/controller-csit-3node-drb-partnheal-longevity-only-carbon/7/console>`__

- DOMNotificationBroker: Only for 1 member.

 - No-loss rate: Publisher-subscriber pairs, 5k nps per pair.

  - Functional (5 minute tests for 1, 4 and 12 pairs): `PASS <https://logs.opendaylight.org/releng/jenkins092/controller-csit-1node-rest-cars-perf-only-carbon/575/archives/log.html.gz#s1-s2>`__
  - Longevity (12 pairs): PASS but the job failed to compile log.html, see `karaf.log <https://logs.opendaylight.org/releng/jenkins092/controller-csit-1node-notifications-longevity-only-carbon/10/archives/odl1_karaf.log.gz>`__ instead.

- Cluster Singleton:

 - Ask-based protocol:

  - Master Stability: `PASS <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/674/archives/log.html.gz#s1-s2>`__
  - Partition and Heal (expected to fail): `AskTimeoutException <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/674/archives/log.html.gz#s1-s4-t3-k2-k8-k1-k1-k3-k2-k1-k1-k2-k1-k4-k7-k1>`__
  - Chasing the Leader: `PASS <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/674/archives/log.html.gz#s1-s6>`__ with reduced performance.
  - Longevity:

   - Chasing the Leader: `PASS <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-cs-chasing-leader-longevity-only-carbon/3/archives/log.html.gz#s1-t3-k3-k4>`__ with reduced performance.
   - Partition and Heal: `FAIL <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-cs-partnheal-longevity-only-carbon/4/archives/log.html.gz#s1>`__ after 4 iterations.
     Reported as `Bug 8420 <https://bugs.opendaylight.org/show_bug.cgi?id=8420>`__.

 - Tell-based protocol:

  - Master Stability: `PASS <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/674/archives/log.html.gz#s1-s42>`__

  - Partition and Heal: different failures:

   - `FAIL <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/674/archives/log.html.gz#s1-s44>`__
     Unexpected `401 <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/674/archives/log.html.gz#s1-s44-t5-k2-k2-k1-k2-k1-k2-k1-k6-k3-k1-k2-k1-k1-k3-k4-k1>`__ while verifying shards are stable.
   - `FAIL <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/673/archives/log.html.gz#s1-s44>`__
     Unexpected `long response <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/673/archives/log.html.gz#s1-s44-t3-k2-k5-k1-k2-k1-k2-k1-k6-k2-k1-k2-k1-k1-k3-k3-k1>`__ from /restconf/modules when verifying shard stability.

  - Chasing the Leader: `PASS <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/674/archives/log.html.gz#s1-s46>`__ with reduced performance.

- Netconf system tests:

 - Basic access: `PASS <https://logs.opendaylight.org/releng/jenkins092/netconf-csit-3node-clustering-only-carbon/518/archives/log.html.gz#s1-s2>`__
 - Onwer killed: `PASS <https://logs.opendaylight.org/releng/jenkins092/netconf-csit-3node-clustering-only-carbon/518/archives/log.html.gz#s1-s5>`__
 - Rolling restarts: `PASS <https://logs.opendaylight.org/releng/jenkins092/netconf-csit-3node-clustering-only-carbon/518/archives/log.html.gz#s1-s7>`__

TODO: Common data points and commentary. Either here or in caveats.
