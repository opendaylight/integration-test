#!/usr/bin/env bash

# --------------------------------------------
# External shell provisioner script for Fedora
# --------------------------------------------

# Add EPEL repo for access to Puppet, git-review, etc.
sudo yum install -y epel-release

# Install other packages (must be done after EPEL repo add)
sudo yum install -y \
  puppet \
  git
