#!/bin/bash

cat > ${WORKSPACE}/dcgw_setup.sh <<EOF

echo "DC-Gateway install procedure"

#Create Build directory
    rm -rf /tmp/build_quagga

    HOST_NAME=\`hostname\`
    case \$HOST_NAME in
    *java*)
        echo "Tool system related changes"
       ;;

    *devstack*)
        echo "6wind quagga is not supported on devstack"
      ;;

    *)
         echo "Tool system related changes"
	 sudo apt-get update --force-yes
       ;;
    esac

echo "dowloading zrpcd"
    mkdir -p /tmp/build_quagga
    cd /tmp/build_quagga
    git clone https://github.com/6WIND/zrpcd.git
    cd zrpcd
    git checkout 20170418
    chmod 777 /tmp/build_quagga/zrpcd/pkgsrc/dev_compile_script.sh
    /tmp/build_quagga/zrpcd/pkgsrc/dev_compile_script.sh -d -b -t -v 2

EOF

echo "Execute the DC-Gateway install procedure on all the tools VMS"

for i in `seq 1 ${NUM_TOOLS_SYSTEM}`
do
        CONTROLLERIP=TOOLS_SYSTEM_${i}_IP
        echo "Copying the /tmp/dcgw_setup.sh to Tools System IP ${!CONTROLLERIP}"
        scp ${WORKSPACE}/dcgw_setup.sh ${!CONTROLLERIP}:/tmp/
        ssh ${!CONTROLLERIP} 'sudo bash /tmp/dcgw_setup.sh'
done

echo "Execute the DC-Gateway install procedure on all the ODL VMS"

for i in `seq 1 ${NUM_ODL_SYSTEM}`
do
    CONTROLLERIP=ODL_SYSTEM_${i}_IP
    echo "Copying the /tmp/dcgw_setup.sh to ODL System  IP ${!CONTROLLERIP}"
    scp ${WORKSPACE}/dcgw_setup.sh ${!CONTROLLERIP}:/tmp/
    ssh ${!CONTROLLERIP} 'sudo bash /tmp/dcgw_setup.sh'
done
