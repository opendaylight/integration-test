## Integration Team Tools VM

This Vagrantfile provides VMs with many of the tools used by the OpenDaylight Integration Team pre-installed and configured. It's meant to serve as a known-working, reproducible, clearly defined environment for consuming them.

### Pre-installed Software

Note that the Vagrant environment is configure to support X forwarding, so GUI programs like RIDE will display correctly.

#### OpenDaylight

The latest OpenDaylight release is installed via the [OpenDaylight Puppet module](https://github.com/dfarrell07/puppet-opendaylight). Because we're using the Puppet mod, we get systemd config, user:group management, the correct Java package and any future maintenance/features for free.

#### Netopeer

[Netopeer](https://code.google.com/p/netopeer/) is an Open Source NETCONF server that can be used to explore the MD-SAL/RESTCONF.

#### Robot Famework

The [Robot Framework](http://robotframework.org/) is used by OpenDaylight to create system integration tests.

#### RIDE

[RIDE](https://github.com/robotframework/RIDE) is an editor for working with Robot Framework test cases.

To access the RIDE GUI:

```ShellSession
[vagrant@tools-fedora ~]$ ride
```

### Dependencies

#### Installing Vagrant

If you don't have Vagrant installed, head over to the [Vagrant Downloads](https://www.vagrantup.com/downloads.html) page and grab the latest version for your OS. Fedora/RHEL/CentOS folks need the RPM package, Ubuntu/Debian folks need the DEB package. Note that Vagrant also supports Windows and OSX.

Assuming you're on Fedora/RHEL/CentOS, find the .rpm file you just downloaded and install it:

```ShellSession
sudo rpm -i <name of rpm>
```

Vagrant uses various "providers" for virtualization support. By default, it uses VirtualBox. If you don't have VirtualBox installed, you'll see an error message when you try to `vagrant up` anything. Install VirtualBox (Fedora/RHEL/CentOS):

```ShellSession
$ sudo yum install VirtualBox kmod-VirtualBox -y
```

You may need to restart your system, or at least `systemctl restart systemd-modules-load.service`. If you see Kernel-related errors, try that.

#### Installing Required Gems

We use Bundler to make gem management trivial.

```ShellSession
$ gem install bundler
$ bundle install
```

Among other things, this will provide `librarian-puppet`, which is required for the next section.

#### Installing Required Puppet Modules

Once you've installed `librarian-puppet` through Bundler (as described above), you can use it to install our Puppet module dependences.

```ShellSession
$ librarian-puppet install
$ ls modules
archive  java  opendaylight  stdlib
```

### Configuration

To configure the RAM and CPU resources to be used by the tools boxes, adjust the variables at the top of the Vagrantfile.

```ruby
# Set memory value (MB) and number of CPU cores here
$MEMORY = "2048"
$CPU = "2"
```

To configure the ODL install, adjust the params passed to the [OpenDaylight Puppet module](https://github.com/dfarrell07/puppet-opendaylight) in `manifests/odl_install.pp`.

By default, the newest ODL stable release will be installed via its RPM.

### Common Vagrant commands

Since this Vagrantfile defines a multi-machine environment, it's mandatory to give the name of the box for most Vagrant command. For example, `vagrant up` should be `vagrant up <name of box>`.

#### Gathering information

Use `vagrant status` to see the supported boxes and their current status.

```ShellSession
$ vagrant status
Current machine states:

fedora                    not created (virtualbox)
ubuntu                    not created (virtualbox)
```

#### Starting boxes

To start a tools VM:

```ShellSession
$ vagrant up <name of box>
```

For example, to start the Fedora tools VM:

```ShellSession
$ vagrant up fedora
```

#### Connecting to boxes

To get a shell on a tools VM:

```ShellSession
$ vagrant ssh <name of box>
```

For example, to connect to the Fedora tools VM:

```ShellSession
$ vagrant ssh fedora
[vagrant@tools-fedora ~]$
```

#### Cleaning up boxes

Suspending a tools VM will allow you to re-access it quickly.

```ShellSession
$ vagrant suspend <name of box>
```

To totally remove a VM:

```ShellSession
$ vagrant destroy -f <name of box>
```
