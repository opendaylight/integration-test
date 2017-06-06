
Carbon SR1 test report
^^^^^^^^^^^^^^^^^^^^^^

S017 instead of 2017 means Sandbox run (includes changes not merged to stable/carbon yet).

.. table:: Test results (pre-SR1)
   :widths: 40,30,10,10,10

   ===================    ==========    =================================================================    =========    ======
   Scenario name          Run date      Bug numbers                                                          fail type    Result
   ===================    ==========    =================================================================    =========    ======
   bgp-1n-1m-a_           2017-06-04                                                                                      `PASS <https://logs.opendaylight.org/releng/jenkins092/bgpcep-csit-1node-periodic-bgp-ingest-only-carbon/302/log.html.gz#s1-s2>`__
   bgp-1n-1m-t_           2017-06-04                                                                                      `PASS <https://logs.opendaylight.org/releng/jenkins092/bgpcep-csit-1node-periodic-bgp-ingest-only-carbon/302/log.html.gz#s1-s9>`__
   bgp-3n-300k-ll-t_      2017-06-04                                                                                      `PASS <https://logs.opendaylight.org/releng/jenkins092/bgpcep-csit-3node-periodic-bgpclustering-only-carbon/302/log.html.gz#s1-s2>`__
   bgp-3n-300k-lr-t_      2017-06-04    `8318 <https://bugs.opendaylight.org/show_bug.cgi?id=8318>`__        akka         `FAIL <https://logs.opendaylight.org/releng/jenkins092/bgpcep-csit-3node-periodic-bgpclustering-only-carbon/302/log.html.gz#s1-s4-t8-k2-k3-k7-k6-k1-k6-k1-k1-k1-k1-k1-k2-k1-k3-k1>`__
   ddb-cls-ms-ll-t_       S017-06-05                                                                                      `PASS <https://logs.opendaylight.org/sandbox/jenkins091/controller-csit-3node-clustering-only-carbon/4/log.html.gz#s1-s2-t1>`__
   ddb-cls-ms-lr-t_       2017-06-06                                                                                      `PASS <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/734/log.html.gz#s1-s20-t3>`__
   ddb-cls-ps-ll-t_       S017-06-05                                                                                      `PASS <https://logs.opendaylight.org/sandbox/jenkins091/controller-csit-3node-clustering-only-carbon/4/log.html.gz#s1-s4-t1>`__
   ddb-cls-ps-lr-t_       2017-06-06                                                                                      `PASS <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/734/log.html.gz#s1-s22-t3>`__
   ddb-elm-ms-lr-t_       2017-06-06                                                                                      `PASS <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/734/log.html.gz#s1-s24-t1>`__
   ddb-elm-ms-rr-t_       2017-06-06                                                                                      `PASS <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/734/log.html.gz#s1-s24-t3>`__
   ddb-elm-ms-rl-t_       S017-06-05                                                                                      `PASS <https://logs.opendaylight.org/sandbox/jenkins091/controller-csit-3node-clustering-only-carbon/4/log.html.gz#s1-s6-t5>`__
   ddb-elm-ps-lr-t_       S017-06-05    '8604 <https://bugs.opendaylight.org/show_bug.cgi?id=8604>`__                     `FAIL <https://logs.opendaylight.org/sandbox/jenkins091/controller-csit-3node-clustering-only-carbon/4/log.html.gz#s1-s8-t1-k2-k6-k3-k1-k4-k7-k1>`__
   ddb-elm-ps-rr-t_       2017-06-06                                                                                      `PASS <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/734/log.html.gz#s1-s26-t3>`__
   ddb-elm-ps-rl-t_       S017-06-05                                                                                      `PASS <https://logs.opendaylight.org/sandbox/jenkins091/controller-csit-3node-clustering-only-carbon/4/log.html.gz#s1-s8-t5>`__
   ddb-li-ms-st-t_        2017-06-06                                                                                      `PASS <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/734/log.html.gz#s1-s28-t1>`__
   ddb-li-ms-dt-t_        S017-06-05    `8602 <https://bugs.opendaylight.org/show_bug.cgi?id=8602>`__        tell/test    `FAIL <https://logs.opendaylight.org/sandbox/jenkins091/controller-csit-3node-clustering-only-carbon/4/log.html.gz#s1-s10-t3-k2-k25-k1-k8>`__
   ddb-li-ps-st-t_        2017-06-06                                                                                      `PASS <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/734/log.html.gz#s1-s30-t1>`__
   ddb-li-ps-dt-t_        S017-06-05    `8605 <https://bugs.opendaylight.org/show_bug.cgi?id=8605>`__        tell/test    `FAIL <https://logs.opendaylight.org/sandbox/jenkins091/controller-csit-3node-clustering-only-carbon/4/log.html.gz#s1-s12-t3-k2-k25-k1-k8>`__
   ddb-ci-ms-ll-ct-t_     2017-06-06                                                                                      `PASS <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/734/log.html.gz#s1-s32-t1>`__
   ddb-ci-ms-ll-st-t_     2017-06-06                                                                                      `PASS <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/734/log.html.gz#s1-s32-t3>`__
   ddb-ci-ms-lr-ct-t_     2017-06-06                                                                                      `PASS <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/734/log.html.gz#s1-s32-t5>`__
   ddb-ci-ms-lr-st-t_     2017-06-06                                                                                      `PASS <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/734/log.html.gz#s1-s32-t7>`__
   ddb-ci-ps-ll-ct-t_     S017-06-05    `8494 <https://bugs.opendaylight.org/show_bug.cgi?id=8494>`__        tell         `FAIL <https://logs.opendaylight.org/sandbox/jenkins091/controller-csit-3node-clustering-only-carbon/4/log.html.gz#s1-s16-t1-k2-k16-k1-k1>`__
   ddb-ci-ps-ll-st-t_     2017-06-06                                                                                      `PASS <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/734/log.html.gz#s1-s34-t3>`__
   ddb-ci-ps-lr-ct-t_     2017-06-06                                                                                      `PASS <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/734/log.html.gz#s1-s34-t5>`__
   ddb-ci-ps-lr-st-t_     2017-06-06                                                                                      `PASS <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/734/log.html.gz#s1-s34-t7>`__
   ddb-ls-ms-ll-t_        S017-06-05    `8606 <https://bugs.opendaylight.org/show_bug.cgi?id=8606>`__        tell/test    `FAIL <https://logs.opendaylight.org/sandbox/jenkins091/controller-csit-3node-clustering-only-carbon/4/log.html.gz#s1-s18-t1-k2-k12-k1-k3-k1>`__
   ddb-ls-ms-lr-t_        S017-06-05    `8606 <https://bugs.opendaylight.org/show_bug.cgi?id=8606>`__        tell/test    `FAIL <https://logs.opendaylight.org/sandbox/jenkins091/controller-csit-3node-clustering-only-carbon/4/log.html.gz#s1-s18-t3-k2-k12-k1-k3-k1>`__
   ddb-ls-ps-ll-t_        2017-06-04    `8403 <https://bugs.opendaylight.org/show_bug.cgi?id=8403#c18>`__    both         `FAIL <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/733/log.html.gz#s1-s38-t1-k2-k14>`__
   ddb-ls-ps-lr-t_        2017-06-04    `8403 <https://bugs.opendaylight.org/show_bug.cgi?id=8403#c18>`__    both         `FAIL <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/733/log.html.gz#s1-s38-t3-k2-k14>`__
   drb-rpp-ms-a_          2017-06-06                                                                                      `PASS <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/734/log.html.gz#s1-s2>`__
   drb-rph-ms-a_          2017-06-06                                                                                      `PASS <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/734/log.html.gz#s1-s4>`__
   drb-app-ms-a_          2017-06-06                                                                                      `PASS <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/734/log.html.gz#s1-s6>`__
   drb-aph-ms-a_          2017-06-06                                                                                      `PASS <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/734/log.html.gz#s1-s8>`__
   dnb-1n-60k-a_          2017-06-04                                                                                      `PASS <https://logs.opendaylight.org/releng/jenkins092/controller-csit-1node-rest-cars-perf-only-carbon/617/log.html.gz#s1-s2>`__
   ss-ms-ms-a_            2017-06-06                                                                                      `PASS <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/734/log.html.gz#s1-s10>`__
   ss-ph-ms-a_            2017-06-06    `8420 <https://bugs.opendaylight.org/show_bug.cgi?id=8420>`__        akka         `FAIL <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/734/log.html.gz#s1-s12-t5-k2-k3-k1-k2>`__
   ss-cl-ms-a_            2017-06-06                                                                                      `PASS <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/734/log.html.gz#s1-s14>`__
   ss-ms-ms-t_            2017-06-06                                                                                      `PASS <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/734/log.html.gz#s1-s40>`__
   ss-ph-ms-t_            2017-06-06    `8420 <https://bugs.opendaylight.org/show_bug.cgi?id=8420>`__        akka         `FAIL <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/734/log.html.gz#s1-s42-t5-k2-k3-k1-k2>`__
   ss-cl-ms-t_            2017-06-06                                                                                      `PASS <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/734/log.html.gz#s1-s44>`__
   netconf-ba-ms-a_       2017-06-06                                                                                      `PASS <https://logs.opendaylight.org/releng/jenkins092/netconf-csit-3node-clustering-only-carbon/557/log.html.gz#s1-s2>`__
   netconf-ok-ms-a_       2017-06-06                                                                                      `PASS <https://logs.opendaylight.org/releng/jenkins092/netconf-csit-3node-clustering-only-carbon/557/log.html.gz#s1-s5>`__
   netconf-rr-ms-a_       2017-06-06                                                                                      `PASS <https://logs.opendaylight.org/releng/jenkins092/netconf-csit-3node-clustering-only-carbon/557/log.html.gz#s1-s7>`__
   bgp-3n-300k-t-long_    S017-06-04    `8318 <https://bugs.opendaylight.org/show_bug.cgi?id=8318>`__        akka         `FAIL <https://logs.opendaylight.org/sandbox/jenkins091/bgpcep-csit-3node-bgpclustering-longevity-only-carbon/2/log.html.gz#s1-s2-t1-k10-k1-k1-k1-k1-k1-k1-k1-k1-k1-k2-k1-k3-k7-k5-k1-k6-k1-k1-k1-k1-k1-k2-k1-k1-k2-k2-k2-k1-k6-k2-k1-k5-k1-k3-k1>`__
   ddb-elm-mc-a-long_     S017-06-05    `8403 <https://bugs.opendaylight.org/show_bug.cgi?id=8403#c19>`__    both         `FAIL <https://logs.opendaylight.org/sandbox/jenkins091/controller-csit-3node-ddb-expl-lead-movement-longevity-only-carbon/2/log.html.gz#s1-s2-t1-k2-k1-k1-k1-k1-k1-k1-k2-k1-k1-k2-k10>`__
   drb-rpp-ms-a-long_     2017-05-29                                                                                      `PASS <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-drb-precedence-longevity-only-carbon/8/console.log.gz>`__
   drb-rph-ms-a-long_     2017-06-04    `8430 <https://bugs.opendaylight.org/show_bug.cgi?id=8430>`__        akka         `FAIL <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-drb-partnheal-longevity-only-carbon/13/console.log.gz>`__
   dnb-1n-60k-a-long_     2017-05-29    `8596 <https://bugs.opendaylight.org/show_bug.cgi?id=8596#c2>`__     test         `FAIL <https://jenkins.opendaylight.org/releng/view/controller/job/controller-csit-1node-notifications-longevity-only-carbon/13/console>`__
   ss-ph-ms-a-long_       2017-06-04    `8596 <https://bugs.opendaylight.org/show_bug.cgi?id=8596#c1>`__     test         `FAIL <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-cs-partnheal-longevity-only-carbon/10/log.html.gz#s1-s2-t1-k3-k1-k1-k1-k1-k1-k1-k2-k1-k1-k1-k1-k3-k1-k3-k1-k3-k1>`__
   ss-cl-ms-a-long_       2017-05-29                                                                                      `PASS <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-cs-chasing-leader-longevity-only-carbon/6/log.html.gz#s1-s2>`__
   ===================    ==========    =================================================================    =========    ======

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

    + Tell-based protocol:

     .. _bgp-3n-300k-ll-t:

     + Leaders local: bgp-3n-300k-ll-t

     .. _bgp-3n-300k-lr-t:

     + Leaders remote: bgp-3n-300k-lr-t

     .. _bgp-3n-300k-t-long:

     + Longevity: bgp-3n-300k-t-long

 + Clean leader shutdown:

  + Module-based shards:

   + Tell-based protocol:

    .. _ddb-cls-ms-ll-t:

    + Shard leader local to producer: ddb-cls-ms-ll-t

    .. _ddb-cls-ms-lr-t:

    + Shard leader remote to producer: ddb-cls-ms-lr-t

  + Prefix-based shards:

   + Tell-based protocol:

    .. _ddb-cls-ps-ll-t:

    + Shard leader local to producer: ddb-cls-ps-ll-t

    .. _ddb-cls-ps-lr-t:

    + Shard leader remote to producer: ddb-cls-ps-lr-t

 + Explicit leader movement:

  + Module-based shards:

    + Remote leader to local: ddb-elm-ms-rl-a

    .. _ddb-elm-mc-a-long:

    + Longevity: ddb-elm-mc-a-long

   + Tell-based protocol:

    .. _ddb-elm-ms-lr-t:

    + Local leader to remote: ddb-elm-ms-lr-t

    .. _ddb-elm-ms-rr-t:

    + Remote leader to other remote: ddb-elm-ms-rr-t

    .. _ddb-elm-ms-rl-t:

    + Remote leader to local: ddb-elm-ms-rl-t

  + Prefix-based shards:

   + Tell-based protocol:

    .. _ddb-elm-ps-lr-t:

    + Local leader to remote: ddb-elm-ps-lr-t

    .. _ddb-elm-ps-rr-t:

    + Remote leader to other remote: ddb-elm-ps-rr-t

    .. _ddb-elm-ps-rl-t:

    + Remote leader to local: ddb-elm-ps-rl-t

 + Leader isolation (network partition only):

  + Module-based shards:

   + Tell-based protocol:

    .. _ddb-li-ms-st-t:

    + Heal within transaction timeout: ddb-li-ms-st-t

    .. _ddb-li-ms-dt-t:

    + Heal after transaction timeout: ddb-li-ms-dt-t

  + Prefix-based shards:

   + Tell-based protocol:

    .. _ddb-li-ps-st-t:

    + Heal within transaction timeout: ddb-li-ps-st-t

    .. _ddb-li-ps-dt-t:

    + Heal after transaction timeout: ddb-li-ps-dt-t

 + Client isolation:

  + Module-based shards:

   + Tell-based protocol:

    + Leader local:

     .. _ddb-ci-ms-ll-st-t:

     + Simple transactions: ddb-ci-ms-ll-st-t

     .. _ddb-ci-ms-ll-ct-t:

     + Transaction chain: ddb-ci-ms-ll-ct-t

    + Leader remote:

     .. _ddb-ci-ms-lr-st-t:

     + Simple transactions: ddb-ci-ms-lr-st-t

     .. _ddb-ci-ms-lr-ct-t:

     + Transaction chain: ddb-ci-ms-lr-ct-t

  + Prefix-based shards:

   + Tell-based protocol:

    + Leader local:

     .. _ddb-ci-ps-ll-st-t:

     + Simple transactions: ddb-ci-ps-ll-st-t

     .. _ddb-ci-ps-ll-ct-t:

     + Transaction chain: ddb-ci-ps-ll-ct-t

    + Leader remote:

     .. _ddb-ci-ps-lr-st-t:

     + Simple transactions: ddb-ci-ps-lr-st-t

     .. _ddb-ci-ps-lr-ct-t:

     + Transaction chain: ddb-ci-ps-lr-ct-t

 + Listener stablity:

  + Module-based shards:

   + Tell-based protocol:

    .. _ddb-ls-ms-ll-t:

    + Leader local: ddb-ls-ms-ll-t

    .. _ddb-ls-ms-lr-t:

    + Leader remote: ddb-ls-ms-lr-t

  + Prefix-based shards:

   + Tell-based protocol:

    .. _ddb-ls-ps-ll-t:

    + Leader local: ddb-ls-ps-ll-t

    .. _ddb-ls-ps-lr-t:

    + Leader remote: ddb-ls-ps-lr-t

