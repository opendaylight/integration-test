
List of test cases
^^^^^^^^^^^^^^^^^^

Each test case has a shorter code, tables with results use that code.
In result tables, the code is a link to this document,
due to coala ReST requirements, the codes are (self-pointing) links also in this document.

Other links point to scenario definitions ao caveat items.

+ `DOMDataBroker`_: Producers make 1000 transactions per second, except BGP which works full speed.

 + `Leader stability`_: BGP inject benchmark (thus module shards only), `300k prefixes`_, 1 Python peer. Progress tracked by counting prefixes in example-ipv4-topology.

  + Ask-based protocol:

   .. _bgp-1n-300k-a:

   + Single member: bgp-1n-300k-a_

  + `Tell-based protocol`_:

   .. _bgp-1n-300k-t:

   + Single member: bgp-1n-300k-t_

   + Three members:

    .. _bgp-3n-300k-ll-t:

    + Leaders local: bgp-3n-300k-ll-t_

    .. _bgp-3n-300k-lr-t:

    + `Leaders remote`_: bgp-3n-300k-lr-t_

    .. _bgp-3n-300k-t-long:

    + `Longevity`_: bgp-3n-300k-t-long_

 + `Clean leader shutdown`_, `Tell-based protocol`_:

  + Module-based shards:

   .. _ddb-cls-ms-ll-t:

   + Shard leader local to producer: ddb-cls-ms-ll-t_

   .. _ddb-cls-ms-lr-t:

   + Shard leader remote to producer: ddb-cls-ms-lr-t_

  + `Prefix-based shards`_:

   .. _ddb-cls-ps-ll-t:

   + Shard leader local to producer: ddb-cls-ps-ll-t_

   .. _ddb-cls-ps-lr-t:

   + Shard leader remote to producer: ddb-cls-ps-lr-t_

 + `Explicit leader movement`_, `Tell-based protocol`_:

  + Module-based shards:

   .. _ddb-elm-ms-lr-t:

   + Local leader to remote: ddb-elm-ms-lr-t_

   .. _ddb-elm-ms-rr-t:

   + Remote leader to other remote: ddb-elm-ms-rr-t_

   .. _ddb-elm-ms-rl-t:

   + Remote leader to local: ddb-elm-ms-rl-t_

   .. _ddb-elm-mc-t-long:

   + Longevity (randomized direction): ddb-elm-mc-t-long_

  + `Prefix-based shards`_:

   .. _ddb-elm-ps-lr-t:

   + Local leader to remote: ddb-elm-ps-lr-t_

   .. _ddb-elm-ps-rr-t:

   + Remote leader to other remote: ddb-elm-ps-rr-t_

   .. _ddb-elm-ps-rl-t:

   + Remote leader to local: ddb-elm-ps-rl-t_

 + `Leader isolation`_ (`network partition only`_), `Tell-based protocol`_:

  + Module-based shards:

   .. _ddb-li-ms-st-t:

   + Heal within transaction timeout: ddb-li-ms-st-t_

   .. _ddb-li-ms-dt-t:

   + Heal after transaction timeout: ddb-li-ms-dt-t_

  + `Prefix-based shards`_:

   .. _ddb-li-ps-st-t:

   + Heal within transaction timeout: ddb-li-ps-st-t_

   .. _ddb-li-ps-dt-t:

   + Heal after transaction timeout: ddb-li-ps-dt-t_

 + `Client isolation`_, `Tell-based protocol`_:

  + Module-based shards:

   + Leader local:

    .. _ddb-ci-ms-ll-st-t:

    + `Simple transactions`_: ddb-ci-ms-ll-st-t_

    .. _ddb-ci-ms-ll-ct-t:

    + Transaction chain: ddb-ci-ms-ll-ct-t_

   + Leader remote:

    .. _ddb-ci-ms-lr-st-t:

    + Simple transactions: ddb-ci-ms-lr-st-t_

    .. _ddb-ci-ms-lr-ct-t:

    + Transaction chain: ddb-ci-ms-lr-ct-t_

  + `Prefix-based shards`_:

   + Leader local:

    .. _ddb-ci-ps-ll-it-t:

    + Isolated transactions: ddb-ci-ps-ll-it-t_

    .. _ddb-ci-ps-ll-nt-t:

    + Non-isolated transactions: ddb-ci-ps-ll-nt-t_

   + Leader remote:

    .. _ddb-ci-ps-lr-it-t:

    + Isolated transactions: ddb-ci-ps-lr-it-t_

    .. _ddb-ci-ps-lr-nt-t:

    + Non-isolated transactions: ddb-ci-ps-lr-nt-t_

 + `Listener stablity`_, `Tell-based protocol`_:

  + Module-based shards:

   .. _ddb-ls-ms-lr-t:

   + Local to remote: ddb-ls-ms-lr-t_

   .. _ddb-ls-ms-rr-t:

   + Remote to remote: ddb-ls-ms-rr-t_

   .. _ddb-ls-ms-rl-t:

   + Remote to local: ddb-ls-ms-rl-t_

  + `Prefix-based shards`_:

   .. _ddb-ls-ps-lr-t:

   + Local to remote: ddb-ls-ps-lr-t_

   .. _ddb-ls-ps-rr-t:

   + Remote to remote: ddb-ls-ps-rr-t_

   .. _ddb-ls-ps-rl-t:

   + Remote to local: ddb-ls-ps-rl-t_

