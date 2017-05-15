
Carbon clustering test report
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Quick table:

=================    ==========    =============================================================    ======
Scenario name        Run date      Bug numbers                                                      Result
=================    ==========    =============================================================    ======
bgp-1n-1m-a_         2017-05-12    None                                                             `PASS <https://logs.opendaylight.org/releng/jenkins092/bgpcep-csit-1node-periodic-bgp-ingest-only-carbon/268/archives/log.html.gz#s1-s2>`__
bgp-1n-1m-t_         2017-05-12    None                                                             `PASS <https://logs.opendaylight.org/releng/jenkins092/bgpcep-csit-1node-periodic-bgp-ingest-only-carbon/268/archives/log.html.gz#s1-s9>`__
bgp-3n-300k-ll-a_    2017-05-11    `8318 <https://bugs.opendaylight.org/show_bug.cgi?id=8318>`__    `FAIL <https://logs.opendaylight.org/releng/jenkins092/bgpcep-csit-3node-periodic-bgpclustering-only-carbon/264/archives/log.html.gz#s1-s1-t8-k2-k3-k7-k4-k1-k6-k1-k1-k1-k1-k1-k2-k1-k1-k2-k5-k2-k1-k6-k2-k1-k5-k1-k3-k1>`__
bgp-3n-300k-lr-a_    2017-05-11    `8318 <https://bugs.opendaylight.org/show_bug.cgi?id=8318>`__    `FAIL <https://logs.opendaylight.org/releng/jenkins092/bgpcep-csit-3node-periodic-bgpclustering-only-carbon/264/archives/log.html.gz#s1-s3-t8-k2-k3-k7-k7-k1-k6-k1-k1-k1-k1-k1-k2-k1-k1-k2-k2-k2-k1-k6-k3-k1-k2-k1-k1-k3-k3-k1>`__
bgp-3n-300k-ll-t_    2017-05-11    `8318 <https://bugs.opendaylight.org/show_bug.cgi?id=8318>`__    `FAIL <https://logs.opendaylight.org/releng/jenkins092/bgpcep-csit-3node-periodic-bgpclustering-only-carbon/264/archives/log.html.gz#s1-s7-t8-k2-k3-k7-k2-k1-k6-k1-k1-k1-k1-k1-k2-k1-k3-k1>`__
bgp-3n-300k-lr-t_    2017-05-11    `8434 <https://bugs.opendaylight.org/show_bug.cgi?id=8434>`__    `FAIL <https://logs.opendaylight.org/releng/jenkins092/bgpcep-csit-3node-periodic-bgpclustering-only-carbon/264/archives/log.html.gz#s1-s9-t8-k2-k3-k7-k2-k1-k6-k1-k1-k1-k1-k1-k2-k1-k1-k2-k4-k2-k1-k6-k3-k1-k2-k1-k1-k3-k3-k1>`__
bgp-3n-300k-long_    2017-05-07    `8318 <https://bugs.opendaylight.org/show_bug.cgi?id=8318>`__    `FAIL <https://logs.opendaylight.org/releng/jenkins092/bgpcep-csit-3node-bgpclustering-longevity-only-carbon/2/archives/log.html.gz#s1-s2-t1-k9-k1-k1-k1-k1-k1-k1-k1-k1-k1-k2-k1-k3-k7-k3-k1-k6-k1-k1-k1-k1-k1-k2-k1-k3-k1>`__
ddb-cls-ms-ll-a_     2017-05-15    `5391 <https://bugs.opendaylight.org/show_bug.cgi?id=5391>`__    `FAIL <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/684/archives/log.html.gz#s1-s1-t1-k2-k9-k1>`__
ddb-cls-ms-lr-a_     2017-05-15    None                                                             `PASS <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/684/archives/log.html.gz#s1-s1-t2>`__
ddb-elm-ms-lr-a_     2017-05-15    None                                                             `PASS <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/684/archives/log.html.gz#s1-s3-t1>`__
ddb-elm-ms-rr-a_     2017-05-15    None                                                             `PASS <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/684/archives/log.html.gz#s1-s3-t2>`__
ddb-elm-ms-rl-a_     2017-05-15    None                                                             `PASS <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/684/archives/log.html.gz#s1-s3-t3>`__
ddb-ls-ms-ll-a_      2017-05-15    `8207 <https://bugs.opendaylight.org/show_bug.cgi?id=8207>`__    `FAIL <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/684/archives/log.html.gz#s1-s5-t1-k2-k14-k1-k1-k1>`__
ddb-ls-ms-lr-a_      2017-05-15    `8207 <https://bugs.opendaylight.org/show_bug.cgi?id=8207>`__    `FAIL <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/684/archives/log.html.gz#s1-s5-t2-k2-k14-k1-k1-k1>`__
drb-rpp-ms-a_        2017-05-15    None                                                             `PASS <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/684/archives/log.html.gz#s1-s7>`__
drb-rph-ms-a_        2017-05-15    None                                                             `PASS <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/684/archives/log.html.gz#s1-s9>`__
drb-app-ms-a_        2017-05-15    None                                                             `PASS <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/684/archives/log.html.gz#s1-s11>`__
drb-aph-ms-a_        2017-05-15    None                                                             `PASS <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/684/archives/log.html.gz#s1-s13>`__
ss-ms-ms-a_          2017-05-15    None                                                             `PASS <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/684/archives/log.html.gz#s1-s15>`__
ss-ph-ms-a_          2017-05-15    None                                                             `PASS <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/684/archives/log.html.gz#s1-s17>`__
ss-cl-ms-a_          2017-05-15    None                                                             `PASS <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/684/archives/log.html.gz#s1-s19>`__
=================    ==========    =============================================================    ======

