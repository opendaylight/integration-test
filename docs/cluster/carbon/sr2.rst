
Carbon SR2 test report
^^^^^^^^^^^^^^^^^^^^^^

Test Case Summary
-----------------

RelEng stability summary.

+ tba: Recent failures to be analyzed yet: 0.
+ test: Recent failures caused by wrong assumptions in test: 0.
+ akka: Recent failures related to pure UnreachableMember: 4.
+ tell: Recent failures not clearly caused by UnreachableMember: 4.
+ few: Tests passing unless low frequency failure happens: 7 (6 without duplication).
  (Low frequency means UnreachableMemeber or similar,
  related to Akka where Controller code has not real control.)
+ pass: Tests passing consistently: 38 (36 without duplication).
+ Total: 53 (50 without duplication).
+ Total minus akka: 49 (46 without duplication).
+ Total minus akka, passing always or mostly: 45 (42 without duplication).
+ Acceptance rate: 45/49=91.83% (42/46=91.30% without duplication).

Table
-----

S017 instead of 2017 means Sandbox run (includes changes not merged to stable/carbon yet).

Last fail is date of last failure not caused by infra
(or by a typo in test or by netconf/bgp failing to initialize properly).

"S 17" or "2 17" in Last run means the documented run was superseded by a newer one, but not analyzed yet.

"few" status from SR1 is not inherited (such tests are marked as "pass").
"long ago" means the last real test failue happened somewhere around SR1 release (or before that, or never).

If status is a link, it points to the latest relevant robot failure, or a history to see the stability.
In case of failure, Bugs field gives the reason of that failure.

