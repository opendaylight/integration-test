
Permanent draft, inaccessible: Sandbox test report
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Test Case Summary
-----------------

RelEng stability summary.

+ tba: Recent failures to be analyzed yet: 0.
+ test: Recent failures caused by wrong assumptions in test: 0.
+ akka: Recent failures related to pure UnreachableMember: 5.
+ tell: Recent failures not clearly caused by UnreachableMember: 6.
+ few: Tests passing unless low frequency failure happens: 0 (0 without duplication).
  (Low frequency means UnreachableMemeber or similar,
  related to Akka where Controller code has not real control.)
+ pass: Tests passing consistently: 42 (39 without duplication).
+ Total: 53 (50 without duplication).
+ Total minus akka: 48 (45 without duplication).
+ Total minus akka passing always or mostly: 42 (39 without duplication).
+ Acceptance rate: 42/48=87.50% (39/45=86.66% without duplication).

Table
-----

S017 instead of 2017 means Sandbox run (includes changes not merged to stable/carbon yet).

Last fail is date of last failure not caused by infra
(or by a typo in test or by netconf/bgp failing to initialize properly).

"S 17" or "2 17" in Last run means the documented run was superseded by a newer one, but not analyzed yet.

"no sr2" means this test was not run on Sandbox, SR1 result is reported instead.
"few" status from SR1 is not inherited (such tests are marked as "pass").
"long ago" means the last real test failue happened somewhere before SR1 release (or never).