Caveats:

+ Missing features:

 + Yang notifications are not delivered to peer members. `Bug 2139 <https://bugs.opendaylight.org/show_bug.cgi?id=2139>`__ is only fixed for data change notifications, not Yang notifications.

  + Notification suites are running on with 1-node setup only.

+ New features:

 + Tell-based protocol instead of ask-based protocol.

  + Some scenarios are expected to fail due to known limitations of ask-based protocol.

 + Prefix-based shards instead of module-based shards.
 + Producer options:

  + Used mostly chained transactions only. Standalone transactions are prone to OptimisticLockTransactions.

 + This results in multiple suites for the same scenario.

+ Reduced number of combinations:

 + Prefix-based shards always use tell-based protocol, so suites which test them with ask-based protocol configuration can be skipped.
 + Ask-based protocol is known to fail on AskTimeoutException in isolation scenarios, so suites which produce transactions constantly can be skipped.

+ Hard reboots between suites:

 + Timing errors in Robot code lead to Robot being unable to restore original state without restarts.
 + Almost 90 second per ODL reboot.

+ Isolation mechanics:

 + Used mostly iptables filtering. Freeze and kill affect the co-located java test driver.

  + Even then, AAA stops working (results in 401), so most checks on the isolated node are dropped anyway.

+ Reduced BGP scaling:

 + Rib owner maintains de-duplicated data structures. Other members get serialized copies and they do not de-duplicate.

+ Reduced Singleton performance:

 + Carbon is missing `an improvement <https://bugs.opendaylight.org/show_bug.cgi?id=7855>`__ which limits java test implementation.
 + Suite accepts 5 deregistrations per second.

+ Missing log.html:

 + Robot VM has only 2GB of RAM and longevity jobs tend to produce large output.xml files.
 + This affects mostly longevity jobs if they pass.

Description:

