#!/bin/bash

cat > ${WORKSPACE}/dcgw-setup.sh <<EOF

    echo "DC-Gateway install procedure"
    QUAGGA_VERSION=4
    Nexus_url="https://nexus.opendaylight.org/content/repositories/thirdparty/quagga\${QUAGGA_VERSION}"
    HOST_NAME=\`hostname\`
    case \${HOST_NAME} in
    *builder*)

        echo "install rpm packages "
        sudo rm -rf /tmp/install-quagga
        sudo mkdir /tmp/install-quagga/
        cd /tmp/install-quagga/
        thirft="thrift/1.0.0.b2a4d4a.CentOS7.4.1708-0.x86_64/thrift-1.0.0.b2a4d4a.CentOS7.4.1708-0.x86_64"
        zmq="zmq/4.1.3.56b71af.CentOS7.4.1708-0.x86_64/zmq-4.1.3.56b71af.CentOS7.4.1708-0.x86_64"
        quagga="quagga/1.1.0.837f143.CentOS7.4.1708-0.x86_64/quagga-1.1.0.837f143.CentOS7.4.1708-0.x86_64"
        zrpc="zrpc/0.2.56d11ae.thriftv\${QUAGGA_VERSION}.CentOS7.4.1708-0.x86_64/zrpc-0.2.56d11ae.thriftv\${QUAGGA_VERSION}.CentOS7.4.1708-0.x86_64"
        for pkg in \${c_capn} \${thirft} \${zmq} \${quagga} \${zrpc}
        do
            sudo wget \${Nexus_url}/\${pkg}.rpm
        done
        zrpc="zrpc/0.2.56d11ae.thriftv\$QUAGGA_VERSION.CentOS7.4.1708-0.x86_64/zrpc-0.2.56d11ae.thriftv\$QUAGGA_VERSION.CentOS7.4.1708-0.x86_64"
        for pkg in \$c_capn \$thirft \$zmq \$quagga \$zrpc
          do
              sudo wget \$Nexus_url/\$pkg.rpm
          done
        sudo rpm -Uvh zrpc-0.2.56d11ae.thriftv\${QUAGGA_VERSION}.CentOS7.4.1708-0.x86_64.rpm
        ;;

    *devstack*)

        echo "Quagga is not needed on devstack nodes"
        ;;

    *)

        echo "install debian packages"
        sudo rm -rf /tmp/install-quagga
        sudo rpm -Uvh zrpc-0.2.56d11ae.thriftv\$QUAGGA_VERSION.CentOS7.4.1708-0.x86_64.rpm
       ;;

    *devstack*)
        echo "Quagga is not needed on devstack nodes"
      ;;

    *)
        echo "install debian packages "
        if [ -d "/tmp/install-quagga" ]; then
          sudo rm -rf /tmp/install-quagga
        fi
        zrpc="zrpc/0.2.56d11ae.thriftv\${QUAGGA_VERSION}.Ubuntu16.04/zrpc-0.2.56d11ae.thriftv\${QUAGGA_VERSION}.Ubuntu16.04"
        for pkg in \${c_capn} \${thirft} \${zmq} \${quagga} \${zrpc}
        do
            sudo wget \${Nexus_url}/\${pkg}.deb
        done
        zrpc="zrpc/0.2.56d11ae.thriftv\$QUAGGA_VERSION.Ubuntu16.04/zrpc-0.2.56d11ae.thriftv\$QUAGGA_VERSION.Ubuntu16.04"
        for pkg in \$c_capn \$thirft \$zmq \$quagga \$zrpc
          do
              sudo wget \$Nexus_url/\$pkg.deb
          done
        sudo lsof /var/lib/dpkg/lock
        sudo ps ax | grep dpkg
        sleep 10s
        pkill -f dpkg
        sudo rm /var/lib/dpkg/lock
        sudo dpkg --configure -a
        dpkg -i thrift-1.0.0.b2a4d4a.Ubuntu16.04.deb
        dpkg -i c-capnproto-1.0.2.75f7901.Ubuntu16.04.deb
        dpkg -i zmq-4.1.3.56b71af.Ubuntu16.04.deb
        dpkg -i quagga-1.1.0.837f143.Ubuntu16.04.deb
        dpkg -i zrpc-0.2.56d11ae.thriftv\${QUAGGA_VERSION}.Ubuntu16.04.deb
        dpkg -i zrpc-0.2.56d11ae.thriftv\$QUAGGA_VERSION.Ubuntu16.04.deb
        ;;
    esac
EOF

echo "Execute the DC-Gateway install procedure on all the ODL VMS"

for i in `seq 1 ${NUM_ODL_SYSTEM}`
do
    ODLIP=ODL_SYSTEM_${i}_IP

    echo "Copying the /tmp/dcgw-setup.sh to ODL System  IP ${!ODLIP}"
    scp ${WORKSPACE}/dcgw-setup.sh ${!ODLIP}:/tmp/
    ssh ${!ODLIP} 'sudo bash /tmp/dcgw-setup.sh'
    CONTROLLERIP=ODL_SYSTEM_${i}_IP
    echo "Copying the /tmp/dcgw-setup.sh to ODL System  IP ${!CONTROLLERIP}"
    scp ${WORKSPACE}/dcgw-setup.sh ${!CONTROLLERIP}:/tmp/
    ssh ${!CONTROLLERIP} 'sudo bash /tmp/dcgw-setup.sh'
done

echo "Execute the DC-Gateway install procedure on all the tools VMS"

for i in `seq 1 ${NUM_TOOLS_SYSTEM}`
do
    TOOLIP=TOOLS_SYSTEM_${i}_IP

    echo "Copying the /tmp/dcgw-setup.sh to Tools System IP ${!TOOLIP}"
    scp ${WORKSPACE}/dcgw-setup.sh ${!TOOLIP}:/tmp/
    ssh ${!TOOLIP} 'sudo bash /tmp/dcgw-setup.sh'
done

