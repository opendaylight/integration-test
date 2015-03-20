# VM Tool

This Vagrantfile is used as a tool to provide a virtualbox test VM for developing/running integration/system test on an OpenDaylight controller. It's built for a "multi-machine" environnement, so you can choose the VM's operating system.

##### Configuration

You only need to edit the memory and CPU variables at the top of the Vagrantfile to suit your needs. By default, it is configured to use 2048 MB (2 GB) of memory and 2 CPUs.

##### Running a VM

You can choose between the following operating systems for the VM:
  - CentOS 7
  - Ubuntu 14.04 (Work in progress)

###### CentOS 7
To start the VM, do:
```sh
$ vagrant up centos
```
To log into the VM, do:
```sh
$ vagrant ssh centos
```
To suspend|resume the VM, do:
```sh
$ vagrant suspend centos
$ vagrant resume centos
```
To shutdown the VM, do:
```sh
$ vagrant halt centos
```
To remove the VM, do:
```sh
$ vagrant destroy centos
```
###### Ubuntu 14.04
Use the same commands as above, but replace "centos" with "ubuntu"
Example:
```sh
$ vagrant up ubuntu
```
This multi-machine environnement means that it is mandatory to add the name of the VM for each vagrant command. For example, if you only use "vagrant up", it won't work.

Always shutdown your VMs using "vagrant halt «name»". Don't shutdown within the VM, or it can break the state of the VM between Vagrant and Virtualbox. (Exit the VM before shutting it down)
