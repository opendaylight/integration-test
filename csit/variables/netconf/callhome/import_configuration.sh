#!/bin/sh
#
# This scripts is called within a docker-compose to import configuration files for netopeer2-server
#

set -e

CONFIG_PATH='/root/configuration-files'

usage()
{
  echo "Usage: $0 [--profile default | call-home-ssh | call-home-tls ]"
  exit 2
}

import_module()
{
  local MODULE_NAME=$1

  # Replace placeholders with ENV variables
  envsubst < $CONFIG_PATH/$PROFILE/$MODULE_NAME.xml > $MODULE_NAME.tmp 
  cat $MODULE_NAME.tmp > $CONFIG_PATH/$PROFILE/$MODULE_NAME.xml
  rm $MODULE_NAME.tmp
 
  # Import configuration into both datastores
  sysrepocfg --import=$CONFIG_PATH/$PROFILE/$MODULE_NAME.xml -m $MODULE_NAME --datastore=startup
  sysrepocfg --import=$CONFIG_PATH/$PROFILE/$MODULE_NAME.xml -m $MODULE_NAME --datastore=running
  
  echo "Configuration file $CONFIG_PATH/$PROFILE/$MODULE_NAME.xml for module $MODULE_NAME has been imported"
}

process_placeholders() {
  local MODULE_NAME=$1
  
  envsubst < $CONFIG_PATH/$PROFILE/$MODULE_NAME.xml | tee $CONFIG_PATH/$PROFILE/$MODULE_NAME.xml

}

# Main script starts here 

# Set proper profile value from args
unset PROFILE

options=$(getopt -l "profile:" -o "" -a -- "$@")
eval set -- "$options"

while true
do
case $1 in
-profile|--profile) 
    shift
    PROFILE=$1
    ;;
--)
    shift
    break;;
esac
shift
done

[ -z "$PROFILE" ] && usage


# Apply configuration files according to profile
echo "Profile: $PROFILE"

if [ $PROFILE = "default" ]; then
  echo "Default configuraton doesn't include any files to import"

elif [ $PROFILE = "call-home-ssh" ]; then
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

elif [ $PROFILE = "call-home-tls" ]; then
  import_module "ietf-netconf-server";
  import_module "ietf-keystore";
  import_module "ietf-truststore";

else
  echo "No configuration files for profile $PROFILE found"
  exit 2
fi

