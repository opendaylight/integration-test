
Draft, outdated: Carbon SR1 test report
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Test Case Summary
-----------------

RelEng stability summary.

+ tba: Recent failures to be analyzed yet: 0.
+ test: Recent failures caused by wrong assumptions in test: 0.
+ akka: Recent failures related to pure UnreachableMember: 5.
+ tell: Recent failures not clearly caused by UnreachableMember: 9.
+ few: Tests passing unless low frequency failure happens: 22 (21 without duplication).
  (Low frequency means UnreachableMemeber or "Message was not delivered, dead letters encountered",
  both are related to Akka where Controller code has not real control.)
+ pass: Tests passing consistently: 17 (15 without duplication).
+ Total: 53 (50 without duplication).
+ Total minus akka: 48 (45 without duplication).
+ Total minus akka passing always or mostly: 39 (36 without duplication).
+ Acceptance rate: 39/48=81.25% (36/45=80.00% without duplication).

Table
-----

S017 instead of 2017 means Sandbox run (includes changes not merged to stable/carbon yet).

Last fail is date of last failure not caused by infra
(or by a typo in test or by netconf/bgp failing to initialize properly).

"S 17" or "2 17" in Last run means the documented run was superseded by a newer one, but not analyzed yet.

"long ago" means the last real test failue happened before around 2017-05-19, or never.

