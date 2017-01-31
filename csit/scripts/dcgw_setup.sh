#!/bin/bash

cat > ${WORKSPACE}/dcgw_setup.sh <<EOF

echo "DC-Gateway install procedure"
#Create Build directory
    rm -rf /tmp/6wind_quagga_build_dir
#    mkdir /tmp/6wind_quagga_build_dir
#    cd /tmp/6wind_quagga_build_dir

#Clean the directory if exists
#    rm -rf c-capnproto thrift zeromq4-1 quagga zrpcd
    sudo apt-get update --force-yes
    
echo "dowloading zrpcd"
    git clone https://github.com/6WIND/zrpcd.git
    cd zrpcd
    chmod -R 777 pkgsrc/dev_compile_script.sh
    case $ODL_STREAM in
    boron)
         sudo bash pkgsrc/dev_compile_script.sh -d -b -t
        ;;
    carbon)
         sudo bash pkgsrc/dev_compile_script.sh -d -b -t -v 2
        ;;
    esac
EOF

echo "Execute the DC-Gateway install procedure on all the tools VMS"

#for i in `seq 1 ${NUM_TOOLS_SYSTEM}`
#do
#        CONTROLLERIP=TOOLS_SYSTEM_${i}_IP
        CONTROLLERIP=TOOLS_SYSTEM_1_IP
        echo "Copying the /tmp/dcgw_setup.sh to Tools System IP ${!CONTROLLERIP}"
        scp ${WORKSPACE}/dcgw_setup.sh ${!CONTROLLERIP}:/tmp/
        ssh ${!CONTROLLERIP} 'sudo bash /tmp/dcgw_setup.sh'
#done

echo "Execute the DC-Gateway install procedure on all the ODL VMS"

for i in `seq 1 ${NUM_ODL_SYSTEM}`
do
    CONTROLLERIP=ODL_SYSTEM_${i}_IP
    echo "Copying the /tmp/dcgw_setup.sh to ODL System  IP ${!CONTROLLERIP}"
    scp ${WORKSPACE}/dcgw_setup.sh ${!CONTROLLERIP}:/tmp/
    ssh ${!CONTROLLERIP} 'sudo bash /tmp/dcgw_setup.sh'
done


