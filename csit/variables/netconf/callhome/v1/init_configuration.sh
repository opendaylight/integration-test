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

# Generate new SSH host-key
rm -f /etc/ssh/ssh_host_*
ssh-keygen -q -t rsa -b 2048 -N '' -f /etc/ssh/ssh_host_rsa_key

# These variables will replace corresponding placeholders inside configuration templates
IFS=
export np_privkey=`cat /etc/ssh/ssh_host_rsa_key | sed -u '1d; $d'`
export np_pubkey=`openssl rsa -in /etc/ssh/ssh_host_rsa_key -pubout | sed -u '1d; $d'`

# Import configuration template for selected modules
import_module "ietf-netconf-server";
import_module "ietf-keystore";

unset np_privkey
unset np_pubkey

echo "Netopeer2-server initial configuration completed"
exit 0
