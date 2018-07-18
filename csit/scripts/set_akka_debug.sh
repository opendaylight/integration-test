#!/bin/bash

cat > ${WORKSPACE}/set_akka_debug.sh <<EOF

  echo "Enable AKKA debug"
  sed -i -e 's/akka {/akka {\nloglevel = "DEBUG"\nactor {\ndebug {\nautoreceive = on\nlifecycle = on\nunhandled = on\nfsm = on\nevent-stream = on\n}\n}/' ${AKKACONF}
  sed -i -e 's/cluster {/cluster {\nseed-node-timeout = 30s\n/' ${AKKACONF}
  sed -i -e 's/remote {/remote {\transport-failure-detector {\nheartbeat-interval = 4 s\nacceptable-heartbeat-pause = 16s\n}/' ${AKKACONF}
  echo "Dump ${AKKACONF}"
  cat ${AKKACONF}
  echo "log4j.logger.akka.remote=DEBUG" >> ${LOGCONF}
  echo "Dump ${LOGCONF}"
  cat ${LOGCONF}

EOF

echo "Copying config files to ODL Controller folder"
for i in `seq 1 ${NUM_ODL_SYSTEM}`
do
  CONTROLLERIP=ODL_SYSTEM_${i}_IP

  echo "Set AKKA debug on ${!CONTROLLERIP}"
  scp ${WORKSPACE}/set_akka_debug.sh ${!CONTROLLERIP}:/tmp/
  ssh ${!CONTROLLERIP} "bash /tmp/set_akka_debug.sh"
done

