
Carbon SR1 test report
^^^^^^^^^^^^^^^^^^^^^^

Test Case Summary
-----------------

RelEng stability summary.

+ tba: Recent failures to be analyzed yet: 0.
+ test: Recent failures caused by wrong assumptions in test: 0.
+ akka: Recent failures related to pure UnreachableMember: 5.
+ tell: Recent failures not clearly caused by UnreachableMember: 7.
+ few: Tests passing unless sporadic UnreachableMember happens: 24 (23 without duplication).
+ pass: Tests passing consistently: 17 (15 without duplication).
+ Total: 53 (50 without duplication).
+ Total minus akka: 48 (45 without duplication).
+ Total minus akka passing always or mostly: 41 (38 without duplication).
+ Acceptance rate: 41/48=85.41% (38/45=84.44% without duplication).

Tables
------

S017 instead of 2017 means Sandbox run (includes changes not merged to stable/carbon yet).

Last fail is date of last failure not caused by infra
(or by a typo in test or by netconf/bgp failing to initialize properly).

"S 17" or "2 17" in Last run means the documented run was superseded by a newer one, but not analyzed yet.

"long ago" means the last real test failue happened before around 2017-05-19, or never.

.. table:: Releng stability results (pre-SR1)
   :widths: 30,10,20,20,10,10

   ===================  =====  ==========  ==========  =============================================================  ==========
   Scenario name        Type   Last fail   Last run    Bugs                                                           Robot link
   ===================  =====  ==========  ==========  =============================================================  ==========
   bgp-1n-1m-a_         pass   long ago    2017-06-30                                                                 `link <https://jenkins.opendaylight.org/releng/view/bgpcep/job/bgpcep-csit-1node-periodic-bgp-ingest-only-carbon/lastSuccessfulBuild/robot/bgpcep-bgp-ingest.txt/Singlepeer%20Prefixcount/>`__
   bgp-1n-300k-t_       pass   long ago    2017-06-30                                                                 `link <https://jenkins.opendaylight.org/releng/view/bgpcep/job/bgpcep-csit-1node-periodic-bgp-ingest-only-carbon/lastSuccessfulBuild/robot/bgpcep-bgp-ingest.txt/Singlepeer%20Pc%20Shm%20300Kroutes_1/>`__
   bgp-3n-300k-ll-t_    akka   2017-06-29  2017-06-30  `8318 <https://bugs.opendaylight.org/show_bug.cgi?id=8318>`__  `link <https://logs.opendaylight.org/releng/jenkins092/bgpcep-csit-3node-periodic-bgpclustering-only-carbon/325/log.html.gz#s1-s2-t8-k2-k3-k7-k4-k1-k6-k1-k1-k1-k1-k1-k2-k1-k4>`__
   bgp-3n-300k-lr-t_    akka   2017-06-26  2017-06-30  `8318 <https://bugs.opendaylight.org/show_bug.cgi?id=8318>`__  `link <https://logs.opendaylight.org/releng/jenkins092/bgpcep-csit-3node-periodic-bgpclustering-only-carbon/322/log.html.gz#s1-s4-t8-k2-k3-k7-k4-k1-k6-k1-k1-k1-k1-k1-k2-k1-k3-k2-k1>`__
   ddb-cls-ms-ll-t_     few    2017-06-15  2017-06-30  `8618 <https://bugs.opendaylight.org/show_bug.cgi?id=8618>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/749/log.html.gz#s1-s20-t1-k2-k10-k2-k1>`__
   ddb-cls-ms-lr-t_     tell   2017-06-29  2017-06-30  `8445 <https://bugs.opendaylight.org/show_bug.cgi?id=8445>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/765/log.html.gz#s1-s20-t3-k2-k8>`__
   ddb-cls-ps-ll-t_     few    2017-06-08  2017-06-30  `8643 <https://bugs.opendaylight.org/show_bug.cgi?id=8643>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/736/log.html.gz#s1-s22-t1-k2-k9>`__
   ddb-cls-ps-lr-t_     pass   long ago    2017-06-30                                                                 `link <https://jenkins.opendaylight.org/releng/view/controller/job/controller-csit-3node-clustering-only-carbon/lastSuccessfulBuild/robot/controller-clustering.txt/Clean%20Leader%20Shutdown%20Prefbasedshard/Remote_Leader_Shutdown/>`__
   ddb-elm-ms-lr-t_     few    2017-06-13  2017-06-30  `8618 <https://bugs.opendaylight.org/show_bug.cgi?id=8618>`__  `link <https://logs.opendaylight.org/sandbox/jenkins091/controller-csit-3node-clustering-only-carbon/31/log.html.gz#s1-s24-t1-k2-k10>`__
   ddb-elm-ms-rr-t_     few    2017-06-10  2017-06-30  `8618 <https://bugs.opendaylight.org/show_bug.cgi?id=8618>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/738/log.html.gz#s1-s24-t3-k2-k10>`__
   ddb-elm-ms-rl-t_     few    2017-06-27  2017-06-30  `8749 <https://bugs.opendaylight.org/show_bug.cgi?id=8749>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/763/log.html.gz#s1-s24-t5-k2-k10>`__
   ddb-elm-ps-lr-t_     few    2017-06-11  2017-06-30  `8664 <https://bugs.opendaylight.org/show_bug.cgi?id=8664>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/736/log.html.gz#s1-s26-t1-k2-k6-k3-k1-k4-k7-k1>`__
   ddb-elm-ps-rr-t_     pass   long ago    2017-06-30                                                                 `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/lastSuccessfulBuild/log.html.gz#s1-s26-t3>`__
   ddb-elm-ps-rl-t_     few    2017-06-07  2017-06-30  `8403 <https://bugs.opendaylight.org/show_bug.cgi?id=8403>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/735/log.html.gz#s1-s26-t5-k2-k9>`__
   ddb-li-ms-st-t_      tell   2017-06-30  2017-06-30  `8782 <https://bugs.opendaylight.org/show_bug.cgi?id=8782>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/767/log.html.gz#s1-s28-t1-k2-k25-k1-k1>`__
   ddb-li-ms-dt-t_      tell   2017-06-30  2017-06-30  `8619 <https://bugs.opendaylight.org/show_bug.cgi?id=8619>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/767/log.html.gz#s1-s28-t3-k2-k25-k1-k8>`__
   ddb-li-ps-st-t_      few    2017-06-08  2017-06-30  `8371 <https://bugs.opendaylight.org/show_bug.cgi?id=8371>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/736/log.html.gz#s1-s30-t1-k2-k25-k1-k1>`__
   ddb-li-ps-dt-t_      tell   2017-06-30  2017-06-30  `8768 <https://bugs.opendaylight.org/show_bug.cgi?id=8768>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/765/log.html.gz#s1-s30-t3-k2-k25-k1-k8>`__
   ddb-ci-ms-ll-ct-t_   few    2017-06-07  2017-06-30  `8494 <https://bugs.opendaylight.org/show_bug.cgi?id=8494>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/735/log.html.gz#s1-s32-t1-k2-k16-k1-k1>`__
   ddb-ci-ms-ll-st-t_   tell   2017-06-30  2017-06-30  `8494 <https://bugs.opendaylight.org/show_bug.cgi?id=8494>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/767/log.html.gz#s1-s32-t3-k2-k16-k1-k1>`__
   ddb-ci-ms-lr-ct-t_   few    2017-06-08  2017-06-30  `8636 <https://bugs.opendaylight.org/show_bug.cgi?id=8636>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/736/log.html.gz#s1-s32-t5-k2-k15-k1-k1-k1-k1-k1-k1-k2-k1-k1-k1>`__
   ddb-ci-ms-lr-st-t_   tell   2017-06-30  2017-06-30  `8494 <https://bugs.opendaylight.org/show_bug.cgi?id=8494>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/767/log.html.gz#s1-s32-t7-k2-k16-k1-k1>`__
   ddb-ci-ps-ll-ct-t_   few    2017-06-28  2017-06-30  `8494 <https://bugs.opendaylight.org/show_bug.cgi?id=8494>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/764/log.html.gz#s1-s34-t1-k2-k16-k1-k1>`__
   ddb-ci-ps-ll-st-t_   few    2017-06-28  2017-06-30  `8494 <https://bugs.opendaylight.org/show_bug.cgi?id=8494>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/764/log.html.gz#s1-s34-t3-k2-k16-k1-k1>`__
   ddb-ci-ps-lr-ct-t_   few    2017-06-28  2017-06-30  `8494 <https://bugs.opendaylight.org/show_bug.cgi?id=8494>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/764/log.html.gz#s1-s34-t5-k2-k16-k1-k1>`__
   ddb-ci-ps-lr-st-t_   few    2017-06-28  2017-06-30  `8494 <https://bugs.opendaylight.org/show_bug.cgi?id=8494>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/764/log.html.gz#s1-s34-t7-k2-k16-k1-k1>`__
   ddb-ls-ms-lr-t_      few    2017-06-29  2017-06-30  `8704 <https://bugs.opendaylight.org/show_bug.cgi?id=8704>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/765/log.html.gz#s1-s36-t1-k2-k12>`__
   ddb-ls-ms-rr-t_      few    2017-06-28  2017-06-30  `8704 <https://bugs.opendaylight.org/show_bug.cgi?id=8704>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/764/log.html.gz#s1-s36-t3-k2-k12>`__
   ddb-ls-ms-rl-t_      few    2017-06-29  2017-06-30  `8704 <https://bugs.opendaylight.org/show_bug.cgi?id=8704>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/765/log.html.gz#s1-s36-t5-k2-k12>`__
   ddb-ls-ps-lr-t_      pass   long ago    2017-06-30                                                                 `link <https://jenkins.opendaylight.org/releng/job/controller-csit-3node-clustering-only-carbon/lastSuccessfulBuild/robot/controller-clustering.txt/Listener%20Stability%20Prefbasedshard/Move_Leader_From_Listener_Local_To_Remote/>`__
   ddb-ls-ps-rr-t_      few    2017-06-26  2017-06-30  `8733 <https://bugs.opendaylight.org/show_bug.cgi?id=8733>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/762/log.html.gz#s1-s38-t3-k2-k14-k2-k1-k4-k7-k1>`__
   ddb-ls-ps-rl-t_      pass   long ago    2017-06-30                                                                 `link <https://jenkins.opendaylight.org/releng/job/controller-csit-3node-clustering-only-carbon/lastSuccessfulBuild/robot/controller-clustering.txt/Listener%20Stability%20Prefbasedshard/Move_Leader_From_Listener_Remote_To_Local/>`__
   drb-rpp-ms-a_        pass   long ago    2017-06-30                                                                 `link <https://jenkins.opendaylight.org/releng/view/controller/job/controller-csit-3node-clustering-only-carbon/lastSuccessfulBuild/robot/controller-clustering.txt/Rpc%20Provider%20Precedence/>`__
   drb-rph-ms-a_        few    2017-06-28  2017-06-30  `8430 <https://bugs.opendaylight.org/show_bug.cgi?id=8430>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/764/log.html.gz#s1-s4-t6-k2-k1-k1-k1-k1-k1-k1-k2-k1-k1-k1-k3-k1-k1-k1-k2-k1-k4-k7-k1>`__
   drb-app-ms-a_        pass   long ago    2017-06-30                                                                 `link <https://jenkins.opendaylight.org/releng/view/controller/job/controller-csit-3node-clustering-only-carbon/lastSuccessfulBuild/robot/controller-clustering.txt/Action%20Provider%20Precedence/>`__
   drb-aph-ms-a_        few    2017-05-22  2017-06-30  `8430 <https://bugs.opendaylight.org/show_bug.cgi?id=8430>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/718/archives/log.html.gz#s1-s8-t6-k2-k3-k2-k1-k1-k1-k1-k1-k1-k1-k2-k1-k1-k1-k3-k1-k4-k7-k1>`__
   dnb-1n-60k-a_        pass   long ago    2017-06-30                                                                 `link <https://jenkins.opendaylight.org/releng/view/controller/job/controller-csit-1node-rest-cars-perf-only-carbon/lastSuccessfulBuild/robot/controller-rest-cars-perf.txt/Noloss%20Rate%201Node/>`__
   ss-ms-ms-a_          pass   long ago    2017-06-30                                                                 `link <https://jenkins.opendaylight.org/releng/view/controller/job/controller-csit-3node-clustering-only-carbon/lastSuccessfulBuild/robot/controller-clustering.txt/Master%20Stability/>`__
   ss-ph-ms-a_          few    2017-06-29  2017-06-30  `8420 <https://bugs.opendaylight.org/show_bug.cgi?id=8420>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/765/log.html.gz#s1-s12-t5-k2-k3-k1-k2>`__
   ss-cl-ms-a_          pass   long ago    2017-06-30                                                                 `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/lastSuccessfulBuild/log.html.gz#s1-s14>`__
   ss-ms-ms-t_          pass   long ago    2017-06-30                                                                 `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/lastSuccessfulBuild/log.html.gz#s1-s40>`__
   ss-ph-ms-t_          few    2017-06-26  2017-06-30  `8420 <https://bugs.opendaylight.org/show_bug.cgi?id=8420>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/762/log.html.gz#s1-s42-t5-k2-k3-k1-k2>`__
   ss-cl-ms-t_          pass   long ago    2017-06-30                                                                 `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/lastSuccessfulBuild/log.html.gz#s1-s44>`__
   netconf-ba-ms-a_     pass   long ago    2017-06-30                                                                 `link <https://jenkins.opendaylight.org/releng/view/netconf/job/netconf-csit-3node-clustering-only-carbon/lastSuccessfulBuild/robot/netconf-clustering.txt/CRUD>`__
   netconf-ok-ms-a_     few    2017-06-18  2017-06-30  `8596 <https://bugs.opendaylight.org/show_bug.cgi?id=8596>`__  `link <https://logs.opendaylight.org/releng/jenkins092/netconf-csit-3node-clustering-only-carbon/568/log.html.gz#s1-s5-t17-k2-k3-k2-k2-k1>`__
   netconf-rr-ms-a_     pass   long ago    2017-06-30                                                                 `link <https://jenkins.opendaylight.org/releng/view/netconf/job/netconf-csit-3node-clustering-only-carbon/lastSuccessfulBuild/robot/netconf-clustering.txt/Outages>`__
   bgp-3n-300k-t-long_  akka   2017-06-25  2017-06-25  `8318 <https://bugs.opendaylight.org/show_bug.cgi?id=8318>`__  `link <https://logs.opendaylight.org/releng/jenkins092/bgpcep-csit-3node-bgpclustering-longevity-only-carbon/9/log.html.gz#s1-s2-t1-k10-k1-k1-k1-k1-k1-k1-k1-k1-k1-k2-k1-k3-k7-k4-k1-k6-k1-k1-k1-k1-k1-k2-k1-k4>'__
   ddb-elm-mc-t-long_   tell   2017-06-25  2017-06-25  `8749 <https://bugs.opendaylight.org/show_bug.cgi?id=8749>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-ddb-expl-lead-movement-longevity-only-carbon/12/log.html.gz#s1-s2-t1-k2-k1-k1-k1-k1-k1-k1-k2-k1-k1-k2-k10>`__
   drb-rpp-ms-a-long_   few    2017-05-07  2017-06-04  `8430 <https://bugs.opendaylight.org/show_bug.cgi?id=8430>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-drb-partnheal-longevity-only-carbon/13/console.log.gz>`__
   drb-rph-ms-a-long_   akka   2017-06-18  2017-06-18  `8430 <https://bugs.opendaylight.org/show_bug.cgi?id=8430>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-drb-partnheal-longevity-only-carbon/15/log.html.gz#s1-t1-k3-k1-k1-k1-k1-k1-k1-k2-k1-k1-k6-k1-k1-k1-k1-k1-k1-k2-k1-k1-k1-k3-k1-k1-k1-k2-k1-k4-k7-k1>`__
   dnb-1n-60k-a-long_   pass   long ago    2017-06-18                                                                 `link <https://jenkins.opendaylight.org/releng/view/controller/job/controller-csit-1node-rest-cars-perf-only-carbon/620/robot/controller-rest-cars-perf.txt/Noloss%20Rate%201Node/>`__
   ss-ph-ms-a-long_     akka   2017-06-25  2017-06-25  `8420 <https://bugs.opendaylight.org/show_bug.cgi?id=8420>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-cs-partnheal-longevity-only-carbon/13/log.html.gz#s1-s2-t1-k3-k1-k1-k1-k1-k1-k1-k1-k1-k1-k7-k3-k1-k2>`__
   ss-cl-ms-a-long_     pass   long ago    2017-06-12                                                                 `link <https://jenkins.opendaylight.org/releng/view/controller/job/controller-csit-1node-rest-cars-perf-only-carbon/620/robot/controller-rest-cars-perf.txt/Noloss%20Rate%201Node/>`__
   ===================  =====  ==========  ==========  =============================================================  ==========