.. table:: Releng stability results (pre-SR1)
   :widths: 30,10,20,20,10,10

   ==================  =====  ==========  ==========  =============================================================  ==========
   Scenario name       Type   Last fail   Last run    Bugs                                                           Robot link
   ==================  =====  ==========  ==========  =============================================================  ==========
   bgp-1n-1m-a         pass   no sr2      S017-07-13                                                                 no fail this week
   bgp-1n-300k-t       pass   no sr2      S017-07-13                                                                 no fail this week
   bgp-3n-300k-ll-t    akka   S017-07-13  S017-07-13  `8318 <https://bugs.opendaylight.org/show_bug.cgi?id=8318>`__  `link <https://logs.opendaylight.org/sandbox/jenkins091/bgpcep-csit-3node-periodic-bgpclustering-only-carbon/1/log.html.gz#s1-s2-t8-k2-k3-k7-k3-k1-k6-k1-k1-k1-k1-k1-k2-k1-k2-k4>`__
   bgp-3n-300k-lr-t    akka   S017-07-13  S017-07-13  `8318 <https://bugs.opendaylight.org/show_bug.cgi?id=8318>`__  `link <https://logs.opendaylight.org/sandbox/jenkins091/bgpcep-csit-3node-periodic-bgpclustering-only-carbon/1/log.html.gz#s1-s4-t9-k2-k3-k7-k1-k1-k6-k1-k1-k1-k1-k1-k2-k1-k1-k2-k1-k2-k4>`__
   ddb-cls-ms-ll-t     pass   long ago    S017-07-13                                                                 no fail this week
   ddb-cls-ms-lr-t     pass   long ago    S017-07-13                                                                 no fail this week
   ddb-cls-ps-ll-t     pass   long ago    S017-07-13                                                                 no fail this week
   ddb-cls-ps-lr-t     pass   long ago    S017-07-13                                                                 no fail this week
   ddb-elm-ms-lr-t     pass   long ago    S017-07-13                                                                 no fail this week
   ddb-elm-ms-rr-t     pass   long ago    S017-07-13                                                                 no fail this week
   ddb-elm-ms-rl-t     pass   long ago    S017-07-13                                                                 no fail this week
   ddb-elm-ps-lr-t     pass   long ago    S017-07-13                                                                 no fail this week
   ddb-elm-ps-rr-t     pass   long ago    S017-07-13                                                                 no fail this week
   ddb-elm-ps-rl-t     pass   long ago    S017-07-13                                                                 no fail this week
   ddb-li-ms-st-t      pass   long ago    S017-07-13                                                                 no fail this week
   ddb-li-ms-dt-t      tell   S017-07-13  S017-07-13  `8619 <https://bugs.opendaylight.org/show_bug.cgi?id=8619>`__  `link <https://logs.opendaylight.org/sandbox/jenkins091/controller-csit-3node-clustering-li-only-carbon/7/log.html.gz#s1-s2-t3-k2-k25-k1-k8>`__
   ddb-li-ps-st-t      pass   long ago    S017-07-13                                                                 no fail this week
   ddb-li-ps-dt-t      tell   S017-07-13  S017-07-13  `8845 <https://bugs.opendaylight.org/show_bug.cgi?id=8845>`__  `link <https://logs.opendaylight.org/sandbox/jenkins091/controller-csit-3node-clustering-li-only-carbon/7/log.html.gz#s1-s4-t3-k2-k25-k1-k8>`__
   ddb-ci-ms-ll-ct-t   pass   long ago    S017-07-13                                                                 no fail this week
   ddb-ci-ms-ll-st-t   tell   S017-07-13  S017-07-13  `8494 <https://bugs.opendaylight.org/show_bug.cgi?id=8494>`__  `link <https://logs.opendaylight.org/sandbox/jenkins091/controller-csit-3node-clustering-ci-only-carbon/5/log.html.gz#s1-s2-t3-k2-k16-k1-k1>`__
   ddb-ci-ms-lr-ct-t   pass   long ago    S017-07-13                                                                 no fail this week
   ddb-ci-ms-lr-st-t   tell   S017-07-13  S017-07-13  `8494 <https://bugs.opendaylight.org/show_bug.cgi?id=8494>`__  `link <https://logs.opendaylight.org/sandbox/jenkins091/controller-csit-3node-clustering-ci-only-carbon/5/log.html.gz#s1-s2-t7-k2-k16-k1-k1>`__
   ddb-ci-ps-ll-ct-t   pass   long ago    S017-07-13                                                                 no fail this week
   ddb-ci-ps-ll-st-t   pass   long ago    S017-07-13                                                                 no fail this week
   ddb-ci-ps-lr-ct-t   pass   long ago    S017-07-13                                                                 no fail this week
   ddb-ci-ps-lr-st-t   pass   long ago    S017-07-13                                                                 no fail this week
   ddb-ls-ms-lr-t      pass   long ago    S017-07-13                                                                 no fail this week
   ddb-ls-ms-rr-t      pass   long ago    S017-07-13                                                                 no fail this week
   ddb-ls-ms-rl-t      pass   long ago    S017-07-13                                                                 no fail this week
   ddb-ls-ps-lr-t      tell   S017-07-11  S017-07-13  `8733 <https://bugs.opendaylight.org/show_bug.cgi?id=8733>`__  `link <https://logs.opendaylight.org/sandbox/jenkins091/controller-csit-3node-clustering-ls-only-carbon/4/log.html.gz#s1-s4-t1-k2-k14-k2-k1-k4-k7-k1>`__
   ddb-ls-ps-rr-t      tell   S017-07-13  S017-07-13  `8733 <https://bugs.opendaylight.org/show_bug.cgi?id=8733>`__  `link <https://logs.opendaylight.org/sandbox/jenkins091/controller-csit-3node-clustering-only-carbon/2/log.html.gz#s1-s38-t3-k2-k14-k2-k1-k4-k7-k1>`__
   ddb-ls-ps-rl-t      pass   long ago    S017-07-13                                                                 no fail this week
   drb-rpp-ms-a        pass   long ago    S017-07-13                                                                 no fail this week
   drb-rph-ms-a        pass   long ago    S017-07-13                                                                 no fail this week
   drb-app-ms-a        pass   long ago    S017-07-13                                                                 no fail this week
   drb-aph-ms-a        pass   long ago    S017-07-13                                                                 no fail this week
   dnb-1n-60k-a        pass   long ago    S017-07-13                                                                 no fail this week
   ss-ms-ms-a          pass   long ago    S017-07-13                                                                 no fail this week
   ss-ph-ms-a          pass   long ago    S017-07-13                                                                 no fail this week
   ss-cl-ms-a          pass   long ago    S017-07-13                                                                 no fail this week
   ss-ms-ms-t          pass   long ago    S017-07-13                                                                 no fail this week
   ss-ph-ms-t          pass   long ago    S017-07-13                                                                 no fail this week
   ss-cl-ms-t          pass   long ago    S017-07-13                                                                 no fail this week
   netconf-ba-ms-a     pass   long ago    S017-07-13                                                                 no fail this week
   netconf-ok-ms-a     pass   long ago    S017-07-13                                                                 no fail this week
   netconf-rr-ms-a     pass   long ago    S017-07-13                                                                 no fail this week
   bgp-3n-300k-t-long  akka   no sr2      no sr2      `8318 <https://bugs.opendaylight.org/show_bug.cgi?id=8318>`__  no sr2
   ddb-elm-mc-t-long   pass   long ago    S017-07-11                                                                 no fail this week
   drb-rpp-ms-a-long   pass   no sr2      no sr2                                                                     no sr2
   drb-rph-ms-a-long   akka   no sr2      no sr2      `8430 <https://bugs.opendaylight.org/show_bug.cgi?id=8430>`__  no sr2
   dnb-1n-60k-a-long   pass   no sr2      no sr2                                                                     no sr2
   ss-ph-ms-a-long     akka   no sr2      no sr2      `8420 <https://bugs.opendaylight.org/show_bug.cgi?id=8420>`__  no sr2
   ss-cl-ms-a-long     pass   no sr2      no sr2                                                                     no sr2
   ==================  =====  ==========  ==========  =============================================================  ==========

Description: FIXME link to page with description
