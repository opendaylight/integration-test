#!/bin/bash

iteration=0
while true
do

  ((iteration++))
# #########################################################################
  # forcefully kill node 1
  sudo docker exec -i odl_172.28.5.1 ps aux |
                                     grep karaf.main | grep -v grep |
                                     awk '{print "kill -9",$2}' |
                                     sudo docker exec -i odl_172.28.5.1 sh
# #####################end of forceful stopper#############################

# #########################################################################
#  # gently stop node 1
#  sudo docker exec -i odl_172.28.5.1 /odlha/karaf/target/assembly/bin/stop
#
#  tries=0
#  until [ $tries -ge 10 ]
#  do
#    sleep 2
#    ((tries++))
#    OUTPUT=$(sudo docker exec -i odl_172.28.5.1 ps aux |
#	  grep karaf.main | grep -v grep)
#    if [[ "$OUTPUT" == "" ]]; then break; fi
#  done
# ######################end of gentle stopper##############################

  # wipe karaf logs to make it easier to look at when we hit the bug
  for i in {1..3}
  do
      sudo docker exec -i odl_172.28.5.$i sh -c 'rm -rf /odlha/karaf/target/assembly/data/log/*'
      # a little clean up of /dev/shm/* since it can get filled up pretty quickly with aeron files
      sudo docker exec -i odl_172.28.5.$i sh -c "cd /dev/shm; ls -t | tail -n +2 | awk '{print \"rm -rf\",\$1}' | sh"
  done

  # pick a random value between 1-90 seconds for when we start karaf again
  sleepy_time=$((RANDOM%90))
  echo "$(date):: Waiting $sleepy_time seconds after killing karaf, before starting"
  sleep $sleepy_time
  # start a pcap on this dude
  sudo docker exec -i odl_172.28.5.1 tcpdump -ni eth0 port 2550 -w /odlha/karaf/target/assembly/$iteration.pcap &
  sudo docker exec -i odl_172.28.5.1 /odlha/karaf/target/assembly/bin/start

  tries=0
  until [ $tries -ge 60 ]
  do
      ((tries++))
      echo "$(date):: $tries th check for 200 code"
      RESP=$(curl --silent --write-out "HTTPSTATUS:%{http_code}" -u "admin:admin" http://172.28.5.1:8181/jolokia/read/org.opendaylight.controller:Category\=ShardManager,name\=shard-manager-config,type\=DistributedConfigDatastore)
      CODE=$(echo $RESP | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')

      if [ $CODE -eq "200" ] && [[ $RESP =~ "SyncStatus\":true," ]]; then
          break
      fi
      # dumping some debugs from each container
      for i in {1..3}
      do
	  echo "$(date):: Looking at netstat from $i"
          sudo docker exec -i odl_172.28.5.$i netstat -tulpn
      done
      sleep 2;
  done

  # we'll have looped for 120s (60 tries) above if 200 never came, so maybe things are broken
  if [ $tries -eq 60 ]; then
      echo "$(date):: Might have caught the bugger; killing all controllers with -9";
      echo "RESP: $RESP"
      echo "CODE: $CODE"
      for i in {1..3}
      do
          sudo docker exec -i odl_172.28.5.$i ps aux |
                                   grep karaf.main | grep -v grep |
                                   awk '{print "kill -9",$2}' |
                                   sudo docker exec -i odl_172.28.5.$i sh
      done
      # stop that packet capture on the first node
      sudo docker exec -i odl_172.28.5.1 pkill tcpdump
      # quitting here for debugging to happen
      exit 1
  fi

  # stop that packet capture on the first node, and remove them since we only care when
  # it's the failure case which is caught above
  sudo docker exec -i odl_172.28.5.1 pkill tcpdump
  sudo find . -name "*pcap" | awk '{print "rm",$1}' | sh

done
