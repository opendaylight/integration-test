#!/bin/bash

cat > ${WORKSPACE}/cloudinit.sh <<EOF

   #cloud-config
   password=csitpass
   #chpasswd: { expire: False }
   ssh_pwauth=True

EOF