+ DOMRpcBroker:

 + RPC Provider Precedence:

  .. _drb-rpp-ms-a:

  + Functional: drb-rpp-ms-a

  .. _drb-rpp-ms-a-long:

  + Longevity: drb-rpp-ms-a-long

 + RPC Provider Partition and Heal:

  .. _drb-rph-ms-a:

  + Functional: drb-rph-ms-a

  .. _drb-rph-ms-a-long:

  + Longevity: drb-rph-ms-a-long

 .. _drb-app-ms-a:

 + Action Provider Precedence: drb-app-ms-a

 .. _drb-aph-ms-a:

 + Action Provider Partition and Heal: drb-aph-ms-a

+ DOMNotificationBroker: Only for 1 member.

 + No-loss rate: Publisher-subscriber pairs, 5k nps per pair.

  .. _dnb-1n-60k-a:

  + Functional (5 minute tests for 1, 4 and 12 pairs): dnb-1n-60k-a

  .. _dnb-1n-60k-a-long:

  + Longevity (12 pairs): dnb-1n-60k-a-long

+ Cluster Singleton:

 + Ask-based protocol:

  .. _ss-ms-ms-a:

  + Master Stability: ss-ms-ms-a

  + Partition and Heal:

   .. _ss-ph-ms-a:

   + Functional: ss-ph-ms-a

   .. _ss-ph-ms-a-long:

   + Longevity: ss-ph-ms-a-long

  + Chasing the Leader:

   .. _ss-cl-ms-a:

   + Functional: ss-cl-ms-a

   .. _ss-cl-ms-a-long:

   + Longevity: ss-cl-ms-a-long

 + Tell-based protocol:

  .. _ss-ms-ms-t:

  + Master Stability: ss-ms-ms-t

  .. _ss-ph-ms-t:

  + Partition and Heal: ss-ph-ms-t

  .. _ss-cl-ms-t:

  + Chasing the Leader: ss-cl-ms-t

+ Netconf system tests (ask-based protocol, module-based shards):

 .. _netconf-ba-ms-a:

 + Basic access: netconf-ba-ms-a

 .. _netconf-ok-ms-a:

 + Owner killed: netconf-ok-ms-a

 .. _netconf-rr-ms-a:

 + Rolling restarts: netconf-rr-ms-a
