
List of test cases
^^^^^^^^^^^^^^^^^^

+ DOMDataBroker: Producers make 1000 transactions per second, except BGP which works full speed.

 + Leader stability: BGP inject benchmark (thus module shards only), 300k prefixes, 1 Python peer. Progress tracked by counting prefixes in example-ipv4-topology.

  + Ask-based protocol:

   .. _bgp-1n-300k-a:

   + Single member: bgp-1n-300k-a

  + Tell-based protocol:

   .. _bgp-1n-300k-t:

   + Single member: bgp-1n-300k-t

   + Three members:

    .. _bgp-3n-300k-ll-t:

    + Leaders local: bgp-3n-300k-ll-t

    .. _bgp-3n-300k-lr-t:

    + Leaders remote: bgp-3n-300k-lr-t

    .. _bgp-3n-300k-t-long:

    + Longevity: bgp-3n-300k-t-long

 + Clean leader shutdown, tell-based protocol:

  + Module-based shards:

   .. _ddb-cls-ms-ll-t:

   + Shard leader local to producer: ddb-cls-ms-ll-t

   .. _ddb-cls-ms-lr-t:

   + Shard leader remote to producer: ddb-cls-ms-lr-t

  + Prefix-based shards:

   .. _ddb-cls-ps-ll-t:

   + Shard leader local to producer: ddb-cls-ps-ll-t

   .. _ddb-cls-ps-lr-t:

   + Shard leader remote to producer: ddb-cls-ps-lr-t

 + Explicit leader movement, tell-based protocol:

  + Module-based shards:

   .. _ddb-elm-ms-lr-t:

   + Local leader to remote: ddb-elm-ms-lr-t

   .. _ddb-elm-ms-rr-t:

   + Remote leader to other remote: ddb-elm-ms-rr-t

   .. _ddb-elm-ms-rl-t:

   + Remote leader to local: ddb-elm-ms-rl-t

   .. _ddb-elm-mc-t-long:

   + Longevity (randomized direction): ddb-elm-mc-t-long

  + Prefix-based shards:

   .. _ddb-elm-ps-lr-t:

   + Local leader to remote: ddb-elm-ps-lr-t

   .. _ddb-elm-ps-rr-t:

   + Remote leader to other remote: ddb-elm-ps-rr-t

   .. _ddb-elm-ps-rl-t:

   + Remote leader to local: ddb-elm-ps-rl-t

 + Leader isolation (network partition only), tell-based protocol:

  + Module-based shards:

   .. _ddb-li-ms-st-t:

   + Heal within transaction timeout: ddb-li-ms-st-t

   .. _ddb-li-ms-dt-t:

   + Heal after transaction timeout: ddb-li-ms-dt-t

  + Prefix-based shards:

   .. _ddb-li-ps-st-t:

   + Heal within transaction timeout: ddb-li-ps-st-t

   .. _ddb-li-ps-dt-t:

   + Heal after transaction timeout: ddb-li-ps-dt-t

 + Client isolation, tell-based protocol:

  + Module-based shards:

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

   + Leader local:

    .. _ddb-ci-ps-ll-it-t:

    + Isolated transactions: ddb-ci-ps-ll-it-t

    .. _ddb-ci-ps-ll-nt-t:

    + Non-isolated transactions: ddb-ci-ps-ll-nt-t

   + Leader remote:

    .. _ddb-ci-ps-lr-it-t:

    + Isolated transactions: ddb-ci-ps-lr-it-t

    .. _ddb-ci-ps-lr-nt-t:

    + Non-isolated transactions: ddb-ci-ps-lr-nt-t

 + Listener stablity, tell-based protocol:

  + Module-based shards:

   .. _ddb-ls-ms-lr-t:

   + Local to remote: ddb-ls-ms-lr-t

   .. _ddb-ls-ms-rr-t:

   + Remote to remote: ddb-ls-ms-rr-t

   .. _ddb-ls-ms-rl-t:

   + Remote to local: ddb-ls-ms-rl-t

  + Prefix-based shards:

   .. _ddb-ls-ps-lr-t:

   + Local to remote: ddb-ls-ps-lr-t

   .. _ddb-ls-ps-rr-t:

   + Remote to remote: ddb-ls-ps-rr-t

   .. _ddb-ls-ps-rl-t:

   + Remote to local: ddb-ls-ps-rl-t

+ DOMRpcBroker, ask-based protocol:

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

+ DOMNotificationBroker: Only for 1 member, ask-based protocol.

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
