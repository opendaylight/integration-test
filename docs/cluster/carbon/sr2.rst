
Carbon SR2 test report
^^^^^^^^^^^^^^^^^^^^^^

Test Case Summary
-----------------

RelEng stability summary.

+ tba: Recent failures to be analyzed yet: 0.
+ test: Recent failures caused by wrong assumptions in test: 0.
+ akka: Recent failures related to pure UnreachableMember: 5.
+ tell: Recent failures not clearly caused by UnreachableMember: 4.
+ few: Tests passing unless low frequency failure happens: 5 (4 without duplication).
  (Low frequency means UnreachableMemeber or similar,
  related to Akka where Controller code has not real control.)
+ pass: Tests passing consistently: 39 (37 without duplication).
+ Total: 53 (50 without duplication).
+ Total minus akka: 48 (45 without duplication).
+ Total minus akka, passing always or mostly: 44 (41 without duplication).
+ Acceptance rate: 44/48=91.66% (41/45=91.11% without duplication).

Table
-----

S017 instead of 2017 means Sandbox run (includes changes not merged to stable/carbon yet).

Last fail is date of last failure not caused by infra
(or by a typo in test or by netconf/bgp failing to initialize properly).

"S 17" or "2 17" in Last run means the documented run was superseded by a newer one, but not analyzed yet.

"few" status from SR1 is not inherited (such tests are marked as "pass").
"long ago" means the last real test failue happened somewhere around SR1 release (or before that, or never).

If status is a link, it points to the latest relevant robot failure.
In that case, Bugs field gives the reason of that failure (which could been fixed since then, when status is "pass").

