#!/bin/bash

cat > ${WORKSPACE}/dcgw_setup.sh <<EOF

echo "DC-Gateway install procedure"

#Create Build directory
    rm -rf /tmp/build_quagga

    HOST_NAME=\`hostname\`
    case \$HOST_NAME in
    *java*)
        echo "Tool system related changes"
        yum update
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
    cd zrpcd/
    git checkout master
    cd pkgsrc
    chmod 777 /tmp/build_quagga/zrpcd/pkgsrc/dev_compile_script.sh
    ./dev_compile_script.sh -p -d -b  -v 2
        
     HOST_NAME=\`hostname\`
    case \$HOST_NAME in
    *java*)
        echo "instll the rpms "
        cd /tmp/build_quagga
        cd zrpcd/pkgsrc
        sudo rpm -ivh thrift-1.0.0.*.rpm
        sudo rpm -ivh zmq-4.1.3.*.rpm
        sudo rpm -ivh c-capnproto-1.0.2.*.rpm
        sudo rpm -ivh quagga-1.1.0.*.rpm
        sudo rpm -ivh zrpc-0.2.*.rpm
        ;;

    *devstack*)
        echo "6wind quagga is not supported on devstack"
      ;;

    *)
         echo "install debian packages "
         cd /tmp/build_quagga
         cd zrpcd/pkgsrc
         sudo dpkg -i  thrift-1.0.0.*.deb
         sudo dpkg -i zmq-4.1.3.*.deb
         sudo dpkg -i c-capnproto-1.0.2.*.deb
         sudo dpkg -i quagga-1.1.0.*.deb
         sudo dpkg -i zrpc-0.2.*.deb
        ;;
    esac
     
EOF

echo "Execute the DC-Gateway install procedure on all the ODL VMS"

for i in `seq 1 ${NUM_ODL_SYSTEM}`
do
    CONTROLLERIP=ODL_SYSTEM_${i}_IP
    echo "Copying the /tmp/dcgw_setup.sh to ODL System  IP ${!CONTROLLERIP}"
    scp ${WORKSPACE}/dcgw_setup.sh ${!CONTROLLERIP}:/tmp/
    ssh ${!CONTROLLERIP} 'sudo bash /tmp/dcgw_setup.sh'
done

echo "Execute the DC-Gateway install procedure on all the tools VMS"

for i in `seq 1 ${NUM_TOOLS_SYSTEM}`
do
        CONTROLLERIP=TOOLS_SYSTEM_${i}_IP
        echo "Copying the /tmp/dcgw_setup.sh to Tools System IP ${!CONTROLLERIP}"
        scp ${WORKSPACE}/dcgw_setup.sh ${!CONTROLLERIP}:/tmp/
        ssh ${!CONTROLLERIP} 'sudo bash /tmp/dcgw_setup.sh'
done
