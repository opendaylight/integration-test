#!/bin/bash

cat > ${WORKSPACE}/system-ovs-restart.sh <<EOF
sudo rm -rf /etc/openvswitch/conf.db
sudo service openvswitch-switch restart
EOF

printf "Copying and running running system-ovs-restart script on tools systems\n"
for i in `seq 2 3`
    ipvar=TOOLS_SYSTEM_${i}_IP
    ip=${!ipvar}
    scp ${WORKSPACE}/system-ovs-restart.sh ${ip}:/tmp/
    ssh ${ip} 'sudo bash /tmp/system-ovs-restart.sh'
done
