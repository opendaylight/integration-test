#!/bin/bash
#Expected input parameter: long/short/a number
#If inputed disabled then harvesting of JVM metrics will be disabled.
short=5000
long=120000
default=$short

if [ -z "$1" ]
  then
    echo "No argument supplied. Expected: long/short/disabled/number from 5000 to 120000"
    exit 1
fi

case $1 in
short)
  period=$short
  ;;
long)
  period=$long
  ;;
disabled)
  exit
  ;;
*)
  if [[ "$1" =~ ^[0-9]+$ ]] && [ "$1" -ge $short -a "$1" -le $long ]; then
      period=$1
  else
      period=$default
  fi
  ;;
esac

cat > ${WORKSPACE}/org.apache.karaf.decanter.scheduler.simple.cfg <<EOF
period=$period

EOF

echo "Copying config files to ODL Controller folder"

for i in `seq 1 ${NUM_ODL_SYSTEM}`
do
        CONTROLLERIP=ODL_SYSTEM_${i}_IP
        echo "Setup long duration config to ${!CONTROLLERIP}"
        ssh ${!CONTROLLERIP} "mkdir -p /tmp/${BUNDLEFOLDER}/etc/opendaylight/karaf/"
        scp ${WORKSPACE}/org.apache.karaf.decanter.scheduler.simple.cfg ${!CONTROLLERIP}:/tmp/${BUNDLEFOLDER}/etc/
done
