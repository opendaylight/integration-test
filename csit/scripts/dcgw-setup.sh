#!/bin/bash

cat > ${WORKSPACE}/dcgw-setup.sh <<EOF

echo "DC-Gateway install procedure"
        QUAGGA_VERSION=4
        Nexus_url="https://nexus.opendaylight.org/content/repositories/thirdparty/quagga\$QUAGGA_VERSION"
        HOST_NAME=\`facter  hostname\`
        #HOST_NAME=\`hostname\`
        echo "\$HOST_NAME"
        echo "$HOST_NAME"
    case \$HOST_NAME in
    *builder*)
        if [ -d "/tmp/install-quagga" ]; then
          sudo rm -rf /tmp/install-quagga
        fi
        sudo mkdir /tmp/install-quagga/
        cd /tmp/install-quagga/
        echo "present working dir: \$pwd"
        c_capn="c-capnproto/1.0.2.75f7901.CentOS7.4.1708-0.x86_64/c-capnproto-1.0.2.75f7901.CentOS7.4.1708-0.x86_64"
        thirft="thrift/1.0.0.b2a4d4a.CentOS7.4.1708-0.x86_64/thrift-1.0.0.b2a4d4a.CentOS7.4.1708-0.x86_64"
        zmq="zmq/4.1.3.56b71af.CentOS7.4.1708-0.x86_64/zmq-4.1.3.56b71af.CentOS7.4.1708-0.x86_64"
        quagga="quagga/1.1.0.837f143.CentOS7.4.1708-0.x86_64/quagga-1.1.0.837f143.CentOS7.4.1708-0.x86_64"
        zrpc="zrpc/0.2.56d11ae.thriftv\$QUAGGA_VERSION.CentOS7.4.1708-0.x86_64/zrpc-0.2.56d11ae.thriftv\$QUAGGA_VERSION.CentOS7.4.1708-0.x86_64"
        for pkg in \$c_capn \$thirft \$zmq \$quagga \$zrpc
          do
            sudo wget \$Nexus_url/\$pkg.rpm
          done
        sudo rpm -Uvh c-capnproto-1.0.2.75f7901.CentOS7.4.1708-0.x86_64.rpm
        sudo rpm -Uvh thrift-1.0.0.b2a4d4a.CentOS7.4.1708-0.x86_64.rpm
        sudo rpm -Uvh zmq-4.1.3.56b71af.CentOS7.4.1708-0.x86_64.rpm
        sudo rpm -Uvh quagga-1.1.0.837f143.CentOS7.4.1708-0.x86_64.rpm
        sudo rpm -Uvh zrpc-0.2.56d11ae.thriftv\$QUAGGA_VERSION.CentOS7.4.1708-0.x86_64.rpm
       ;;

    *devstack*)
        echo "6wind quagga is not supported on devstack"
      ;;

    *)
        echo "install debian packages "
        # install the QBGP packages on ubuntu host
        if [ -d "/tmp/install-quagga" ]; then
          sudo rm -rf /tmp/install-quagga
        fi
        sudo mkdir -p /tmp/install-quagga/
        cd /tmp/install-quagga/
        c_capn="c-capnproto/1.0.2.75f7901.Ubuntu16.04/c-capnproto-1.0.2.75f7901.Ubuntu16.04"
        thirft="thrift/1.0.0.b2a4d4a.Ubuntu16.04/thrift-1.0.0.b2a4d4a.Ubuntu16.04"
        zmq="zmq/4.1.3.56b71af.Ubuntu16.04/zmq-4.1.3.56b71af.Ubuntu16.04"
        quagga="quagga/1.1.0.837f143.Ubuntu16.04/quagga-1.1.0.837f143.Ubuntu16.04"
        zrpc="zrpc/0.2.56d11ae.thriftv\$QUAGGA_VERSION.Ubuntu16.04/zrpc-0.2.56d11ae.thriftv\$QUAGGA_VERSION.Ubuntu16.04"
        for pkg in \$c_capn \$thirft \$zmq \$quagga \$zrpc
          do
             sudo wget \$Nexus_url/\$pkg.deb
          done
        #sudo ps ax | grep dpkg
        #sleep 5s
        #pkill -f dpkg
        sudo ps aux | grep dpkg | awk {'print $2'} | xargs kill -9
        sudo ps aux | grep apt | awk {'print $2'} | xargs kill -9
        sleep 5 
        dpkg -i thrift-1.0.0.b2a4d4a.Ubuntu16.04.deb
        dpkg -i c-capnproto-1.0.2.75f7901.Ubuntu16.04.deb
        dpkg -i zmq-4.1.3.56b71af.Ubuntu16.04.deb
        dpkg -i quagga-1.1.0.837f143.Ubuntu16.04.deb
        dpkg -i zrpc-0.2.56d11ae.thriftv\$QUAGGA_VERSION.Ubuntu16.04.deb
        ;;
    esac
EOF

echo "Execute the DC-Gateway install procedure on all the ODL VMS"

for i in `seq 1 ${NUM_ODL_SYSTEM}`
do
    CONTROLLERIP=ODL_SYSTEM_${i}_IP
    echo "Copying the /tmp/dcgw-setup.sh to ODL System  IP ${!CONTROLLERIP}"
    scp ${WORKSPACE}/dcgw-setup.sh ${!CONTROLLERIP}:/tmp/
    ssh ${!CONTROLLERIP} 'sudo bash /tmp/dcgw-setup.sh'
done

echo "Execute the DC-Gateway install procedure on all the tools VMS"

for i in `seq 1 ${NUM_TOOLS_SYSTEM}`
do
        CONTROLLERIP=TOOLS_SYSTEM_${i}_IP
        echo "Copying the /tmp/dcgw-setup.sh to Tools System IP ${!CONTROLLERIP}"
        scp ${WORKSPACE}/dcgw-setup.sh ${!CONTROLLERIP}:/tmp/
        ssh ${!CONTROLLERIP} 'sudo bash /tmp/dcgw-setup.sh'
done
