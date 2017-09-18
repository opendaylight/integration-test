
Permanent draft, inaccessible: Sandbox test report
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Test Case Summary
-----------------

RelEng stability summary.

+ tba: Recent failures to be analyzed yet: 0.
+ test: Recent failures caused by wrong assumptions in test: 0.
+ akka: Recent failures related to pure UnreachableMember: 4.
+ tell: Recent failures not clearly caused by UnreachableMember: 6.
+ few: Tests passing unless low frequency failure happens: 2 (1 without duplication).
  (Low frequency means UnreachableMemeber or similar,
  related to Akka where Controller code has not real control.)
+ pass: Tests passing consistently: 41 (39 without duplication).
+ Total: 53 (50 without duplication).
+ Total minus akka: 49 (46 without duplication).
+ Total minus akka passing always or mostly: 43 (40 without duplication).
+ Acceptance rate: 43/49=87.75% (40/46=86.95% without duplication).

Table
-----

S017 instead of 2017 means Sandbox run (includes changes not merged to stable/carbon yet).

Last fail is date of last failure not caused by infra
(or by a typo in test or by netconf/bgp failing to initialize properly).

"S 17" or "2 17" in Last run means the documented run was superseded by a newer one, but not analyzed yet.

"no sr3" means this test was not run on Sandbox, SR2 result is reported instead.
"few" status from SR2 is not inherited (such tests are marked as "pass").
"long ago" means the last real test failue happened somewhere before SR2 release (or never).

TODO: Copy formatting from sr2 page.