.. table:: Releng stability results (post SR1, pre SR2)
   :widths: 40,15,15,15,15

   ==================  ==========  ==========  =============================================================  ======
   Test case           Last fail   Last run    Bugs                                                           Status
   ==================  ==========  ==========  =============================================================  ======
   bgp-1n-300k-a       long ago    2017-08-01                                                                 pass
   bgp-1n-300k-t       long ago    2017-08-01                                                                 pass
   bgp-3n-300k-ll-t    2017-08-01  2017-08-01  `8318 <https://bugs.opendaylight.org/show_bug.cgi?id=8318>`__  `akka <https://logs.opendaylight.org/releng/jenkins092/bgpcep-csit-3node-periodic-bgpclustering-only-carbon/361/log.html.gz#s1-s2-t10-k2-k3-k7-k2-k1-k6-k1-k1-k1-k1-k1-k2-k1-k3-k2-k1>`__
   bgp-3n-300k-lr-t    2017-07-30  2017-08-01  `8318 <https://bugs.opendaylight.org/show_bug.cgi?id=8318>`__  `akka <https://logs.opendaylight.org/releng/jenkins092/bgpcep-csit-3node-periodic-bgpclustering-only-carbon/359/log.html.gz#s1-s4-t9-k2-k3-k7-k3-k1-k6-k1-k1-k1-k1-k1-k2-k1-k4>`__
   ddb-cls-ms-ll-t     long ago    2017-08-01                                                                 pass
   ddb-cls-ms-lr-t     long ago    2017-08-01                                                                 pass
   ddb-cls-ps-ll-t     long ago    2017-08-01                                                                 pass
   ddb-cls-ps-lr-t     long ago    2017-08-01                                                                 pass
   ddb-elm-ms-lr-t     long ago    2017-08-01                                                                 pass
   ddb-elm-ms-rr-t     long ago    2017-08-01                                                                 pass
   ddb-elm-ms-rl-t     long ago    2017-08-01                                                                 pass
   ddb-elm-ps-lr-t     long ago    2017-08-01                                                                 pass
   ddb-elm-ps-rr-t     long ago    2017-08-01                                                                 pass
   ddb-elm-ps-rl-t     long ago    2017-08-01                                                                 pass
   ddb-li-ms-st-t      long ago    2017-08-01                                                                 pass
   ddb-li-ms-dt-t      2017-07-22  2017-08-01  `8619 <https://bugs.opendaylight.org/show_bug.cgi?id=8619>`__  `pass <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/790/log.html.gz#s1-s28-t3-k2-k25-k1-k8>`__
   ddb-li-ps-st-t      long ago    2017-08-01                                                                 pass
   ddb-li-ps-dt-t      2017-08-01  2017-08-01  `8845 <https://bugs.opendaylight.org/show_bug.cgi?id=8845>`__  `tell <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/801/log.html.gz#s1-s30-t3-k2-k25-k1-k8>`__
   ddb-ci-ms-ll-ct-t   long ago    2017-08-01                                                                 pass
   ddb-ci-ms-ll-st-t   2017-07-25  2017-08-01  `8494 <https://bugs.opendaylight.org/show_bug.cgi?id=8494>`__  `pass <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/792/log.html.gz#s1-s32-t3-k2-k16-k1-k1>`__
   ddb-ci-ms-lr-ct-t   long ago    2017-08-01                                                                 pass
   ddb-ci-ms-lr-st-t   2017-07-25  2017-08-01  `8494 <https://bugs.opendaylight.org/show_bug.cgi?id=8494>`__  `pass <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/792/log.html.gz#s1-s32-t7-k2-k16-k1-k1>`__
   ddb-ci-ps-ll-ct-t   long ago    2017-08-01                                                                 pass
   ddb-ci-ps-ll-st-t   long ago    2017-08-01                                                                 pass
   ddb-ci-ps-lr-ct-t   long ago    2017-08-01                                                                 pass
   ddb-ci-ps-lr-st-t   2017-07-26  2017-08-01  `8898 <https://bugs.opendaylight.org/show_bug.cgi?id=8898>`__  `few <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/794/log.html.gz#s1-s34-t7-k2-k16-k1-k1>`__
   ddb-ls-ms-lr-t      long ago    2017-08-01                                                                 pass
   ddb-ls-ms-rr-t      long ago    2017-08-01                                                                 pass
   ddb-ls-ms-rl-t      long ago    2017-08-01                                                                 pass
   ddb-ls-ps-lr-t      2017-08-01  2017-08-01  `8733 <https://bugs.opendaylight.org/show_bug.cgi?id=8733>`__  `tell <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/801/log.html.gz#s1-s38-t1-k2-k14-k2-k1-k4-k7-k1>`__
   ddb-ls-ps-rr-t      2017-08-01  2017-08-01  `8733 <https://bugs.opendaylight.org/show_bug.cgi?id=8733>`__  `tell <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/801/log.html.gz#s1-s38-t3-k2-k14-k2-k1-k4-k7-k1>`__
   ddb-ls-ps-rl-t      2017-07-18  2017-08-01  `8733 <https://bugs.opendaylight.org/show_bug.cgi?id=8733>`__  `tell <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/786/log.html.gz#s1-s38-t5-k2-k14-k2-k1-k4-k7-k1>`__
   drb-rpp-ms-a        long ago    2017-08-01                                                                 pass
   drb-rph-ms-a        long ago    2017-08-01                                                                 pass
   drb-app-ms-a        long ago    2017-08-01                                                                 pass
   drb-aph-ms-a        long ago    2017-08-01                                                                 pass
   dnb-1n-60k-a        long ago    2017-08-01                                                                 pass
   ss-ms-ms-a          long ago    2017-08-01                                                                 pass
   ss-ph-ms-a          2017-07-29  2017-08-01  `8420 <https://bugs.opendaylight.org/show_bug.cgi?id=8420>`__  `few <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/798/log.html.gz#s1-s12-t5-k2-k3-k1-k2>`__
   ss-cl-ms-a          long ago    2017-08-01                                                                 pass
   ss-ms-ms-t          long ago    2017-08-01                                                                 pass
   ss-ph-ms-t          2017-07-28  2017-08-01  `8420 <https://bugs.opendaylight.org/show_bug.cgi?id=8420>`__  `few <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/797/log.html.gz#s1-s42-t5-k2-k3-k1-k2>`__
   ss-cl-ms-t          long ago    2017-08-01                                                                 pass
   netconf-ba-ms-a     long ago    2017-08-01                                                                 pass
   netconf-ok-ms-a     2017-07-26  2017-08-01  `8899 <https://bugs.opendaylight.org/show_bug.cgi?id=8899>`__  `few <https://logs.opendaylight.org/releng/jenkins092/netconf-csit-3node-clustering-only-carbon/607/log.html.gz#s1-s5-t14-k2-k1-k2-k1-k4-k1>`__
   netconf-rr-ms-a     long ago    2017-08-01                                                                 pass
   bgp-3n-300k-t-long  2017-07-23  2017-07-29  `8318 <https://bugs.opendaylight.org/show_bug.cgi?id=8318>`__  `akka <https://logs.opendaylight.org/releng/jenkins092/bgpcep-csit-3node-bgpclustering-longevity-only-carbon/14/log.html.gz#s1-s2-t1-k10-k1-k1-k1-k1-k1-k1-k1-k1-k1-k2-k1-k3-k7-k5-k1-k6-k1-k1-k1-k1-k1-k2-k1-k3-k1>`__
   ddb-elm-mc-t-long   2017-07-15  2017-07-29  `8792 <https://bugs.opendaylight.org/show_bug.cgi?id=8792>`__  `pass <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-ddb-expl-lead-movement-longevity-only-carbon/15/log.html.gz#s1-s2-t1-k2-k1-k1-k1-k1-k1-k1-k2-k1-k1-k2-k10>`__
   drb-rpp-ms-a-long   long ago    2017-07-29                                                                 pass
   drb-rph-ms-a-long   2017-07-29  2017-07-29  `8430 <https://bugs.opendaylight.org/show_bug.cgi?id=8430>`__  `akka <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-drb-partnheal-longevity-only-carbon/21/log.html.gz#s1-t1-k3-k1-k1-k1-k1-k1-k1-k1-k1-k1-k1-k1-k3-k1-k1-k1-k2-k1-k4-k7-k1>`__
   dnb-1n-60k-a-long   long ago    2017-07-29                                                                 pass
   ss-ph-ms-a-long     2017-07-29  2017-07-29  `8420 <https://bugs.opendaylight.org/show_bug.cgi?id=8420>`__  `akka <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-cs-partnheal-longevity-only-carbon/18/log.html.gz#s1-s2-t1-k3-k1-k1-k1-k1-k1-k1-k2-k1-k1-k7-k3-k1-k2>`__
   ss-cl-ms-a-long     2017-07-15  2017-07-29  `8858 <https://bugs.opendaylight.org/show_bug.cgi?id=8858>`__  `few <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-cs-chasing-leader-longevity-only-carbon/13/log.html.gz#s1-s2-t3-k3-k2-k1-k1-k2-k1-k4-k7-k1>`__
   ==================  ==========  ==========  =============================================================  ======

For descriptions of test cases, see :ref:`description page <list-testcases>`.

TODO: figure out how to create cross-document links visible after "tox -edocs" locally, without compiling at readthedocs.