.. table:: Releng stability results (pre-SR1)
   :widths: 30,10,20,20,10,10

   ==================  =====  ==========  ==========  =============================================================  ==========
   Scenario name       Type   Last fail   Last run    Bugs                                                           Robot link
   ==================  =====  ==========  ==========  =============================================================  ==========
   bgp-1n-1m-a         pass   long ago    2017-07-14                                                                 `link <https://jenkins.opendaylight.org/releng/view/bgpcep/job/bgpcep-csit-1node-periodic-bgp-ingest-only-carbon/lastSuccessfulBuild/robot/bgpcep-bgp-ingest.txt/Singlepeer%20Prefixcount/>`__
   bgp-1n-300k-t       pass   long ago    2017-07-14                                                                 `link <https://jenkins.opendaylight.org/releng/view/bgpcep/job/bgpcep-csit-1node-periodic-bgp-ingest-only-carbon/lastSuccessfulBuild/robot/bgpcep-bgp-ingest.txt/Singlepeer%20Pc%20Shm%20300Kroutes_1/>`__
   bgp-3n-300k-ll-t    akka   2017-07-14  2017-07-14  `8318 <https://bugs.opendaylight.org/show_bug.cgi?id=8318>`__  `link <https://logs.opendaylight.org/releng/jenkins092/bgpcep-csit-3node-periodic-bgpclustering-only-carbon/343/log.html.gz#s1-s2-t8-k2-k3-k7-k5-k1-k6-k1-k1-k1-k1-k1-k2-k1-k4>`__
   bgp-3n-300k-lr-t    akka   2017-07-13  2017-07-14  `8318 <https://bugs.opendaylight.org/show_bug.cgi?id=8318>`__  `link <https://logs.opendaylight.org/releng/jenkins092/bgpcep-csit-3node-periodic-bgpclustering-only-carbon/343/log.html.gz#s1-s4-t8-k2-k3-k7-k7-k1-k6-k1-k1-k1-k1-k1-k2-k1-k2-k4>`__
   ddb-cls-ms-ll-t     few    2017-07-04  2017-07-15  `8794 <https://bugs.opendaylight.org/show_bug.cgi?id=8794>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/771/log.html.gz#s1-s20-t1-k2-k8>`__
   ddb-cls-ms-lr-t     few    2017-07-08  2017-07-15  `8618 <https://bugs.opendaylight.org/show_bug.cgi?id=8618>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/776/log.html.gz#s1-s20-t3-k2-k8>`__
   ddb-cls-ps-ll-t     few    2017-07-09  2017-07-15  `8794 <https://bugs.opendaylight.org/show_bug.cgi?id=8794>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/777/log.html.gz#s1-s22-t1-k2-k8>`__
   ddb-cls-ps-lr-t     pass   long ago    2017-07-15                                                                 `link <https://jenkins.opendaylight.org/releng/view/controller/job/controller-csit-3node-clustering-only-carbon/lastSuccessfulBuild/robot/controller-clustering.txt/Clean%20Leader%20Shutdown%20Prefbasedshard/Remote_Leader_Shutdown/>`__
   ddb-elm-ms-lr-t     few    2017-06-13  2017-07-15  `8618 <https://bugs.opendaylight.org/show_bug.cgi?id=8618>`__  `link <https://logs.opendaylight.org/sandbox/jenkins091/controller-csit-3node-clustering-only-carbon/31/log.html.gz#s1-s24-t1-k2-k10>`__
   ddb-elm-ms-rr-t     few    2017-06-10  2017-07-15  `8618 <https://bugs.opendaylight.org/show_bug.cgi?id=8618>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/738/log.html.gz#s1-s24-t3-k2-k10>`__
   ddb-elm-ms-rl-t     few    2017-06-27  2017-07-15  `8749 <https://bugs.opendaylight.org/show_bug.cgi?id=8749>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/763/log.html.gz#s1-s24-t5-k2-k10>`__
   ddb-elm-ps-lr-t     few    2017-06-11  2017-07-15  `8664 <https://bugs.opendaylight.org/show_bug.cgi?id=8664>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/736/log.html.gz#s1-s26-t1-k2-k6-k3-k1-k4-k7-k1>`__
   ddb-elm-ps-rr-t     pass   long ago    2017-07-15                                                                 `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/lastSuccessfulBuild/log.html.gz#s1-s26-t3>`__
   ddb-elm-ps-rl-t     few    2017-06-07  2017-07-15  `8403 <https://bugs.opendaylight.org/show_bug.cgi?id=8403>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/735/log.html.gz#s1-s26-t5-k2-k9>`__
   ddb-li-ms-st-t      tell   2017-07-15  2017-07-15  `8792 <https://bugs.opendaylight.org/show_bug.cgi?id=8792>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/783/log.html.gz#s1-s28-t1-k2-k25-k1-k1>`__
   ddb-li-ms-dt-t      tell   2017-07-15  2017-07-15  `8619 <https://bugs.opendaylight.org/show_bug.cgi?id=8619>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/783/log.html.gz#s1-s28-t3-k2-k25-k1-k8>`__
   ddb-li-ps-st-t      few    2017-06-08  2017-07-15  `8371 <https://bugs.opendaylight.org/show_bug.cgi?id=8371>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/736/log.html.gz#s1-s30-t1-k2-k25-k1-k1>`__
   ddb-li-ps-dt-t      tell   2017-07-15  2017-07-15  `8845 <https://bugs.opendaylight.org/show_bug.cgi?id=8845>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/783/log.html.gz#s1-s30-t3-k2-k25-k1-k8>`__
   ddb-ci-ms-ll-ct-t   few    2017-06-07  2017-07-15  `8494 <https://bugs.opendaylight.org/show_bug.cgi?id=8494>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/735/log.html.gz#s1-s32-t1-k2-k16-k1-k1>`__
   ddb-ci-ms-ll-st-t   tell   2017-07-15  2017-07-15  `8494 <https://bugs.opendaylight.org/show_bug.cgi?id=8494>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/783/log.html.gz#s1-s32-t3-k2-k16-k1-k1>`__
   ddb-ci-ms-lr-ct-t   few    2017-06-08  2017-07-15  `8636 <https://bugs.opendaylight.org/show_bug.cgi?id=8636>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/736/log.html.gz#s1-s32-t5-k2-k15-k1-k1-k1-k1-k1-k1-k2-k1-k1-k1>`__
   ddb-ci-ms-lr-st-t   tell   2017-07-15  2017-07-15  `8494 <https://bugs.opendaylight.org/show_bug.cgi?id=8494>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/783/log.html.gz#s1-s32-t7-k2-k16-k1-k1>`__
   ddb-ci-ps-ll-ct-t   few    2017-06-28  2017-07-15  `8494 <https://bugs.opendaylight.org/show_bug.cgi?id=8494>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/764/log.html.gz#s1-s34-t1-k2-k16-k1-k1>`__
   ddb-ci-ps-ll-st-t   few    2017-06-28  2017-07-15  `8494 <https://bugs.opendaylight.org/show_bug.cgi?id=8494>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/764/log.html.gz#s1-s34-t3-k2-k16-k1-k1>`__
   ddb-ci-ps-lr-ct-t   few    2017-06-28  2017-07-15  `8494 <https://bugs.opendaylight.org/show_bug.cgi?id=8494>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/764/log.html.gz#s1-s34-t5-k2-k16-k1-k1>`__
   ddb-ci-ps-lr-st-t   few    2017-06-28  2017-07-15  `8494 <https://bugs.opendaylight.org/show_bug.cgi?id=8494>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/764/log.html.gz#s1-s34-t7-k2-k16-k1-k1>`__
   ddb-ls-ms-lr-t      tell   2017-07-15  2017-07-15  `8792 <https://bugs.opendaylight.org/show_bug.cgi?id=8792>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/783/log.html.gz#s1-s36-t1-k2-k12>`__
   ddb-ls-ms-rr-t      tell   2017-07-14  2017-07-15  `8792 <https://bugs.opendaylight.org/show_bug.cgi?id=8792>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/782/log.html.gz#s1-s36-t3-k2-k12>`__
   ddb-ls-ms-rl-t      tell   2017-07-12  2017-07-15  `8792 <https://bugs.opendaylight.org/show_bug.cgi?id=8792>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/779/log.html.gz#s1-s36-t5-k2-k12>`__
   ddb-ls-ps-lr-t      pass   long ago    2017-07-15                                                                 `link <https://jenkins.opendaylight.org/releng/job/controller-csit-3node-clustering-only-carbon/lastSuccessfulBuild/robot/controller-clustering.txt/Listener%20Stability%20Prefbasedshard/Move_Leader_From_Listener_Local_To_Remote/>`__
   ddb-ls-ps-rr-t      few    2017-06-26  2017-07-15  `8733 <https://bugs.opendaylight.org/show_bug.cgi?id=8733>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/762/log.html.gz#s1-s38-t3-k2-k14-k2-k1-k4-k7-k1>`__
   ddb-ls-ps-rl-t      pass   long ago    2017-07-15                                                                 `link <https://jenkins.opendaylight.org/releng/job/controller-csit-3node-clustering-only-carbon/lastSuccessfulBuild/robot/controller-clustering.txt/Listener%20Stability%20Prefbasedshard/Move_Leader_From_Listener_Remote_To_Local/>`__
   drb-rpp-ms-a        pass   long ago    2017-07-15                                                                 `link <https://jenkins.opendaylight.org/releng/view/controller/job/controller-csit-3node-clustering-only-carbon/lastSuccessfulBuild/robot/controller-clustering.txt/Rpc%20Provider%20Precedence/>`__
   drb-rph-ms-a        few    2017-06-28  2017-07-15  `8430 <https://bugs.opendaylight.org/show_bug.cgi?id=8430>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/764/log.html.gz#s1-s4-t6-k2-k1-k1-k1-k1-k1-k1-k2-k1-k1-k1-k3-k1-k1-k1-k2-k1-k4-k7-k1>`__
   drb-app-ms-a        pass   long ago    2017-07-15                                                                 `link <https://jenkins.opendaylight.org/releng/view/controller/job/controller-csit-3node-clustering-only-carbon/lastSuccessfulBuild/robot/controller-clustering.txt/Action%20Provider%20Precedence/>`__
   drb-aph-ms-a        few    2017-07-02  2017-07-15  `8430 <https://bugs.opendaylight.org/show_bug.cgi?id=8430>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/769/log.html.gz#s1-s8-t6-k2-k1-k1-k1-k1-k1-k1-k1-k1-k1-k1-k3-k1-k1-k1-k3-k1-k4-k7-k1>`__
   dnb-1n-60k-a        pass   long ago    2017-07-15                                                                 `link <https://jenkins.opendaylight.org/releng/view/controller/job/controller-csit-1node-rest-cars-perf-only-carbon/lastSuccessfulBuild/robot/controller-rest-cars-perf.txt/Noloss%20Rate%201Node/>`__
   ss-ms-ms-a          pass   long ago    2017-07-15                                                                 `link <https://jenkins.opendaylight.org/releng/view/controller/job/controller-csit-3node-clustering-only-carbon/lastSuccessfulBuild/robot/controller-clustering.txt/Master%20Stability/>`__
   ss-ph-ms-a          few    2017-06-29  2017-07-15  `8420 <https://bugs.opendaylight.org/show_bug.cgi?id=8420>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/765/log.html.gz#s1-s12-t5-k2-k3-k1-k2>`__
   ss-cl-ms-a          pass   long ago    2017-07-15                                                                 `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/lastSuccessfulBuild/log.html.gz#s1-s14>`__
   ss-ms-ms-t          pass   long ago    2017-07-15                                                                 `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/lastSuccessfulBuild/log.html.gz#s1-s40>`__
   ss-ph-ms-t          few    2017-07-15  2017-07-15  `8420 <https://bugs.opendaylight.org/show_bug.cgi?id=8420>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/783/log.html.gz#s1-s42-t5-k2-k3-k1-k2>`__
   ss-cl-ms-t          pass   long ago    2017-07-15                                                                 `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-clustering-only-carbon/lastSuccessfulBuild/log.html.gz#s1-s44>`__
   netconf-ba-ms-a     pass   long ago    2017-07-14                                                                 `link <https://jenkins.opendaylight.org/releng/view/netconf/job/netconf-csit-3node-clustering-only-carbon/lastSuccessfulBuild/robot/netconf-clustering.txt/CRUD>`__
   netconf-ok-ms-a     few    2017-06-18  2017-07-14  `8596 <https://bugs.opendaylight.org/show_bug.cgi?id=8596>`__  `link <https://logs.opendaylight.org/releng/jenkins092/netconf-csit-3node-clustering-only-carbon/568/log.html.gz#s1-s5-t17-k2-k3-k2-k2-k1>`__
   netconf-rr-ms-a     pass   long ago    2017-07-14                                                                 `link <https://jenkins.opendaylight.org/releng/view/netconf/job/netconf-csit-3node-clustering-only-carbon/lastSuccessfulBuild/robot/netconf-clustering.txt/Outages>`__
   bgp-3n-300k-t-long  akka   2017-07-08  2017-07-08  `8318 <https://bugs.opendaylight.org/show_bug.cgi?id=8318>`__  `link <https://logs.opendaylight.org/releng/jenkins092/bgpcep-csit-3node-bgpclustering-longevity-only-carbon/11/log.html.gz#s1-s2-t1-k10-k1-k1-k1-k1-k1-k1-k1-k1-k1-k2-k1-k3-k7-k5-k1-k6-k1-k1-k1-k1-k1-k2-k1-k1-k2-k2-k2-k1-k6-k2-k2-k1>`__
   ddb-elm-mc-t-long   tell   2017-07-08  2017-07-08  `8618 <https://bugs.opendaylight.org/show_bug.cgi?id=8618>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-ddb-expl-lead-movement-longevity-only-carbon/14/log.html.gz#s1-s2-t1-k2-k1-k1-k1-k1-k1-k1-k2-k1-k1-k2-k10>`__
   drb-rpp-ms-a-long   few    2017-05-07  2017-07-08  `8430 <https://bugs.opendaylight.org/show_bug.cgi?id=8430>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-drb-partnheal-longevity-only-carbon/13/console.log.gz>`__
   drb-rph-ms-a-long   akka   2017-07-08  2017-07-08  `8430 <https://bugs.opendaylight.org/show_bug.cgi?id=8430>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-drb-partnheal-longevity-only-carbon/18/log.html.gz#s1-t1-k3-k1-k1-k1-k1-k1-k1-k2-k1-k1-k6-k1-k1-k1-k1-k1-k1-k2-k1-k1-k1-k3-k1-k1-k1-k2-k1-k4-k7-k1>`__
   dnb-1n-60k-a-long   pass   long ago    2017-07-08                                                                 `link <https://jenkins.opendaylight.org/releng/view/controller/job/controller-csit-1node-rest-cars-perf-only-carbon/620/robot/controller-rest-cars-perf.txt/Noloss%20Rate%201Node/>`__
   ss-ph-ms-a-long     akka   2017-07-08  2017-07-08  `8420 <https://bugs.opendaylight.org/show_bug.cgi?id=8420>`__  `link <https://logs.opendaylight.org/releng/jenkins092/controller-csit-3node-cs-partnheal-longevity-only-carbon/15/log.html.gz#s1-s2-t1-k3-k1-k1-k1-k1-k1-k1-k1-k1-k1-k7-k3-k1-k2>`__
   ss-cl-ms-a-long     pass   long ago    2017-07-08                                                                 `link <https://jenkins.opendaylight.org/releng/view/controller/job/controller-csit-1node-rest-cars-perf-only-carbon/620/robot/controller-rest-cars-perf.txt/Noloss%20Rate%201Node/>`__
   ==================  =====  ==========  ==========  =============================================================  ==========

For descriptions of test cases, see `description page <tests.html>`_.
Note that the link contains current description,
the details might have been implemented differently at SR1 release.