Description:

+ DOMDataBroker: Producers make 1000 transactions per second, except BGP which works full speed.

 + Leader stability: BGP inject benchmark (thus module shards only), 1 Python peer. Progress tracked by counting prefixes in example-ipv4-topology.

  + Single member:

   .. _bgp-1n-1m-a:

   + Ask-based protocol, 1M prefixes: bgp-1n-1m-a

   .. _bgp-1n-1m-t:

   + Tell-based protocol, 300k prefixes to avoid `Bug 8649 <https://bugs.opendaylight.org/show_bug.cgi?id=8749>`__.: bgp-1n-300k-t

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

   + Tell-based protocol:

    .. _ddb-elm-ms-lr-t:

    + Local leader to remote: ddb-elm-ms-lr-t

    .. _ddb-elm-ms-rr-t:

    + Remote leader to other remote: ddb-elm-ms-rr-t

    .. _ddb-elm-ms-rl-t:

    + Remote leader to local: ddb-elm-ms-rl-t

    .. _ddb-elm-mc-t-long:

    + Longevity: ddb-elm-mc-t-long

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

    .. _ddb-ls-ms-lr-t:

    + Local to remote: ddb-ls-ms-lr-t

    .. _ddb-ls-ms-rr-t:

    + Remote to remote: ddb-ls-ms-rr-t

    .. _ddb-ls-ms-rl-t:

    + Remote to local: ddb-ls-ms-rl-t

  + Prefix-based shards:

   + Tell-based protocol:

    .. _ddb-ls-ps-lr-t:

    + Local to remote: ddb-ls-ps-lr-t

    .. _ddb-ls-ps-rr-t:

    + Remote to remote: ddb-ls-ps-rr-t

    .. _ddb-ls-ps-rl-t:

    + Remote to local: ddb-ls-ps-rl-t

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
