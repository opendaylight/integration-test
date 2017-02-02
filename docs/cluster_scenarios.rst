
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

Name: 

Name: Dsbenchmark on one node.
Location: csit/suites/controller/benchmark/dsbenchmark.robot
Steps: FIXME.

Name: Restconf write performance.
Location: csit/suites/controller/ThreeNodes_Datastore/010_crud_mdsal_perf.robot
Steps: FIXME.
