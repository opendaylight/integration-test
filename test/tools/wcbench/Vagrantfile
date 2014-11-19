VAGRANTFILE_API_VERSION = "2"

# The WCBench README describes how to use Vagrant for WCBench work
# See: https://github.com/dfarrell07/wcbench#user-content-detailed-walkthrough-vagrant

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
    # Build Vagrant box based on Fedora 20
    config.vm.box = "chef/fedora-20"

    # Configure VM RAM and CPU
    config.vm.provider "virtualbox" do |v|
      v.memory = 2048
      v.cpus = 4
    end

    # This allows sudo commands in wcbench.sh to work
    config.ssh.pty = true

    # Unexpectedly, /usr/local/bin isn't in the default path
    # The cbench and oflops binary install there, need to add it
    config.vm.provision "shell", inline: "echo export PATH=$PATH:/usr/local/bin >> /home/vagrant/.bashrc"
    config.vm.provision "shell", inline: "echo export PATH=$PATH:/usr/local/bin >> /root/.bashrc"

    # Drop code in /home/vagrant/wcbench, not /vagrant
    config.vm.synced_folder ".", "/vagrant", disabled: true
    config.vm.synced_folder ".", "/home/vagrant/wcbench"

    # Install OpenDaylight and CBench with verbose output
    config.vm.provision "shell", inline: 'su -c "/home/vagrant/wcbench/wcbench.sh -vci" vagrant'
end
