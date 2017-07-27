=======
Caveats
=======

This sub-page describes ways the test implementation differs from the original specification and why.

+ Missing features:

 + Yang notifications are not delivered to peer members.
   `Bug 2139 <https://bugs.opendaylight.org/show_bug.cgi?id=2139>`__
    is only fixed for data change notifications, not Yang notifications.

  + Notification suites are running on with 1-node setup only.

+ New features:

 + Tell-based protocol as an alternative to Boron ask-based protocol.

  + Some scenarios are expected to fail due to known limitations of ask-based protocol.

 + Prefix-based shards as an alternative to Boron module-based shards.
 + Producer options:

  + Mostly chained transactions only are used.
    Prefix-based shards do not even support "non-chained" transactions.

 + All of this results in multiple test cases for the same scenario case.

+ Reduced number of combinations:

 + Prefix-based shards always use tell-based protocol, so suites which test them with ask-based protocol configuration can be skipped.
 + Ask-based protocol is known to fail on AskTimeoutException in isolation scenarios, so suites which produce transactions constantly can be skipped.

+ Hard reboots between suites:

 + Timing errors in Robot code leads to Robot being unable to restore original state without restarts.
 + Almost 90 second per ODL reboot.

+ Isolation mechanics:

 + Only iptables filtering is used. Freeze and kill affect the co-located java test driver.

  + Even then, AAA stops working (results in 401), so most checks on the isolated node are dropped anyway.

+ Reduced BGP scaling (from 1 million prefixes to 300 thousand):

 + Rib owner maintains de-duplicated data structures. Other members get serialized copies and they do not de-duplicate.
 + Even single node strugless to fit into 6GB heap with tell-based protocol,
   see `Bug 8649 <https://bugs.opendaylight.org/show_bug.cgi?id=8649>`__.

+ Reduced Singleton performance:

 + Carbon is missing `an improvement <https://bugs.opendaylight.org/show_bug.cgi?id=7855>`__
   which limits java test implementation.
 + Suite accepts 5 deregistrations per second.

+ Increased timeouts:

 + With tell-based protocol, Http requests may stay open up to 120 seconds before returning an error.
 + Even shard state reads using Jolokia can take long if the shard actor is busy processing other messages.

+ Missing log.html:

 + Robot VM has only 2GB of RAM and longevity jobs tend to produce large output.xml files.
 + This affects mostly longevity jobs (and runs with verbose logging) if they pass.
