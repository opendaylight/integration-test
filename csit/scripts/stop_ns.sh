#!/bin/sh

# Check that this is run as root
#if [ "$USER" != "root" ]
#then
#        echo "Script must be executed as root"
#        exit 1
#fi
#
# Kill network namespaces (and contained resources)
echo "Killing network namespaces (and resources) ..."
for NS in `ip netns list`; do
  echo "Deleting $NS ..."
  sudo ip netns delete $NS
done

# Remove any eth  links
echo "Deleting any eth links ..."
for link in `ifconfig -a | grep -F eth3. | awk {'print $1'}`; do
    echo "Deleting $link ..."
    sudo ip link delete $link > /dev/null
done


