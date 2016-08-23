#!/bin/bash


cat > ${WORKSPACE}/set_sg_mode_and_restart.sh <<EOF

    /tmp/${BUNDLEFOLDER}/bin/stop
    # wait for karaf process to go away
    COUNT="0"
    while true; do
      sleep 5
      COUNT=$((${COUNT} + 5))
      ps ax | grep -v grep | grep karaf
      if [[ $? -eq 1 ]]; then
          break
      elif (($COUNT > 120)); then
          echo "karaf process did not stop after two minutes"
          exit 1
      fi
    done

    cat /tmp/${BUNDLEFOLDER}/etc/opendaylight/datastore/initial/config/netvirt-aclservice-config.xml
    sed -i s/stateful/transparent/ /tmp/${BUNDLEFOLDER}/etc/opendaylight/datastore/initial/config/netvirt-aclservice-config.xml
    cat /tmp/${BUNDLEFOLDER}/etc/opendaylight/datastore/initial/config/netvirt-aclservice-config.xml

    /tmp/${BUNDLEFOLDER}/bin/start
    echo "Waiting for controller to come up..."
    COUNT="0"
    while true; do
        RESP="$( curl --user admin:admin -sL -w "%{http_code} %{url_effective}\\n" http://localhost:8181/restconf/modules -o /dev/null )"
        echo $RESP
        if [[ $RESP == *"200"* ]]; then
            echo "Controller is UP"
            break
        elif (( $COUNT > 600 )); then
            echo "Timeout Controller DOWN"
            echo "Dumping first 500K bytes of karaf log..."
            head --bytes=500K "/tmp/${BUNDLEFOLDER}/data/log/karaf.log"
            echo "Dumping last 500K bytes of karaf log..."
            tail --bytes=500K "/tmp/${BUNDLEFOLDER}/data/log/karaf.log"
            echo "Listing all open ports on controller system"
            netstat -natu
            exit 1
        else
            COUNT=$(( $COUNT + 5 ))
            sleep 5
            echo "waiting $COUNT secs..."
        fi
    done
    
EOF

echo "Copying config files to ODL Controller folder"
for i in `seq 1 ${NUM_ODL_SYSTEM}`
do
        CONTROLLERIP=ODL_SYSTEM_${i}_IP

        echo "Setting security group mode to ${SECURITY_GROUP_MODE} on ${!CONTROLLERIP}"
        scp ${WORKSPACE}/set_sg_mode_and_restart.sh ${!CONTROLLERIP}:/tmp/
        ssh ${!CONTROLLERIP} 'bash /tmp/set_sg_mode_and_restart.sh'

done
