#!/bin/sh
#
# This scripts is called within a docker-compose to initialize configuration for netopeer2-server
#

set -e

CONFIG_PATH='/root/configuration-files'

import_module()
{
  local MODULE_NAME=$1

  # Replace placeholders with ENV variables
  envsubst < $CONFIG_PATH/$MODULE_NAME.xml > $MODULE_NAME.tmp
  cat $MODULE_NAME.tmp > $CONFIG_PATH/$MODULE_NAME.xml
  rm $MODULE_NAME.tmp

  # Import configuration into both datastores
  sysrepocfg --import=$CONFIG_PATH/$MODULE_NAME.xml -m $MODULE_NAME --datastore=startup
  sysrepocfg --import=$CONFIG_PATH/$MODULE_NAME.xml -m $MODULE_NAME --datastore=running

  echo "Configuration file $CONFIG_PATH/$MODULE_NAME.xml has been imported"
}

### Main script starts here ###

# Remove existing host keys and import new one
rm -f /etc/ssh/ssh_host_*
cp $CONFIG_PATH/rsa_ssh_host_rsa_key /etc/ssh/ssh_host_rsa_key
cp $CONFIG_PATH/rsa_ssh_host_rsa_key.pub /etc/ssh/ssh_host_rsa_key.pub

# These variables will replace corresponding placeholders inside configuration templates
IFS=
export NP_PRIVKEY=`cat /etc/ssh/ssh_host_rsa_key | sed -u '1d; $d'`
export NP_PUBKEY=`openssl rsa -in /etc/ssh/ssh_host_rsa_key -pubout | sed -u '1d; $d'`

# Import configuration template for selected modules
for filename in /root/configuration-file/ietf-*.xml; do
    module = $(basename $filename .xml)
    import_module "$module"
done

import_module "ietf-netconf-server";
import_module "ietf-keystore";

unset np_privkey
unset np_pubkey

echo "Netopeer2-server initial configuration completed"
exit 0
