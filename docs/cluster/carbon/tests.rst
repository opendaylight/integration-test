
.. _list-testcases

List of test cases
^^^^^^^^^^^^^^^^^^

+ DOMDataBroker: Producers make 1000 transactions per second, except BGP which works full speed.

 + Leader stability: BGP inject benchmark (thus module shards only), 300k prefixes, 1 Python peer. Progress tracked by counting prefixes in example-ipv4-topology.

  + Ask-based protocol:

   + Single member: bgp-1n-300k-a

  + Tell-based protocol:

   + Single member: bgp-1n-300k-t

   + Three members:

    + Leaders local: bgp-3n-300k-ll-t

    + Leaders remote: bgp-3n-300k-lr-t

    + Longevity: bgp-3n-300k-t-long

 + Clean leader shutdown, tell-based protocol:

  + Module-based shards:

   + Shard leader local to producer: ddb-cls-ms-ll-t

   + Shard leader remote to producer: ddb-cls-ms-lr-t

  + Prefix-based shards:

   + Shard leader local to producer: ddb-cls-ps-ll-t

   + Shard leader remote to producer: ddb-cls-ps-lr-t

 + Explicit leader movement, tell-based protocol:

  + Module-based shards:

   + Local leader to remote: ddb-elm-ms-lr-t

   + Remote leader to other remote: ddb-elm-ms-rr-t

   + Remote leader to local: ddb-elm-ms-rl-t

   + Longevity (randomized direction): ddb-elm-mc-t-long

  + Prefix-based shards:

   + Local leader to remote: ddb-elm-ps-lr-t

   + Remote leader to other remote: ddb-elm-ps-rr-t

   + Remote leader to local: ddb-elm-ps-rl-t

 + Leader isolation (network partition only), tell-based protocol:

  + Module-based shards:

   + Heal within transaction timeout: ddb-li-ms-st-t

   + Heal after transaction timeout: ddb-li-ms-dt-t

  + Prefix-based shards:

   + Heal within transaction timeout: ddb-li-ps-st-t

   + Heal after transaction timeout: ddb-li-ps-dt-t

 + Client isolation, tell-based protocol:

  + Module-based shards:

   + Leader local:

    + Simple transactions: ddb-ci-ms-ll-st-t

    + Transaction chain: ddb-ci-ms-ll-ct-t

   + Leader remote:

    + Simple transactions: ddb-ci-ms-lr-st-t

    + Transaction chain: ddb-ci-ms-lr-ct-t

  + Prefix-based shards:

   + Leader local:

    + Isolated transactions: ddb-ci-ps-ll-st-t

    + Non-isolated transactions: ddb-ci-ps-ll-ct-t

   + Leader remote:

    + Isolated transactions: ddb-ci-ps-lr-st-t

    + Non-isolated transactions: ddb-ci-ps-lr-ct-t

 + Listener stablity, tell-based protocol:

  + Module-based shards:

   + Local to remote: ddb-ls-ms-lr-t

   + Remote to remote: ddb-ls-ms-rr-t

   + Remote to local: ddb-ls-ms-rl-t

  + Prefix-based shards:

   + Local to remote: ddb-ls-ps-lr-t

   + Remote to remote: ddb-ls-ps-rr-t

   + Remote to local: ddb-ls-ps-rl-t

+ DOMRpcBroker, ask-based protocol:

 + RPC Provider Precedence:

  + Functional: drb-rpp-ms-t

  + Longevity: drb-rpp-ms-t-long

 + RPC Provider Partition and Heal:

  + Functional: drb-rph-ms-t

  + Longevity: drb-rph-ms-t-long

 + Action Provider Precedence: drb-app-ms-a

 + Action Provider Partition and Heal: drb-aph-ms-a

+ DOMNotificationBroker: Only for 1 member, ask-based protocol.

 + No-loss rate: Publisher-subscriber pairs, 5k nps per pair.

  + Functional (5 minute tests for 1, 4 and 12 pairs): dnb-1n-60k-a

  + Longevity (12 pairs): dnb-1n-60k-a-long

+ Cluster Singleton:

 + Ask-based protocol:

  + Master Stability: ss-ms-ms-a

  + Partition and Heal:

   + Functional: ss-ph-ms-a

   + Longevity: ss-ph-ms-a-long

  + Chasing the Leader:

   + Functional: ss-cl-ms-a

   + Longevity: ss-cl-ms-a-long

 + Tell-based protocol:

  + Master Stability: ss-ms-ms-t

  + Partition and Heal: ss-ph-ms-t

  + Chasing the Leader: ss-cl-ms-t

+ Netconf system tests (ask-based protocol, module-based shards):

 + Basic access: netconf-ba-ms-a

 + Owner killed: netconf-ok-ms-a

 + Rolling restarts: netconf-rr-ms-a