+ DOMDataBroker: Producers make 1000 transactions per second, except BGP which works full speed.

 + Leader stability: BGP inject benchmark (thus module shards only), 1 Python peer. Progress tracked by counting prefixes in example-ipv4-topology.

  + Single member, 1M prefixes:

   .. _bgp-1n-1m-a:

   + Ask-based protocol: bgp-1n-1m-a

   .. _bgp-1n-1m-t:

   + Tell-based protocol: bgp-1n-1m-t

  + Three members:

   + Original scale 1M perfixes: TODO: Remove and give bug number to Caveats.

   + Updated scale 300k prefixes:

    + Ask-based protocol:

     .. _bgp-3n-300k-ll-a:

     + Leaders local: bgp-3n-300k-ll-a

     .. _bgp-3n-300k-lr-a:

     + Leaders remote: bgp-3n-300k-lr-a

    + Tell-based protocol:

     .. _bgp-3n-300k-ll-t:

     + Leaders local: bgp-3n-300k-ll-t

     .. _bgp-3n-300k-lr-t:

     + Leaders remote: bgp-3n-300k-lr-t

     .. _bgp-3n-300k-long:

     + Longevity: bgp-3n-300k-long

 + Clean leader shutdown:

  + Module-based shards:

   + Ask-based protocol:

    .. _ddb-cls-ms-ll-a:

    + Shard leader local to producer: ddb-cls-ms-ll-a

    .. _ddb-cls-ms-lr-a:

    + Shard leader remote to producer: ddb-cls-ms-lr-a

  + Prefix-based shards:

   + Tell-based protocol:

    + Shard leader local to producer: FAIL Bug 8214: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s35-t1
    + Shard leader remote to producer: FAIL Bug 8214: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s35-t2

 + Explicit leader movement:

  + Module-based shards:

   + Ask-based protocol:

    .. _ddb-elm-ms-lr-a:

    + Local leader to remote: ddb-elm-ms-lr-a

    .. _ddb-elm-ms-rr-a:

    + Remote leader to other remote: ddb-elm-ms-rr-a

    .. _ddb-elm-ms-rl-a:

    + Remote leader to local: ddb-elm-ms-rl-a

  + Prefix-based shards:

   + Tell-based protocol:

    + Local leader to remote: FAIL Bug 8214: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s32-t1
    + Remote leader to other remote: FAIL Bug 8214: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s32-t2
    + Remote leader to local: FAIL Bug 8214: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s32-t3
    + Longevity tell-based (currently ask-based and failing on "no leader found" https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-ddb-expl-lead-movement-longevity-only-carbon/1/archives/log.html.gz )

 + Leader isolation (network partition only):

  + Module-based shards:

   + Tell-based protocol:

    + Heal within transaction timeout: FAIL Bug 8214: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s28-t1
    + Heal after transaction timeout: FAIL Bug 8214: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s28-t2

  + Prefix-based shards:

   + Tell-based protocol:

    + Heal within transaction timeout: FAIL Bug 8214: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s31-t1
    + Heal after transaction timeout: FAIL Bug 8214: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s31-t2

 + Client isolation:

  + Module-based shards:

   + Tell-based protocol:

    + Leader local:

     + Simple transactions: FAIL Bug 8214: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s29-t2
     + Transaction chain: FAIL Bug 8214: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s29-t1

    + Leader remote:

     + Simple transactions: FAIL Bug 8214: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s29-t4
     + Transaction chain: FAIL Bug 8214: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s29-t3

  + Prefix-based shards:

   + Tell-based protocol:

    + Leader local:

     + Simple transactions: FAIL Bug 8214: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s34-t2
     + Transaction chain: FAIL Bug 8214: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s34-t1

    + Leader remote:

     + Simple transactions: FAIL Bug 8214: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s34-t4
     + Transaction chain: FAIL Bug 8214: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s34-t3

 + Listener stablity:

  + Module-based shards:

   + Ask-based protocol:

    .. _ddb-ls-ms-ll-a:

    + Leader local: ddb-ls-ms-ll-a

    .. _ddb-ls-ms-lr-a:

    + Leader remote: ddb-ls-ms-lr-a

   + Tell-based protocol:

    + Leader local: FAIL Bug 8214: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s30-t1
    + Leader remote: FAIL Bug 8214: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s30-t2

  + Prefix-based shards:

   + Tell-based protocol:

    + Leader local: FAIL Bug 8214: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s33-t1
    + Leader remote: FAIL Bug 8214: https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/653/archives/log.html.gz#s1-s33-t2

