#!/bin/bash

cat > ${WORKSPACE}/dcgw-setup.sh <<EOF

    echo "DC-Gateway install procedure"
    Nexus_url="https://nexus.opendaylight.org/content/repositories/thirdparty/quagga4"
    HOST_NAME=\`hostname\`
    case \${HOST_NAME} in
    *builder*|*docker*)

        echo "install telnet"
        sudo yum install telnet telnet-server -y
        echo "install rpm packages"
        sudo rm -rf /tmp/install-quagga
        sudo mkdir /tmp/install-quagga/
        cd /tmp/install-quagga/
        c_capn="c-capnproto/1.0.2.75f7901.CentOS7.4.1708-0.x86_64/c-capnproto-1.0.2.75f7901.CentOS7.4.1708-0.x86_64"
        thirft="thrift/1.0.0.b2a4d4a.CentOS7.4.1708-0.x86_64/thrift-1.0.0.b2a4d4a.CentOS7.4.1708-0.x86_64"
        zmq="zmq/4.1.3.56b71af.CentOS7.4.1708-0.x86_64/zmq-4.1.3.56b71af.CentOS7.4.1708-0.x86_64"
        quagga="quagga/1.1.0.837f143.CentOS7.4.1708-0.x86_64/quagga-1.1.0.837f143.CentOS7.4.1708-0.x86_64"
        zrpc="zrpc/0.2.56d11ae.thriftv4.CentOS7.4.1708-0.x86_64/zrpc-0.2.56d11ae.thriftv4.CentOS7.4.1708-0.x86_64"
        for pkg in \${c_capn} \${thirft} \${zmq} \${quagga} \${zrpc}
        do
            sudo wget \${Nexus_url}/\${pkg}.rpm
        done
        sudo rpm -Uvh c-capnproto-1.0.2.75f7901.CentOS7.4.1708-0.x86_64.rpm
        sudo rpm -Uvh thrift-1.0.0.b2a4d4a.CentOS7.4.1708-0.x86_64.rpm
        sudo rpm -Uvh zmq-4.1.3.56b71af.CentOS7.4.1708-0.x86_64.rpm
        sudo rpm -Uvh quagga-1.1.0.837f143.CentOS7.4.1708-0.x86_64.rpm
        sudo rpm -Uvh zrpc-0.2.56d11ae.thriftv4.CentOS7.4.1708-0.x86_64.rpm
        ;;

    *)

        echo "Quagga is not needed on devstack and mininet nodes"
        ;;
    esac
EOF

if [[ ${NUM_TOOLS_SYSTEM} -ne 0 && ${ODL_ENABLE_L3_FWD} == "yes" ]]; then
    for i in `seq 1 ${NUM_ODL_SYSTEM}`
    do
        ODLIP=ODL_SYSTEM_${i}_IP

        echo "Execute the DC-Gateway install procedure on all the ODL VMS"
        echo "Copying and running the /tmp/dcgw-setup.sh to ODL System  IP ${!ODLIP}"
        scp ${WORKSPACE}/dcgw-setup.sh ${!ODLIP}:/tmp/
        ssh ${!ODLIP} 'sudo bash /tmp/dcgw-setup.sh'
    done

    for i in `seq 1 ${NUM_TOOLS_SYSTEM}`
    do
        TOOLIP=TOOLS_SYSTEM_${i}_IP

        echo "Execute the DC-Gateway install procedure on all the tools VMS"
        echo "Copying and running the /tmp/dcgw-setup.sh to Tools System IP ${!TOOLIP}"
        scp ${WORKSPACE}/dcgw-setup.sh ${!TOOLIP}:/tmp/
        ssh ${!TOOLIP} 'sudo bash /tmp/dcgw-setup.sh'
    done
else

    echo "Quagga installation is not required in any of nodes"
fi