.. table:: Releng stability results (pre-SR2)
   :widths: 30,10,20,20,10,10

   ==================  =====  ==========  ==========  =============================================================  ==========
   Scenario name       Type   Last fail   Last run    Bugs                                                           Robot link
   ==================  =====  ==========  ==========  =============================================================  ==========
   bgp-1n-1m-a         pass   no sr3      no sr3                                                                     no sr3
   bgp-1n-300k-t       pass   no sr3      no sr3                                                                     no sr3
   bgp-3n-300k-ll-t    akka   no sr3      no sr3      `8318 <https://bugs.opendaylight.org/show_bug.cgi?id=8318>`__  no sr3
   bgp-3n-300k-lr-t    akka   no sr3      no sr3      `8318 <https://bugs.opendaylight.org/show_bug.cgi?id=8318>`__  no sr3
   ddb-cls-ms-ll-t     pass   long ago    S017-08-24                                                                 no fail this week
   ddb-cls-ms-lr-t     pass   long ago    S017-08-24                                                                 no fail this week
   ddb-cls-ps-ll-t     pass   long ago    S017-08-24                                                                 no fail this week
   ddb-cls-ps-lr-t     pass   long ago    S017-08-24                                                                 no fail this week
   ddb-elm-ms-lr-t     pass   long ago    S017-08-24                                                                 no fail this week
   ddb-elm-ms-rr-t     pass   long ago    S017-08-24                                                                 no fail this week
   ddb-elm-ms-rl-t     pass   long ago    S017-08-24                                                                 no fail this week
   ddb-elm-ps-lr-t     pass   long ago    S017-08-24                                                                 no fail this week
   ddb-elm-ps-rr-t     pass   long ago    S017-08-24                                                                 no fail this week
   ddb-elm-ps-rl-t     pass   long ago    S017-08-24                                                                 no fail this week
   ddb-li-ms-st-t      pass   long ago    S017-08-24                                                                 no fail this week
   ddb-li-ms-dt-t      pass   long ago    S017-08-24                                                                 no fail this week
   ddb-li-ps-st-t      pass   long ago    S017-08-24                                                                 no fail this week
   ddb-li-ps-dt-t      tell   S017-08-24  S017-08-24  `8845 <https://bugs.opendaylight.org/show_bug.cgi?id=8845>`__  `link <https://logs.opendaylight.org/sandbox/jenkins091/controller-csit-3node-clustering-only-carbon/2/log.html.gz#s1-s30-t3-k2-k25-k1-k8>`__
   ddb-ci-ms-ll-ct-t   pass   long ago    S017-08-24                                                                 no fail this week
   ddb-ci-ms-ll-st-t   pass   long ago    S017-08-24                                                                 no fail this week
   ddb-ci-ms-lr-ct-t   pass   long ago    S017-08-24                                                                 no fail this week
   ddb-ci-ms-lr-st-t   pass   long ago    S017-08-24                                                                 no fail this week
   ddb-ci-ps-ll-ct-t   pass   long ago    S017-08-24                                                                 no fail this week
   ddb-ci-ps-ll-st-t   pass   long ago    S017-08-24                                                                 no fail this week
   ddb-ci-ps-lr-ct-t   pass   long ago    S017-08-24                                                                 no fail this week
   ddb-ci-ps-lr-st-t   pass   long ago    S017-08-24                                                                 no fail this week
   ddb-ls-ms-lr-t      pass   long ago    S017-08-24                                                                 no fail this week
   ddb-ls-ms-rr-t      pass   long ago    S017-08-24                                                                 no fail this week
   ddb-ls-ms-rl-t      pass   long ago    S017-08-24                                                                 no fail this week
   ddb-ls-ps-lr-t      tell   S017-08-24  S017-08-24  `8733 <https://bugs.opendaylight.org/show_bug.cgi?id=8733>`__  `link <https://logs.opendaylight.org/sandbox/jenkins091/controller-csit-3node-clustering-only-carbon/2/log.html.gz#s1-s38-t1-k2-k14-k2-k1-k4-k7-k1>`__
   ddb-ls-ps-rr-t      tell   S017-08-24  S017-08-24  `8733 <https://bugs.opendaylight.org/show_bug.cgi?id=8733>`__  `link <https://logs.opendaylight.org/sandbox/jenkins091/controller-csit-3node-clustering-only-carbon/2/log.html.gz#s1-s38-t3-k2-k14-k2-k1-k4-k7-k1>`__
   ddb-ls-ps-rl-t      pass   long ago    S017-08-24                                                                 no fail this week
   drb-rpp-ms-a        pass   long ago    S017-08-24                                                                 no fail this week
   drb-rph-ms-a        pass   long ago    S017-08-24                                                                 no fail this week
   drb-app-ms-a        pass   long ago    S017-08-24                                                                 no fail this week
   drb-aph-ms-a        pass   long ago    S017-08-24                                                                 no fail this week
   dnb-1n-60k-a        pass   no sr3      no sr3                                                                     no sr3
   ss-ms-ms-a          pass   long ago    S017-08-24                                                                 no fail this week
   ss-ph-ms-a          few    S017-08-24  S017-08-24  `8420 <https://bugs.opendaylight.org/show_bug.cgi?id=8420>`__  `link <https://logs.opendaylight.org/sandbox/jenkins091/controller-csit-3node-clustering-only-carbon/2/log.html.gz#s1-s10-t5-k2-k1-k1-k4>`__
   ss-cl-ms-a          pass   long ago    S017-08-24                                                                 no fail this week
   ss-ms-ms-t          pass   long ago    S017-08-24                                                                 no fail this week
   ss-ph-ms-t          few    S017-08-24  S017-08-24  `8420 <https://bugs.opendaylight.org/show_bug.cgi?id=8420>`__  `link <https://logs.opendaylight.org/sandbox/jenkins091/controller-csit-3node-clustering-only-carbon/2/log.html.gz#s1-s40-t5-k2-k1-k1-k4>`__
   ss-cl-ms-t          pass   long ago    S017-08-24                                                                 no fail this week
   netconf-ba-ms-a     pass   no sr3      no sr3                                                                     no fail this week
   netconf-ok-ms-a     tell   no sr3      no sr3      `9027 <https://bugs.opendaylight.org/show_bug.cgi?id=9027>`__  no fail this week
   netconf-rr-ms-a     tell   no sr3      no sr3      `9027 <https://bugs.opendaylight.org/show_bug.cgi?id=9027>`__  no fail this week
   bgp-3n-300k-t-long  akka   no sr3      no sr3      `8318 <https://bugs.opendaylight.org/show_bug.cgi?id=8318>`__  no sr3
   ddb-elm-mc-t-long   pass   no sr3      no sr3                                                                     no sr3
   drb-rpp-ms-a-long   pass   no sr3      no sr3                                                                     no sr3
   drb-rph-ms-a-long   pass   no sr3      no sr3      `8430 <https://bugs.opendaylight.org/show_bug.cgi?id=8430>`__  no sr3
   dnb-1n-60k-a-long   pass   no sr3      no sr3                                                                     no sr3
   ss-ph-ms-a-long     akka   no sr3      no sr3      `8420 <https://bugs.opendaylight.org/show_bug.cgi?id=8420>`__  no sr3
   ss-cl-ms-a-long     tell   S017-08-23  S017-08-23  `9054 <https://bugs.opendaylight.org/show_bug.cgi?id=9054>`__  `link <https://logs.opendaylight.org/sandbox/jenkins091/controller-csit-3node-cs-chasing-leader-longevity-only-carbon/14/log.html.gz#s1-s2-t3-k3-k2-k1-k1-k2-k1-k4-k6-k1>`__
   ==================  =====  ==========  ==========  =============================================================  ==========

For descriptions of test cases, see `description page <tests.html>`_.
Note that the link contains current description,
the details might have been implemented differently at SR1 release.
