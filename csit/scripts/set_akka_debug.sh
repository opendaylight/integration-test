#!/bin/bash

cat > ${WORKSPACE}/set_akka_debug.sh <<EOF

  echo "Enable AKKA or PEKKO debug"
  # Check whether the file contains 'akka {' or 'pekko {'
if grep -q '^akka {' ${AKKACONF}; then
  echo "Detected AKKA configuration. Applying debug settings for AKKA..."
  # light debug
  sed -i -e 's/akka {/akka {\nloglevel = "DEBUG"\nactor {\ndebug {\nautoreceive = on\nlifecycle = on\nunhandled = on\nfsm = on\nevent-stream = on\n}\n}/' ${AKKACONF}
  # heavy debug
  #sed -i -e 's/akka {/akka {\nloglevel = "DEBUG"\nremote {\nlog-received-messages = on\nlog-sent-messages = on\n}\nactor {\ndebug {\nautoreceive = on\nlifecycle = on\nunhandled = on\nfsm = on\nevent-stream = on\n}\n}/' ${AKKACONF}
elif grep -q '^pekko {' ${AKKACONF}; then
  echo "Detected PEKKO configuration. Applying debug settings for PEKKO..."
  # light debug
  sed -i -e 's/pekko {/pekko {\nloglevel = "DEBUG"\nactor {\ndebug {\nautoreceive = on\nlifecycle = on\nunhandled = on\nfsm = on\nevent-stream = on\n}\n}/' ${AKKACONF}
  # heavy debug
  #sed -i -e 's/pekko {/pekko {\nloglevel = "DEBUG"\nremote {\nlog-received-messages = on\nlog-sent-messages = on\n}\nactor {\ndebug {\nautoreceive = on\nlifecycle = on\nunhandled = on\nfsm = on\nevent-stream = on\n}\n}/' ${AKKACONF}
else
  echo "Error: Neither 'akka {' nor 'pekko {' found in ${AKKACONF}. Exiting."
  exit 1
fi

  echo "Dump ${AKKACONF}"
  cat ${AKKACONF}
  echo "log4j2.logger.cluster.name=akka.cluster" >> ${LOGCONF}
  echo "log4j2.logger.cluster.level=DEBUG" >> ${LOGCONF}
  echo "log4j2.logger.remote.name=akka.remote" >> ${LOGCONF}
  echo "log4j2.logger.remote.level=DEBUG" >> ${LOGCONF}
  echo "Dump ${LOGCONF}"
  cat ${LOGCONF}

EOF

echo "Copying config files to ODL Controller folder"
for i in `seq 1 ${NUM_ODL_SYSTEM}`
do
  CONTROLLERIP=ODL_SYSTEM_${i}_IP

  echo "Set AKKA/PEKKO debug on ${!CONTROLLERIP}"
  scp ${WORKSPACE}/set_akka_debug.sh ${!CONTROLLERIP}:/tmp/
  ssh ${!CONTROLLERIP} "bash /tmp/set_akka_debug.sh"
done