.. table:: Releng stability results (post SR1, pre SR2)
   :widths: 40,15,15,15,15

   ===================  ==========  ==========  =============================================================  ======
   Test case            Last fail   Last run    Bugs                                                           Status
   ===================  ==========  ==========  =============================================================  ======
   bgp-1n-300k-a_       long ago    2017-09-12                                                                 `PASS <https://jenkins.opendaylight.org/releng/view/bgpcep/job/bgpcep-csit-1node-periodic-bgp-ingest-all-carbon/lastSuccessfulBuild/robot/bgpcep-bgp-ingest.txt/Singlepeer%20Pc%20Shm%20300Kroutes/>`__
   bgp-1n-300k-t_       long ago    2017-09-12                                                                 `PASS <https://jenkins.opendaylight.org/releng/view/bgpcep/job/bgpcep-csit-1node-periodic-bgp-ingest-all-carbon/lastSuccessfulBuild/robot/bgpcep-bgp-ingest.txt/Singlepeer%20Pc%20Shm%20300Kroutes_1/>`__
   bgp-3n-300k-ll-t_    2017-09-08  2017-09-12  `8318 <https://bugs.opendaylight.org/show_bug.cgi?id=8318>`__  `AKKA <https://logs.opendaylight.org/releng/jenkins092/bgpcep-csit-3node-periodic-bgpclustering-all-carbon/393/log.html.gz#s1-s2-t8-k2-k3-k7-k4-k1-k6-k1-k1-k1-k1-k1-k2-k1-k4>`__
   bgp-3n-300k-lr-t_    2017-09-12  2017-09-12  `8318 <https://bugs.opendaylight.org/show_bug.cgi?id=8318>`__  `AKKA <https://logs.opendaylight.org/releng/jenkins092/bgpcep-csit-3node-periodic-bgpclustering-all-carbon/397/log.html.gz#s1-s4-t9-k2-k3-k7-k6-k1-k6-k1-k1-k1-k1-k1-k2-k1-k4>`__
   ddb-cls-ms-ll-t_     2017-08-24  2017-09-12                                                                 `PASS <https://jenkins.opendaylight.org/releng/view/controller/job/controller-csit-3node-clustering-all-carbon/lastSuccessfulBuild/robot/controller-clustering.txt/Clean%20Leader%20Shutdown/Local_Leader_Shutdown>`__
   ddb-cls-ms-lr-t_     long ago    2017-09-12                                                                 `PASS <https://jenkins.opendaylight.org/releng/view/controller/job/controller-csit-3node-clustering-all-carbon/lastSuccessfulBuild/robot/controller-clustering.txt/Clean%20Leader%20Shutdown/Remote_Leader_Shutdown>`__
   ddb-cls-ps-ll-t_     long ago    2017-09-12                                                                 `PASS <https://jenkins.opendaylight.org/releng/view/controller/job/controller-csit-3node-clustering-all-carbon/lastSuccessfulBuild/robot/controller-clustering.txt/Clean%20Leader%20Shutdown%20Prefbasedshard/Local_Leader_Shutdown>`__
   ddb-cls-ps-lr-t_     long ago    2017-09-12                                                                 `PASS <https://jenkins.opendaylight.org/releng/view/controller/job/controller-csit-3node-clustering-all-carbon/lastSuccessfulBuild/robot/controller-clustering.txt/Clean%20Leader%20Shutdown%20Prefbasedshard/Remote_Leader_Shutdown>`__
   ddb-elm-ms-lr-t_     long ago    2017-09-12                                                                 `PASS <https://jenkins.opendaylight.org/releng/view/controller/job/controller-csit-3node-clustering-all-carbon/lastSuccessfulBuild/robot/controller-clustering.txt/Explicit%20Leader%20Movement/Local_To_Remote_Movement>`__
   ddb-elm-ms-rr-t_     long ago    2017-09-12                                                                 `PASS <https://jenkins.opendaylight.org/releng/view/controller/job/controller-csit-3node-clustering-all-carbon/lastSuccessfulBuild/robot/controller-clustering.txt/Explicit%20Leader%20Movement/Remote_To_Remote_Movement>`__
   ddb-elm-ms-rl-t_     long ago    2017-09-12                                                                 `PASS <https://jenkins.opendaylight.org/releng/view/controller/job/controller-csit-3node-clustering-all-carbon/lastSuccessfulBuild/robot/controller-clustering.txt/Explicit%20Leader%20Movement/Remote_To_Local_Movement>`__
   ddb-elm-ps-lr-t_     long ago    2017-09-12                                                                 `PASS <https://jenkins.opendaylight.org/releng/view/controller/job/controller-csit-3node-clustering-all-carbon/lastSuccessfulBuild/robot/controller-clustering.txt/Explicit%20Leader%20Movement%20Prefbasedshard/Local_To_Remote_Movement>`__
   ddb-elm-ps-rr-t_     long ago    2017-09-12                                                                 `PASS <https://jenkins.opendaylight.org/releng/view/controller/job/controller-csit-3node-clustering-all-carbon/lastSuccessfulBuild/robot/controller-clustering.txt/Explicit%20Leader%20Movement%20Prefbasedshard/Remote_To_Remote_Movement>`__
   ddb-elm-ps-rl-t_     long ago    2017-09-12                                                                 `PASS <https://jenkins.opendaylight.org/releng/view/controller/job/controller-csit-3node-clustering-all-carbon/lastSuccessfulBuild/robot/controller-clustering.txt/Explicit%20Leader%20Movement%20Prefbasedshard/Remote_To_Local_Movement>`__
   ddb-li-ms-st-t_      2017-08-18  2017-09-12                                                                 `PASS <https://jenkins.opendaylight.org/releng/view/controller/job/controller-csit-3node-clustering-all-carbon/lastSuccessfulBuild/robot/controller-clustering.txt/Leader%20Isolation/Healing_Within_Request_Timeout>`__
   ddb-li-ms-dt-t_      2017-08-21  2017-09-12                                                                 `PASS <https://jenkins.opendaylight.org/releng/view/controller/job/controller-csit-3node-clustering-all-carbon/lastSuccessfulBuild/robot/controller-clustering.txt/Leader%20Isolation/Healing_After_Request_Timeout>`__
   ddb-li-ps-st-t_      2017-09-01  2017-09-12                                                                 `PASS <https://jenkins.opendaylight.org/releng/view/controller/job/controller-csit-3node-clustering-all-carbon/lastSuccessfulBuild/robot/controller-clustering.txt/Leader%20Isolation%20Prefbasedshard/Healing_Within_Request_Timeout>`__
   ddb-li-ps-dt-t_      2017-09-12  2017-09-12  `8845 <https://bugs.opendaylight.org/show_bug.cgi?id=8845>`__  `TELL <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-all-carbon/439/log.html.gz#s1-s30-t3-k2-k25-k1-k8>`__
   ddb-ci-ms-ll-ct-t_   long ago    2017-09-12                                                                 `PASS <https://jenkins.opendaylight.org/releng/view/controller/job/controller-csit-3node-clustering-all-carbon/lastSuccessfulBuild/robot/controller-clustering.txt/Client%20Isolation/Producer_On_Shard_Leader_Node_ChainedTx>`__
   ddb-ci-ms-ll-st-t_   long ago    2017-09-12                                                                 `PASS <https://jenkins.opendaylight.org/releng/view/controller/job/controller-csit-3node-clustering-all-carbon/lastSuccessfulBuild/robot/controller-clustering.txt/Client%20Isolation/Producer_On_Shard_Leader_Node_SimpleTx>`__
   ddb-ci-ms-lr-ct-t_   long ago    2017-09-12                                                                 `PASS <https://jenkins.opendaylight.org/releng/view/controller/job/controller-csit-3node-clustering-all-carbon/lastSuccessfulBuild/robot/controller-clustering.txt/Client%20Isolation/Producer_On_Shard_Non_Leader_Node_ChainedTx>`__
   ddb-ci-ms-lr-st-t_   long ago    2017-09-12                                                                 `PASS <https://jenkins.opendaylight.org/releng/view/controller/job/controller-csit-3node-clustering-all-carbon/lastSuccessfulBuild/robot/controller-clustering.txt/Client%20Isolation/Producer_On_Shard_Non_Leader_Node_SimpleTx>`__
   ddb-ci-ps-ll-it-t_   long ago    2017-09-12                                                                 `PASS <https://jenkins.opendaylight.org/releng/view/controller/job/controller-csit-3node-clustering-all-carbon/lastSuccessfulBuild/robot/controller-clustering.txt/Client%20Isolation%20Prefbasedshard/Producer_On_Shard_Leader_Node_Isolated_Transactions>`__
   ddb-ci-ps-ll-nt-t_   long ago    2017-09-12                                                                 `PASS <https://jenkins.opendaylight.org/releng/view/controller/job/controller-csit-3node-clustering-all-carbon/lastSuccessfulBuild/robot/controller-clustering.txt/Client%20Isolation%20Prefbasedshard/Producer_On_Shard_Leader_Node_Nonisolated_Transactions>`__
   ddb-ci-ps-lr-it-t_   long ago    2017-09-12                                                                 `PASS <https://jenkins.opendaylight.org/releng/view/controller/job/controller-csit-3node-clustering-all-carbon/lastSuccessfulBuild/robot/controller-clustering.txt/Client%20Isolation%20Prefbasedshard/Producer_On_Shard_Non_Leader_Node_Isolated_Transactions>`__
   ddb-ci-ps-lr-nt-t_   long ago    2017-09-12                                                                 `PASS <https://jenkins.opendaylight.org/releng/view/controller/job/controller-csit-3node-clustering-all-carbon/lastSuccessfulBuild/robot/controller-clustering.txt/Client%20Isolation%20Prefbasedshard/Producer_On_Shard_Non_Leader_Node_Nonisolated_Transactions>`__
   ddb-ls-ms-lr-t_      long ago    2017-09-12                                                                 `PASS <https://jenkins.opendaylight.org/releng/view/controller/job/controller-csit-3node-clustering-all-carbon/lastSuccessfulBuild/robot/controller-clustering.txt/Listener%20Stability/Move_Leader_From_Listener_Local_To_Remote>`__
   ddb-ls-ms-rr-t_      long ago    2017-09-12                                                                 `PASS <https://jenkins.opendaylight.org/releng/view/controller/job/controller-csit-3node-clustering-all-carbon/lastSuccessfulBuild/robot/controller-clustering.txt/Listener%20Stability/Move_Leader_From_Listener_Remote_To_Other_Remote>`__
   ddb-ls-ms-rl-t_      long ago    2017-09-12                                                                 `PASS <https://jenkins.opendaylight.org/releng/view/controller/job/controller-csit-3node-clustering-all-carbon/lastSuccessfulBuild/robot/controller-clustering.txt/Listener%20Stability/Move_Leader_From_Listener_Remote_To_Local>`__
   ddb-ls-ps-lr-t_      2017-09-12  2017-09-12  `8733 <https://bugs.opendaylight.org/show_bug.cgi?id=8733>`__  `TELL <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-all-carbon/439/log.html.gz#s1-s38-t1-k2-k14-k2-k1-k4-k7-k1>`__
   ddb-ls-ps-rr-t_      2017-09-12  2017-09-12  `8733 <https://bugs.opendaylight.org/show_bug.cgi?id=8733>`__  `TELL <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-all-carbon/439/log.html.gz#s1-s38-t3-k2-k14-k2-k1-k4-k7-k1>`__
   ddb-ls-ps-rl-t_      2017-08-25  2017-09-12  `8733 <https://bugs.opendaylight.org/show_bug.cgi?id=8733>`__  `FEW <https://jenkins.opendaylight.org/releng/view/controller/job/controller-csit-3node-clustering-all-carbon/lastSuccessfulBuild/robot/controller-clustering.txt/Listener%20Stability%20Prefbasedshard/Move_Leader_From_Listener_Remote_To_Local/>`__
   drb-rpp-ms-a_        long ago    2017-09-12                                                                 `PASS <https://jenkins.opendaylight.org/releng/view/controller/job/controller-csit-3node-clustering-all-carbon/lastSuccessfulBuild/robot/controller-clustering.txt/Rpc%20Provider%20Precedence>`__
   drb-rph-ms-a_        long ago    2017-09-12                                                                 `PASS <https://jenkins.opendaylight.org/releng/view/controller/job/controller-csit-3node-clustering-all-carbon/lastSuccessfulBuild/robot/controller-clustering.txt/Rpc%20Provider%20Partition%20And%20Heal>`__
   drb-app-ms-a_        long ago    2017-09-12                                                                 `PASS <https://jenkins.opendaylight.org/releng/view/controller/job/controller-csit-3node-clustering-all-carbon/lastSuccessfulBuild/robot/controller-clustering.txt/Action%20Provider%20Precedence>`__
   drb-aph-ms-a_        long ago    2017-09-12                                                                 `PASS <https://jenkins.opendaylight.org/releng/view/controller/job/controller-csit-3node-clustering-all-carbon/lastSuccessfulBuild/robot/controller-clustering.txt/Action%20Provider%20Partition%20And%20Heal>`__
   dnb-1n-60k-a_        long ago    2017-09-12                                                                 `PASS <https://jenkins.opendaylight.org/releng/view/controller/job/controller-csit-1node-rest-cars-perf-all-carbon/lastSuccessfulBuild/robot/controller-rest-cars-perf.txt/Noloss%20Rate%201Node/>`__
   ss-ms-ms-a_          long ago    2017-09-12                                                                 `PASS <https://jenkins.opendaylight.org/releng/view/controller/job/controller-csit-3node-clustering-all-carbon/lastSuccessfulBuild/robot/controller-clustering.txt/Master%20Stability>`__
   ss-ph-ms-a_          2017-09-01  2017-09-12  `8420 <https://bugs.opendaylight.org/show_bug.cgi?id=8420>`__  `FEW <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-all-carbon/427/log.html.gz#s1-s12-t5-k2-k3-k1-k2>`__
   ss-cl-ms-a_          long ago    2017-09-12                                                                 `PASS <https://jenkins.opendaylight.org/releng/view/controller/job/controller-csit-3node-clustering-all-carbon/lastSuccessfulBuild/robot/controller-clustering.txt/Chasing%20The%20Leader>`__
   ss-ms-ms-t_          long ago    2017-09-12                                                                 `PASS <https://jenkins.opendaylight.org/releng/view/controller/job/controller-csit-3node-clustering-all-carbon/lastSuccessfulBuild/robot/controller-clustering.txt/Master%20Stability_1>`__
   ss-ph-ms-t_          2017-08-10  2017-09-12  `8420 <https://bugs.opendaylight.org/show_bug.cgi?id=8420>`__  `FEW <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-all-carbon/437/log.html.gz#s1-s42-t5-k2-k3-k1-k2>`__
   ss-cl-ms-t_          long ago    2017-09-12                                                                 `PASS <https://jenkins.opendaylight.org/releng/view/controller/job/controller-csit-3node-clustering-all-carbon/lastSuccessfulBuild/robot/controller-clustering.txt/Chasing%20The%20Leader_1>`__
   netconf-ba-ms-a_     long ago    2017-09-12                                                                 `PASS <https://jenkins.opendaylight.org/releng/view/netconf/job/netconf-csit-3node-clustering-all-carbon/615/robot/netconf-clustering.txt/CRUD>`__
   netconf-ok-ms-a_     long ago    2017-09-12                                                                 `PASS <https://jenkins.opendaylight.org/releng/view/netconf/job/netconf-csit-3node-clustering-all-carbon/lastSuccessfulBuild/robot/netconf-clustering.txt/Entity/>`__
   netconf-rr-ms-a_     2017-09-06  2017-09-12  `9027 <https://bugs.opendaylight.org/show_bug.cgi?id=9027>`__  `TELL <https://logs.opendaylight.org/releng/jenkins092/netconf-csit-3node-clustering-all-carbon/394/log.html.gz#s1-s9-t9-k2-k2-k8-k1-k2-k1-k1-k2-k1-k4-k1>`__
   bgp-3n-300k-t-long_  2017-09-09  2017-09-09  `8318 <https://bugs.opendaylight.org/show_bug.cgi?id=8318>`__  `AKKA <https://logs.opendaylight.org/releng/jenkins092/bgpcep-csit-3node-bgpclustering-longevity-only-carbon/20/log.html.gz#s1-s2-t1-k10-k1-k1-k1-k1-k1-k1-k1-k1-k1-k2-k2-k3-k7-k2-k1-k6-k1-k1-k1-k1-k1-k2-k1-k1-k2-k1-k2-k1-k6-k1-k1-k1-k5-k1-k3-k1>`__
   ddb-elm-mc-t-long_   2017-08-06  2017-09-02  `8959 <https://bugs.opendaylight.org/show_bug.cgi?id=8959>`__  `FEW <https://jenkins.opendaylight.org/releng/view/controller/job/controller-csit-3node-ddb-expl-lead-movement-longevity-only-carbon/lastSuccessfulBuild/robot/controller-ddb-expl-lead-movement-longevity.txt/Explicit%20Leader%20Movement%20Longevity/>`__
   drb-rpp-ms-a-long_   long ago    2017-09-02  `8959 <https://bugs.opendaylight.org/show_bug.cgi?id=8959>`__  `FEW <https://jenkins.opendaylight.org/releng/view/controller/job/controller-csit-3node-drb-precedence-longevity-only-carbon/lastSuccessfulBuild/robot/>`__
   drb-rph-ms-a-long_   2017-08-12  2017-09-02  `8430 <https://bugs.opendaylight.org/show_bug.cgi?id=8430>`__  `FEW <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-drb-partnheal-longevity-only-carbon/23/log.html.gz#s1-t1-k3-k1-k1-k1-k1-k1-k1-k1-k1-k1-k1-k1-k3-k1-k1-k1-k2-k1-k4-k7-k1>`__
   dnb-1n-60k-a-long_   long ago    2017-09-02  `8959 <https://bugs.opendaylight.org/show_bug.cgi?id=8959>`__  `FEW <https://jenkins.opendaylight.org/releng/view/controller/job/controller-csit-1node-notifications-longevity-only-carbon/lastSuccessfulBuild/robot/>`__
   ss-ph-ms-a-long_     2017-09-02  2017-09-02  `8420 <https://bugs.opendaylight.org/show_bug.cgi?id=8420>`__  `AKKA <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-cs-partnheal-longevity-only-carbon/23/log.html.gz#s1-s2-t1-k3-k1-k1-k4>`__
   ss-cl-ms-a-long_     2017-08-06  2017-09-09                                                                 `PASS <https://jenkins.opendaylight.org/releng/view/controller/job/controller-csit-3node-cs-chasing-leader-longevity-only-carbon/lastSuccessfulBuild/robot/controller-cs-chasing-leader-longevity.txt/Chasing%20The%20Leader%20Longevity/>`__
   ===================  ==========  ==========  =============================================================  ======

