
Carbon SR2 test report
^^^^^^^^^^^^^^^^^^^^^^

Test Case Summary
-----------------

RelEng stability summary.

+ tba: Recent failures to be analyzed yet: 0.
+ test: Recent failures caused by wrong assumptions in test: 0.
+ akka: Recent failures related to pure UnreachableMember: 5.
+ tell: Recent failures not clearly caused by UnreachableMember: 4.
+ few: Tests passing unless low frequency failure happens: 4 (3 without duplication).
  (Low frequency means UnreachableMemeber or similar,
  related to Akka where Controller code has not real control.)
+ pass: Tests passing consistently: 40 (38 without duplication).
+ Total: 53 (50 without duplication).
+ Total minus akka: 48 (45 without duplication).
+ Total minus akka, passing always or mostly: 44 (41 without duplication).
+ Acceptance rate: 44/48=87.50% (41/45=86.66% without duplication).

Tables
------

S017 instead of 2017 means Sandbox run (includes changes not merged to stable/carbon yet).

Last fail is date of last failure not caused by infra
(or by a typo in test or by netconf/bgp failing to initialize properly).

"S 17" or "2 17" in Last run means the documented run was superseded by a newer one, but not analyzed yet.

"few" status from SR1 is not inherited (such tests are marked as "pass").
"long ago" means the last real test failue happened somewhere around SR1 release (or never).

