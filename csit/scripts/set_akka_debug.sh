#!/bin/bash

cat > ${WORKSPACE}/set_akka_debug.sh <<EOF

  echo "Enable AKKA debug"
  # light debug
  sed -i -e 's/pekko {/pekko {\nloglevel = "DEBUG"\nactor {\ndebug {\nautoreceive = on\nlifecycle = on\nunhandled = on\nfsm = on\nevent-stream = on\n}\n}/' ${PEKKOCONF}
  # heavy debug
  #sed -i -e 's/pekko {/pekko {\nloglevel = "DEBUG"\nremote {\nlog-received-messages = on\nlog-sent-messages = on\n}\nactor {\ndebug {\nautoreceive = on\nlifecycle = on\nunhandled = on\nfsm = on\nevent-stream = on\n}\n}/' ${PEKKOCONF}
  echo "Dump ${PEKKOCONF}"
  cat ${PEKKOCONF}
  echo "log4j2.logger.cluster.name=pekko.cluster" >> ${LOGCONF}
  echo "log4j2.logger.cluster.level=DEBUG" >> ${LOGCONF}
  echo "log4j2.logger.remote.name=pekko.remote" >> ${LOGCONF}
  echo "log4j2.logger.remote.level=DEBUG" >> ${LOGCONF}
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

