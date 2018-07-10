#!/bin/bash

while true
do

  # kill node 1
  sudo docker exec -i odl_172.28.5.1 ps aux |
                                     grep karaf.main | grep -v grep |
                                     awk '{print "kill -9",$2}' |
                                     sudo docker exec -i odl_172.28.5.1 sh

  # wipe karaf logs to make it easier to look at when we hit the bug
  for i in {1..3}
  do
      docker exec -i odl_172.28.5.$i sh -c 'rm -rf /odlha/karaf/target/assembly/data/log/*'
  done

  # pick a random value between 1-90 seconds for when we start karaf again
  sleepy_time=$((RANDOM%90))
  echo "Waiting $sleepy_time seconds after killing karaf, before starting"
  sleep $sleepy_time
  sudo docker exec -i odl_172.28.5.1 /odlha/karaf/target/assembly/bin/start

  tries=0
  until [ $tries -ge 60 ]
  do
      ((tries++))
      echo "$tries th check for 200 code"
      RESP=$(curl --silent --write-out "HTTPSTATUS:%{http_code}" -u "admin:admin" http://172.28.5.1:8181/jolokia/read/org.opendaylight.controller:Category\=ShardManager,name\=shard-manager-config,type\=DistributedConfigDatastore)
      CODE=$(echo $RESP | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')

      if [ $CODE -eq "200" ] && [[ $RESP =~ "SyncStatus\":true," ]]; then
          break
      fi
      sleep 2;
  done

  # we'll have looped for 120s (60 tries) above if 200 never came, so maybe things are broken
  if [ $tries -eq 60 ]; then
      echo "Might have caught the bugger; killing all controllers with -9";
      for i in {1..3}
      do
          sudo docker exec -i odl_172.28.5.$i ps aux |
                                   grep karaf.main | grep -v grep |
                                   awk '{print "kill -9",$2}' |
                                   sudo docker exec -i odl_172.28.5.$i sh
      done
exit 1
  fi
done