+ DOMRpcBroker:

 .. _drb-rpp-ms-a:

 + RPC Provider Precedence: drb-rpp-ms-a

 .. _drb-rph-ms-a:

 + RPC Provider Partition and Heal: drb-rph-ms-a

 .. _drb-app-ms-a:

 + Action Provider Precedence: drb-app-ms-a

 .. _drb-aph-ms-a:

 + Action Provider Partition and Heal: drb-aph-ms-a
 + Longevity:

  + Provider precedence: `FAIL <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-drb-precedence-longevity-only-carbon/5/archives/log.html.gz#s1-t1>`__
    `501 after 5 minutes (119 iterations), nothing wrong in karaf.log <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-drb-precedence-longevity-only-carbon/5/archives/log.html.gz#s1-t1-k2-k1-k1-k1-k1-k1-k1-k2-k1-k1-k6-k1-k2-k1-k4-k7-k1>`__
  + Partition and Heal: FAIL after passing for 4 hours, VM stopped responding.
    `Console <https://jenkins.opendaylight.org/releng/view/controller/job/controller-csit-3node-drb-partnheal-longevity-only-carbon/7/console>`__

+ DOMNotificationBroker: Only for 1 member.

 + No-loss rate: Publisher-subscriber pairs, 5k nps per pair.

  + Functional (5 minute tests for 1, 4 and 12 pairs): `PASS <https://logs.opendaylight.org/releng/jenkins092/controller-csit-1node-rest-cars-perf-only-carbon/575/archives/log.html.gz#s1-s2>`__
  + Longevity (12 pairs): PASS but the job failed to compile log.html, see `karaf.log <https://logs.opendaylight.org/releng/jenkins092/controller-csit-1node-notifications-longevity-only-carbon/10/archives/odl1_karaf.log.gz>`__ instead.

+ Cluster Singleton:

 + Ask-based protocol:

  .. _ss-ms-ms-a:

  + Master Stability: ss-ms-ms-a

  .. _ss-ph-ms-a:

  + Partition and Heal: ss-ph-ms-a

  .. _ss-cl-ms-a:

  + Chasing the Leader: ss-cl-ms-a
  + Longevity:

   + Chasing the Leader: `PASS <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-cs-chasing-leader-longevity-only-carbon/3/archives/log.html.gz#s1-t3-k3-k4>`__ with reduced performance.
   + Partition and Heal: `FAIL <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-cs-partnheal-longevity-only-carbon/4/archives/log.html.gz#s1>`__ after 4 iterations.
     Reported as `Bug 8420 <https://bugs.opendaylight.org/show_bug.cgi?id=8420>`__.

 + Tell-based protocol:

  + Master Stability: `PASS <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/674/archives/log.html.gz#s1-s42>`__

  + Partition and Heal: different failures:

   + `FAIL <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/674/archives/log.html.gz#s1-s44>`__
     Unexpected `401 <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/674/archives/log.html.gz#s1-s44-t5-k2-k2-k1-k2-k1-k2-k1-k6-k3-k1-k2-k1-k1-k3-k4-k1>`__ while verifying shards are stable.
   + `FAIL <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/673/archives/log.html.gz#s1-s44>`__
     Unexpected `long response <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/673/archives/log.html.gz#s1-s44-t3-k2-k5-k1-k2-k1-k2-k1-k6-k2-k1-k2-k1-k1-k3-k3-k1>`__ from /restconf/modules when verifying shard stability.

  + Chasing the Leader: `PASS <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/674/archives/log.html.gz#s1-s46>`__ with reduced performance.

+ Netconf system tests:

 + Basic access: `PASS <https://logs.opendaylight.org/releng/jenkins092/netconf-csit-3node-clustering-only-carbon/518/archives/log.html.gz#s1-s2>`__
 + Onwer killed: `PASS <https://logs.opendaylight.org/releng/jenkins092/netconf-csit-3node-clustering-only-carbon/518/archives/log.html.gz#s1-s5>`__
 + Rolling restarts: `PASS <https://logs.opendaylight.org/releng/jenkins092/netconf-csit-3node-clustering-only-carbon/518/archives/log.html.gz#s1-s7>`__
