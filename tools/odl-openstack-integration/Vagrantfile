# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.provision "shell", path: "puppet/scripts/bootstrap.sh"

  config.vm.provision "puppet" do |puppet|
      puppet.hiera_config_path = "puppet/hiera.yaml"
      puppet.working_directory = "/vagrant/puppet"
      puppet.manifests_path = "puppet/manifests"
      puppet.manifest_file  = "base.pp"
  end

  config.vm.define "ds-ctl-havana" do |dsctlh|
    dsctlh.vm.box = "saucy64"
    dsctlh.vm.box_url = "http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_ubuntu-13.10_chef-provisionerless.box"
    dsctlh.vm.hostname = "ds-ctl"
    dsctlh.vm.network "private_network", ip: "192.168.50.20"
    dsctlh.vm.provider :virtualbox do |vb|
      vb.memory = 4096
    end
    dsctlh.vm.provision "puppet" do |puppet|
      puppet.hiera_config_path = "puppet/hiera.yaml"
      puppet.working_directory = "/vagrant/puppet"
      puppet.manifests_path = "puppet/manifests"
      puppet.manifest_file  = "devstack-control.pp"
      puppet.facter = {
        "devstack_branch" => "stable/havana"
      }
    end
  end

  config.vm.define "ds-c1-havana" do |dsc1h|
    dsc1h.vm.box = "saucy64"
    dsc1h.vm.box_url = "http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_ubuntu-13.10_chef-provisionerless.box"
    dsc1h.vm.hostname = "ds-c1"
    dsc1h.vm.network "private_network", ip: "192.168.50.21"
    dsc1h.vm.provider :virtualbox do |vb|
      vb.memory = 4096
    end
    dsc1h.vm.provision "puppet" do |puppet|
      puppet.hiera_config_path = "puppet/hiera.yaml"
      puppet.working_directory = "/vagrant/puppet"
      puppet.manifests_path = "puppet/manifests"
      puppet.manifest_file  = "ds-compute.pp"
      puppet.facter = {
        "devstack_branch" => "stable/havana"
      }
    end
  end

  config.vm.define "ds-c2-havana" do |dsc2h|
    dsc2h.vm.box = "saucy64"
    dsc2h.vm.box_url = "http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_ubuntu-13.10_chef-provisionerless.box"
    dsc2h.vm.hostname = "ds-c2"
    dsc2h.vm.network "private_network", ip: "192.168.50.22"
    dsc2h.vm.provider :virtualbox do |vb|
      vb.memory = 4096
    end
    dsc2h.vm.provision "puppet" do |puppet|
      puppet.hiera_config_path = "puppet/hiera.yaml"
      puppet.working_directory = "/vagrant/puppet"
      puppet.manifests_path = "puppet/manifests"
      puppet.manifest_file  = "ds-compute.pp"
      puppet.facter = {
        "devstack_branch" => "stable/havana"
      }
    end
  end

  config.vm.define "ds-ctl-icehouse" do |dsctli|
    dsctli.vm.box = "saucy64"
    dsctli.vm.box_url = "http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_ubuntu-13.10_chef-provisionerless.box"
    dsctli.vm.hostname = "ds-ctl"
    dsctli.vm.network "private_network", ip: "192.168.50.20"
    dsctli.vm.provider :virtualbox do |vb|
      vb.memory = 4096
    end
    dsctli.vm.provision "puppet" do |puppet|
      puppet.hiera_config_path = "puppet/hiera.yaml"
      puppet.working_directory = "/vagrant/puppet"
      puppet.manifests_path = "puppet/manifests"
      puppet.manifest_file  = "devstack-control.pp"
      puppet.facter = {
        "devstack_branch" => "stable/icehouse"
      }
    end
  end

  config.vm.define "ds-c1-icehouse" do |dsc1i|
    dsc1i.vm.box = "saucy64"
    dsc1i.vm.box_url = "http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_ubuntu-13.10_chef-provisionerless.box"
    dsc1i.vm.hostname = "ds-c1"
    dsc1i.vm.network "private_network", ip: "192.168.50.21"
    dsc1i.vm.provider :virtualbox do |vb|
      vb.memory = 4096
    end
    dsc1i.vm.provision "puppet" do |puppet|
      puppet.hiera_config_path = "puppet/hiera.yaml"
      puppet.working_directory = "/vagrant/puppet"
      puppet.manifests_path = "puppet/manifests"
      puppet.manifest_file  = "devstack-compute.pp"
      puppet.facter = {
        "devstack_branch" => "stable/icehouse"
      }
    end
  end

  config.vm.define "ds-c2-icehouse" do |dsc2i|
    dsc2i.vm.box = "saucy64"
    dsc2i.vm.box_url = "http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_ubuntu-13.10_chef-provisionerless.box"
    dsc2i.vm.hostname = "ds-c2"
    dsc2i.vm.network "private_network", ip: "192.168.50.22"
    dsc2i.vm.provider :virtualbox do |vb|
      vb.memory = 4096
    end
    dsc2i.vm.provision "puppet" do |puppet|
      puppet.hiera_config_path = "puppet/hiera.yaml"
      puppet.working_directory = "/vagrant/puppet"
      puppet.manifests_path = "puppet/manifests"
      puppet.manifest_file  = "devstack-compute.pp"
      puppet.facter = {
        "devstack_branch" => "stable/icehouse"
      }
    end
  end

  config.vm.define "ds-ctl-juno" do |dsctlj|
    dsctlj.vm.box = "saucy64"
    dsctlj.vm.box_url = "http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_ubuntu-13.10_chef-provisionerless.box"
    dsctlj.vm.hostname = "ds-ctl"
    dsctlj.vm.network "private_network", ip: "192.168.50.20"
    dsctlj.vm.provider :virtualbox do |vb|
      vb.memory = 4096
    end
    dsctlj.vm.provision "puppet" do |puppet|
      puppet.hiera_config_path = "puppet/hiera.yaml"
      puppet.working_directory = "/vagrant/puppet"
      puppet.manifests_path = "puppet/manifests"
      puppet.manifest_file  = "devstack-control.pp"
      puppet.facter = {
        "devstack_branch" => "master"
      }
    end
  end

  config.vm.define "ds-c1-juno" do |dsc1j|
    dsc1j.vm.box = "saucy64"
    dsc1j.vm.box_url = "http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_ubuntu-13.10_chef-provisionerless.box"
    dsc1j.vm.hostname = "ds-c1"
    dsc1j.vm.network "private_network", ip: "192.168.50.21"
    dsc1j.vm.provider :virtualbox do |vb|
      vb.memory = 4096
    end
    dsc1j.vm.provision "puppet" do |puppet|
      puppet.hiera_config_path = "puppet/hiera.yaml"
      puppet.working_directory = "/vagrant/puppet"
      puppet.manifests_path = "puppet/manifests"
      puppet.manifest_file  = "devstack-compute.pp"
      puppet.facter = {
        "devstack_branch" => "master"
      }
    end
  end

  config.vm.define "ds-c2-juno" do |dsc2j|
    dsc2j.vm.box = "saucy64"
    dsc2j.vm.box_url = "http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_ubuntu-13.10_chef-provisionerless.box"
    dsc2j.vm.hostname = "ds-c2"
    dsc2j.vm.network "private_network", ip: "192.168.50.22"
    dsc2j.vm.provider :virtualbox do |vb|
      vb.memory = 4096
    end
    dsc2j.vm.provision "puppet" do |puppet|
      puppet.hiera_config_path = "puppet/hiera.yaml"
      puppet.working_directory = "/vagrant/puppet"
      puppet.manifests_path = "puppet/manifests"
      puppet.manifest_file  = "devstack-compute.pp"
      puppet.facter = {
        "devstack_branch" => "master"
      }
    end
  end

end