.. table:: Releng stability results (pre-SR1)
   :widths: 30,10,20,20,10,10

   ==================  =====  ==========  ==========  =============================================================  ==========
   Scenario name       Type   Last fail   Last run    Bugs                                                           Robot link
   ==================  =====  ==========  ==========  =============================================================  ==========
   bgp-1n-1m-a         pass   long ago    2017-07-25                                                                 no sr2 fail
   bgp-1n-300k-t       pass   long ago    2017-07-25                                                                 no sr2 fail
   bgp-3n-300k-ll-t    akka   2017-07-22  2017-07-25  `8318 <https://bugs.opendaylight.org/show_bug.cgi?id=8318>`__  `link <https://logs.opendaylight.org/releng/jenkins092/bgpcep-csit-3node-periodic-bgpclustering-only-carbon/351/log.html.gz#s1-s2-t10-k2-k3-k7-k2-k1-k6-k1-k1-k1-k1-k1-k2-k1-k4>`__
   bgp-3n-300k-lr-t    akka   2017-07-21  2017-07-25  `8318 <https://bugs.opendaylight.org/show_bug.cgi?id=8318>`__  `link <https://logs.opendaylight.org/releng/jenkins092/bgpcep-csit-3node-periodic-bgpclustering-only-carbon/350/log.html.gz#s1-s4-t8-k2-k3-k7-k7-k1-k6-k1-k1-k1-k1-k1-k2-k1-k2-k4>`__
   ddb-cls-ms-ll-t     pass   long ago    2017-07-25                                                                 no sr2 fail
   ddb-cls-ms-lr-t     pass   long ago    2017-07-25                                                                 no sr2 fail
   ddb-cls-ps-ll-t     pass   long ago    2017-07-25                                                                 no sr2 fail
   ddb-cls-ps-lr-t     pass   long ago    2017-07-25                                                                 no sr2 fail
   ddb-elm-ms-lr-t     pass   long ago    2017-07-25                                                                 no sr2 fail
   ddb-elm-ms-rr-t     pass   long ago    2017-07-25                                                                 no sr2 fail
   ddb-elm-ms-rl-t     pass   long ago    2017-07-25                                                                 no sr2 fail
   ddb-elm-ps-lr-t     pass   long ago    2017-07-25                                                                 no sr2 fail
   ddb-elm-ps-rr-t     pass   long ago    2017-07-25                                                                 no sr2 fail
   ddb-elm-ps-rl-t     pass   long ago    2017-07-25                                                                 no sr2 fail
   ddb-li-ms-st-t      pass   long ago    2017-07-25                                                                 no sr2 fail
   ddb-li-ms-dt-t      pass   2017-07-22  2017-07-25  `8619 <https://bugs.opendaylight.org/show_bug.cgi?id=8619>`__  'link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/790/log.html.gz#s1-s28-t3-k2-k25-k1-k8>`__
   ddb-li-ps-st-t      pass   long ago    2017-07-25                                                                 no sr2 fail
   ddb-li-ps-dt-t      tell   2017-07-25  2017-07-25  `8845 <https://bugs.opendaylight.org/show_bug.cgi?id=8845>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/793/log.html.gz#s1-s30-t3-k2-k25-k1-k8>`__
   ddb-ci-ms-ll-ct-t   pass   long ago    2017-07-25                                                                 no sr2 fail
   ddb-ci-ms-ll-st-t   pass   2017-07-25  2017-07-25  `8494 <https://bugs.opendaylight.org/show_bug.cgi?id=8494>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/792/log.html.gz#s1-s32-t3-k2-k16-k1-k1>`__
   ddb-ci-ms-lr-ct-t   pass   long ago    2017-07-25                                                                 no sr2 fail
   ddb-ci-ms-lr-st-t   pass   2017-07-25  2017-07-25  `8494 <https://bugs.opendaylight.org/show_bug.cgi?id=8494>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/792/log.html.gz#s1-s32-t7-k2-k16-k1-k1>`__
   ddb-ci-ps-ll-ct-t   pass   long ago    2017-07-25                                                                 no sr2 fail
   ddb-ci-ps-ll-st-t   pass   long ago    2017-07-25                                                                 no sr2 fail
   ddb-ci-ps-lr-ct-t   pass   long ago    2017-07-25                                                                 no sr2 fail
   ddb-ci-ps-lr-st-t   pass   long ago    2017-07-25                                                                 no sr2 fail
   ddb-ls-ms-lr-t      pass   long ago    2017-07-25                                                                 no sr2 fail
   ddb-ls-ms-rr-t      pass   long ago    2017-07-25                                                                 no sr2 fail
   ddb-ls-ms-rl-t      pass   long ago    2017-07-25                                                                 no sr2 fail
   ddb-ls-ps-lr-t      tell   2017-07-25  2017-07-25  `8733 <https://bugs.opendaylight.org/show_bug.cgi?id=8733>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/793/log.html.gz#s1-s38-t1-k2-k14-k2-k1-k4-k7-k1>`__
   ddb-ls-ps-rr-t      tell   2017-07-25  2017-07-25  `8733 <https://bugs.opendaylight.org/show_bug.cgi?id=8733>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/793/log.html.gz#s1-s38-t3-k2-k14-k2-k1-k4-k7-k1>`__
   ddb-ls-ps-rl-t      tell   2017-07-18  2017-07-25  `8733 <https://bugs.opendaylight.org/show_bug.cgi?id=8733>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/786/log.html.gz#s1-s38-t5-k2-k14-k2-k1-k4-k7-k1>`__
   drb-rpp-ms-a        pass   long ago    2017-07-25                                                                 no sr2 fail
   drb-rph-ms-a        pass   long ago    2017-07-25                                                                 no sr2 fail
   drb-app-ms-a        pass   long ago    2017-07-25                                                                 no sr2 fail
   drb-aph-ms-a        pass   long ago    2017-07-25                                                                 no sr2 fail
   dnb-1n-60k-a        pass   long ago    2017-07-25                                                                 no sr2 fail
   ss-ms-ms-a          pass   long ago    2017-07-25                                                                 no sr2 fail
   ss-ph-ms-a          few    2017-07-25  2017-07-25  `8420 <https://bugs.opendaylight.org/show_bug.cgi?id=8420>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/792/log.html.gz#s1-s12-t5-k2-k3-k1-k2>`__
   ss-cl-ms-a          pass   long ago    2017-07-25                                                                 no sr2 fail
   ss-ms-ms-t          pass   long ago    2017-07-25                                                                 no sr2 fail
   ss-ph-ms-t          few    2017-07-24  2017-07-25  `8420 <https://bugs.opendaylight.org/show_bug.cgi?id=8420>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/791/log.html.gz#s1-s42-t5-k2-k3-k1-k2>`__
   ss-cl-ms-t          pass   long ago    2017-07-25                                                                 no sr2 fail
   netconf-ba-ms-a     pass   long ago    2017-07-25                                                                 no sr2 fail
   netconf-ok-ms-a     pass   long ago    2017-07-25                                                                 no sr2 fail
   netconf-rr-ms-a     pass   long ago    2017-07-25                                                                 no sr2 fail
   bgp-3n-300k-t-long  akka   2017-07-23  2017-07-23  `8318 <https://bugs.opendaylight.org/show_bug.cgi?id=8318>`__  `link <https://logs.opendaylight.org/releng/jenkins092/bgpcep-csit-3node-bgpclustering-longevity-only-carbon/13/log.html.gz#s1-s2-t1-k10-k1-k1-k1-k1-k1-k1-k1-k1-k1-k2-k1-k3-k7-k4-k1-k6-k1-k1-k1-k1-k1-k2-k1-k1-k2-k2-k2-k1-k6-k1-k2-k1>`__
   ddb-elm-mc-t-long   few    2017-07-15  2017-07-23  `8792 <https://bugs.opendaylight.org/show_bug.cgi?id=8792>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-ddb-expl-lead-movement-longevity-only-carbon/15/log.html.gz#s1-s2-t1-k2-k1-k1-k1-k1-k1-k1-k2-k1-k1-k2-k10>`__
   drb-rpp-ms-a-long   pass   long ago    2017-07-23                                                                 no sr2 fail
   drb-rph-ms-a-long   akka   2017-07-23  2017-07-23  `8430 <https://bugs.opendaylight.org/show_bug.cgi?id=8430>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-drb-partnheal-longevity-only-carbon/20/log.html.gz#s1-t1-k3-k1-k1-k1-k1-k1-k1-k2-k1-k1-k6-k1-k1-k1-k1-k1-k1-k2-k1-k1-k1-k3-k1-k1-k1-k2-k1-k4-k7-k1>`__
   dnb-1n-60k-a-long   pass   long ago    2017-07-23                                                                 no sr2 fail
   ss-ph-ms-a-long     akka   2017-07-23  2017-07-23  `8420 <https://bugs.opendaylight.org/show_bug.cgi?id=8420>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-cs-partnheal-longevity-only-carbon/17/log.html.gz#s1-s2-t1-k3-k1-k1-k1-k1-k1-k1-k2-k1-k1-k7-k3-k1-k2>`__
   ss-cl-ms-a-long     few    2017-07-15  2017-07-23  `8858 <https://bugs.opendaylight.org/show_bug.cgi?id=8858>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-cs-chasing-leader-longevity-only-carbon/13/log.html.gz#s1-s2-t3-k3-k2-k1-k1-k2-k1-k4-k7-k1>`__
   ==================  =====  ==========  ==========  =============================================================  ==========

Description: FIXME link to page with description
