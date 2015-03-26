# External shell script for the vagrant shell provisioner
# This applies for the CentOS VM

# Add EPEL repo for access to Puppet, git-review, etc.
sudo yum install -y epel-release

# Install other packages (must be done after EPEL repo add)
sudo yum install -y \
  puppet \
  git \
  git-review \
  vim \
  nano
