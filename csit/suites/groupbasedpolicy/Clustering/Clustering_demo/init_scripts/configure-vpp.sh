#! /bin/bash

#configure vpp
if ! grep -q "dev 0000:00:09.0 {vlan-strip-offload off}" /etc/vpp/startup.conf; then
    echo "configuring VPP..."
    sudo sed -i "\$adpdk \n{\n  dev 0000:00:09.0 {vlan-strip-offload off}\n  dev 0000:00:0a.0 {vlan-strip-offload off}\n}" "/etc/vpp/startup.conf"
    echo "configuring VPP done."
else 
    echo "WARNING: VPP startup conf was not configured..."
    exit
fi

sudo service vpp start