.. _bgp-1n-300k-a: tests.html#bgp-1n-300k-a
.. _bgp-1n-300k-t: tests.html#bgp-1n-300k-t
.. _bgp-3n-300k-ll-t: tests.html#bgp-3n-300k-ll-t
.. _bgp-3n-300k-lr-t: tests.html#bgp-3n-300k-lr-t
.. _ddb-cls-ms-ll-t: tests.html#ddb-cls-ms-ll-t
.. _ddb-cls-ms-lr-t: tests.html#ddb-cls-ms-lr-t
.. _ddb-cls-ps-ll-t: tests.html#ddb-cls-ps-ll-t
.. _ddb-cls-ps-lr-t: tests.html#ddb-cls-ps-lr-t
.. _ddb-elm-ms-lr-t: tests.html#ddb-elm-ms-lr-t
.. _ddb-elm-ms-rr-t: tests.html#ddb-elm-ms-rr-t
.. _ddb-elm-ms-rl-t: tests.html#ddb-elm-ms-rl-t
.. _ddb-elm-ps-lr-t: tests.html#ddb-elm-ps-lr-t
.. _ddb-elm-ps-rr-t: tests.html#ddb-elm-ps-rr-t
.. _ddb-elm-ps-rl-t: tests.html#ddb-elm-ps-rl-t
.. _ddb-li-ms-st-t: tests.html#ddb-li-ms-st-t
.. _ddb-li-ms-dt-t: tests.html#ddb-li-ms-dt-t
.. _ddb-li-ps-st-t: tests.html#ddb-li-ps-st-t
.. _ddb-li-ps-dt-t: tests.html#ddb-li-ps-dt-t
.. _ddb-ci-ms-ll-ct-t: tests.html#ddb-ci-ms-ll-ct-t
.. _ddb-ci-ms-ll-st-t: tests.html#ddb-ci-ms-ll-st-t
.. _ddb-ci-ms-lr-ct-t: tests.html#ddb-ci-ms-lr-ct-t
.. _ddb-ci-ms-lr-st-t: tests.html#ddb-ci-ms-lr-st-t
.. _ddb-ci-ps-ll-it-t: tests.html#ddb-ci-ps-ll-it-t
.. _ddb-ci-ps-ll-nt-t: tests.html#ddb-ci-ps-ll-nt-t
.. _ddb-ci-ps-lr-it-t: tests.html#ddb-ci-ps-lr-it-t
.. _ddb-ci-ps-lr-nt-t: tests.html#ddb-ci-ps-lr-nt-t
.. _ddb-ls-ms-lr-t: tests.html#ddb-ls-ms-lr-t
.. _ddb-ls-ms-rr-t: tests.html#ddb-ls-ms-rr-t
.. _ddb-ls-ms-rl-t: tests.html#ddb-ls-ms-rl-t
.. _ddb-ls-ps-lr-t: tests.html#ddb-ls-ps-lr-t
.. _ddb-ls-ps-rr-t: tests.html#ddb-ls-ps-rr-t
.. _ddb-ls-ps-rl-t: tests.html#ddb-ls-ps-rl-t
.. _drb-rpp-ms-a: tests.html#drb-rpp-ms-a
.. _drb-rph-ms-a: tests.html#drb-rph-ms-a
.. _drb-app-ms-a: tests.html#drb-app-ms-a
.. _drb-aph-ms-a: tests.html#drb-aph-ms-a
.. _dnb-1n-60k-a: tests.html#dnb-1n-60k-a
.. _ss-ms-ms-a: tests.html#ss-ms-ms-a
.. _ss-ph-ms-a: tests.html#ss-ph-ms-a
.. _ss-cl-ms-a: tests.html#ss-cl-ms-a
.. _ss-ms-ms-t: tests.html#ss-ms-ms-t
.. _ss-ph-ms-t: tests.html#ss-ph-ms-t
.. _ss-cl-ms-t: tests.html#ss-cl-ms-t
.. _netconf-ba-ms-a: tests.html#netconf-ba-ms-a
.. _netconf-ok-ms-a: tests.html#netconf-ok-ms-a
.. _netconf-rr-ms-a: tests.html#netconf-rr-ms-a
.. _bgp-3n-300k-t-long: tests.html#bgp-3n-300k-t-long
.. _ddb-elm-mc-t-long: tests.html#ddb-elm-mc-t-long
.. _drb-rpp-ms-a-long: tests.html#drb-rpp-ms-a-long
.. _drb-rph-ms-a-long: tests.html#drb-rph-ms-a-long
.. _dnb-1n-60k-a-long: tests.html#dnb-1n-60k-a-long
.. _ss-ph-ms-a-long: tests.html#ss-ph-ms-a-long
.. _ss-cl-ms-a-long: tests.html#ss-cl-ms-a-long