+ `DOMRpcBroker`_, ask-based protocol:

 + `RPC Provider Precedence`_:

  .. _drb-rpp-ms-a:

  + Functional: drb-rpp-ms-a_

  .. _drb-rpp-ms-a-long:

  + Longevity: drb-rpp-ms-a-long_

 + `RPC Provider Partition and Heal`_:

  .. _drb-rph-ms-a:

  + Functional: drb-rph-ms-a_

  .. _drb-rph-ms-a-long:

  + Longevity: drb-rph-ms-a-long_

 .. _drb-app-ms-a:

 + `Action Provider Precedence`_: drb-app-ms-a_

 .. _drb-aph-ms-a:

 + `Action Provider Partition and Heal`_: drb-aph-ms-a_

+ `DOMNotificationBroker`_: Only for 1 member, ask-based protocol.

 + `No-loss rate`_: Publisher-subscriber pairs, 5k nps per pair.

  .. _dnb-1n-60k-a:

  + Functional (5 minute tests for 1, 4 and 12 pairs): dnb-1n-60k-a_

  .. _dnb-1n-60k-a-long:

  + Longevity (12 pairs): dnb-1n-60k-a-long_

+ `Cluster Singleton`_:

 + Ask-based protocol:

  .. _ss-ms-ms-a:

  + `Master Stability`_: ss-ms-ms-a_

  + `Partition and Heal`_:

   .. _ss-ph-ms-a:

   + Functional: ss-ph-ms-a_

   .. _ss-ph-ms-a-long:

   + Longevity: ss-ph-ms-a-long_

  + `Chasing the Leader`_:

   .. _ss-cl-ms-a:

   + Functional: ss-cl-ms-a_

   .. _ss-cl-ms-a-long:

   + Longevity: ss-cl-ms-a-long_

 + `Tell-based protocol`_:

  .. _ss-ms-ms-t:

  + `Master Stability`_: ss-ms-ms-t_

  .. _ss-ph-ms-t:

  + `Partition and Heal`_: ss-ph-ms-t_

  .. _ss-cl-ms-t:

  + `Chasing the Leader`_: ss-cl-ms-t_

+ `Netconf system tests`_ (ask-based protocol, module-based shards):

 .. _netconf-ba-ms-a:

 + `Basic access`_: netconf-ba-ms-a_

 .. _netconf-ok-ms-a:

 + `Owner killed`_: netconf-ok-ms-a_

 .. _netconf-rr-ms-a:

 + `Rolling restarts`_: netconf-rr-ms-a_

.. _`300k prefixes`: caveats.html#reduced-bgp-scaling
.. _`Action Provider Partition and Heal`: scenarios.html#action-provider-partition-and-heal
.. _`Action Provider Precedence`: scenarios.html#action-provider-precedence
.. _`Basic access`: scenarios.html#basic-configuration-and-mount-point-access
.. _`Chasing the Leader`: scenarios.html#chasing-the-leader
.. _`Clean leader shutdown`: scenarios.html#clean-leader-shutdown
.. _`Client isolation`: scenarios.html#client-isolation
.. _`Cluster Singleton`: scenarios.html#cluster-singleton
.. _`DOMDataBroker`: scenarios.html#domdatabroker
.. _`DOMNotificationBroker`: scenarios.html#domnotificationbroker
.. _`DOMRpcBroker`: scenarios.html#domrpcbroker
.. _`Explicit leader movement`: scenarios.html#explicit-leader-movement
.. _`Leader isolation`: scenarios.html#leader-isolation
.. _`Leader stability`: scenarios.html#leader-stability
.. _`Leaders remote`: caveats.html#initial-leader-placement
.. _`Listener stablity`: scenarios.html#listener-isolation
.. _`Longevity`: scenarios.html#controller-cluster-services-longevity-tests
.. _`Master Stability`: scenarios.html#master-stability
.. _`Netconf system tests`: scenarios.html#netconf-system-tests
.. _`network partition only`: caveats.html#isolation-mechanics
.. _`No-loss rate`: scenarios.html#no-loss-rate
.. _`Owner killed`: scenarios.html#device-owner-killed
.. _`Partition and Heal`: scenarios.html#partition-and-heal
.. _`Prefix-based shards`: caveats.html#prefix-based-shards
.. _`Rolling restarts`: scenarios.html#rolling-restarts
.. _`RPC Provider Partition and Heal`: scenarios.html#rpc-provider-partition-and-heal
.. _`RPC Provider Precedence`: scenarios.html#rpc-provider-precedence
.. _`Simple transactions`: caveats.html#producer-options
.. _`Tell-based protocol`: caveats.html#tell-based-protocol
