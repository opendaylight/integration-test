
Caveats
^^^^^^^

Caveats:

+ Missing features:

 + Yang notifications are not delivered to peer members. `Bug 2139 <https://bugs.opendaylight.org/show_bug.cgi?id=2139>`__ is only fixed for data change notifications, not Yang notifications.

  + Notification suites are running on with 1-node setup only.

+ New features:

 + Tell-based protocol instead of ask-based protocol.

  + Some scenarios are expected to fail due to known limitations of ask-based protocol.

 + Prefix-based shards instead of module-based shards.
 + Producer options:

  + Used mostly chained transactions only. Standalone transactions are prone to OptimisticLockTransactions.

 + This results in multiple suites for the same scenario.

+ Reduced number of combinations:

 + Prefix-based shards always use tell-based protocol, so suites which test them with ask-based protocol configuration can be skipped.
 + Ask-based protocol is known to fail on AskTimeoutException in isolation scenarios, so suites which produce transactions constantly can be skipped.

+ Hard reboots between suites:

 + Timing errors in Robot code lead to Robot being unable to restore original state without restarts.
 + Almost 90 second per ODL reboot.

+ Isolation mechanics:

 + Used mostly iptables filtering. Freeze and kill affect the co-located java test driver.

  + Even then, AAA stops working (results in 401), so most checks on the isolated node are dropped anyway.

+ Reduced BGP scaling:

 + Rib owner maintains de-duplicated data structures. Other members get serialized copies and they do not de-duplicate.

+ Reduced Singleton performance:

 + Carbon is missing `an improvement <https://bugs.opendaylight.org/show_bug.cgi?id=7855>`__ which limits java test implementation.
 + Suite accepts 5 deregistrations per second.

+ Missing log.html:

 + Robot VM has only 2GB of RAM and longevity jobs tend to produce large output.xml files.
 + This affects mostly longevity jobs if they pass.
