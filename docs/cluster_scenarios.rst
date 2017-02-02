
TODO: If this document refers to a suite, the suite should refer back to this document.

Common implicit steps: CSIT starts.
Features installed may differ, but -all- jobs have them all anyway.

Implemented:

Controller project:

Name: cluster ready.
Location: FIXME.
Steps: Wait for cluster become in sync (also query each shard separately) within timeout.

Name: CarPeople Crud.
Location: FIXME.
Steps: Locate leaders for shard/people confi shards.
Write cars to car Leader.
Read cars from all members.
Call add-person on people Follower to add people.
Read people from all members.
Call buy-car on car-people Leader to buy some cars.
Call buy-car on car-people Followers to buy the rest of cars.
Read car-people data from all members.
Delete all car-people, people, car data.

Name: Car Failover Crud.
Location: FIXME.
Steps: Locate Leader (always refers to car shard in this scenario).
Write cars to Leader. Read cars from all members.
Kill the Leader (called Old), wait for New Leader to be elected.
Read cars from live members.
Delete current cars on New Leader, write new cars to New Leader.
Read cars from live members.
Delete current cars on a Follower, write new cars to Follower.
Read cars from live members.
Start the killed member, wait for sync.
Read cars from the started member.
Delete cars on started member.



Name: Dsbenchmark on one node.
Location: csit/suites/controller/benchmark/dsbenchmark.robot
Steps: FIXME.

Name: Restconf write performance.
Location: csit/suites/controller/ThreeNodes_Datastore/010_crud_mdsal_perf.robot
Steps: FIXME.
